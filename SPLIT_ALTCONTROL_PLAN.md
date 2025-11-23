# Plan de découpage AltControl.lua

## 📋 Analyse préliminaire

### 1. Serveur Python - Communication actuelle

**Fonction clé : `send_command_to_alt(alt_name, command)`**
- Envoie des commandes via TCP au port de l'alt
- Format : Texte brut (commandes Windower)
- Exemples actuels :
  - `//lua r AltControl` (reload)
  - `//ac follow Dexterbrown`
  - `//ac cast "Song Name" <me>`

**Pas de bouton ON/OFF serveur actuellement** → À créer

---

### 2. AltControl.lua - Structure actuelle

#### Parties à GARDER dans le Core (léger)
```lua
-- Déclaration addon
_addon.name, _addon.commands

-- Socket
require('socket')

-- Variables de connexion
host, base_port

-- Fonctions essentielles
- write_connection_file()  -- Crée fichier port
- get_auto_port()          -- Calcule port unique
- listen_for_commands()    -- Écoute TCP

-- Events minimaux
- windower.register_event('load')
- windower.register_event('login')
- windower.register_event('unload')
```

#### Parties à DÉPLACER dans Extended (lourd)
```lua
-- Modules tools
- load_tool()
- autocast, autoengage, distancefollow

-- Toutes les fonctions get_*
- get_weapon_id()
- get_party_info()
- get_pet_info()
- get_active_buffs()
- get_party_buffs()
- get_bst_ready_charges()
- get_recasts()

-- Fonctions d'envoi
- send_alt_info()
- send_alt_info_safe()
- broadcast_pet_to_overlay()

-- JSON
- escape_str()
- is_array()
- table_to_json()

-- Toutes les commandes addon
- //ac start, stop, status
- //ac autoengage
- //ac dfollow
- //ac follow, stopfollow
- //ac cast, queue_song
- //ac enable_auto_songs, etc.
- Toutes les commandes BRD
- Commandes debug pet

-- Events lourds
- windower.register_event('pet_change')
- windower.register_event('pet_status_change')
- windower.register_event('job_change')
- windower.register_event('equip change')
- windower.register_event('prerender')
- windower.register_event('action')
- windower.register_event('outgoing chunk')

-- Boucles
- coroutine.schedule (boucle principale)
```

---

### 3. Impact sur les liens existants

#### ✅ AUCUN IMPACT sur :
- **Webapp** → Envoie toujours des commandes via `send_command_to_alt()`
- **Serveur Python** → Continue d'écouter sur port 5007
- **Fichiers de config** → Toujours créés par le Core

#### ⚠️ MODIFICATIONS NÉCESSAIRES :

**A. Serveur Python (FFXI_ALT_Control.py)**
```python
# À AJOUTER : Bouton ON/OFF et fonction de chargement

def start_extended_features():
    """Charge Extended sur tous les alts connectés"""
    for alt_name in alts.keys():
        send_command_to_alt(alt_name, '//ac load_extended')
        time.sleep(0.1)  # Petit délai entre chaque alt

def stop_extended_features():
    """Décharge Extended sur tous les alts"""
    for alt_name in alts.keys():
        send_command_to_alt(alt_name, '//ac unload_extended')
        time.sleep(0.1)

# Route Flask à ajouter
@app.route('/toggle-extended', methods=['POST'])
def toggle_extended():
    data = request.json
    enable = data.get('enable', False)
    
    if enable:
        start_extended_features()
    else:
        stop_extended_features()
    
    return jsonify({"success": True})
```

**B. Webapp (à créer)**
```typescript
// Nouveau bouton dans Home.tsx ou AltAdminPanel.tsx
const [extendedActive, setExtendedActive] = useState(false);

const toggleExtended = async () => {
    const newState = !extendedActive;
    await backendService.toggleExtended(newState);
    setExtendedActive(newState);
};

// Bouton UI
<button onClick={toggleExtended}>
    {extendedActive ? "Extended: ON" : "Extended: OFF"}
</button>
```

**C. Fonction Reload (à modifier)**
```python
# Dans FFXI_ALT_Control.py
@app.route('/reload-lua', methods=['POST'])
def reload_lua():
    # 1. Reload Core
    for alt_name, alt in alts.items():
        send_command_to_alt(alt_name, '//lua r AltControl')
    
    time.sleep(1)  # Attendre 1 seconde
    
    # 2. Si Extended était actif, le recharger
    if extended_features_active:  # Variable globale à ajouter
        for alt_name in alts.keys():
            send_command_to_alt(alt_name, '//ac load_extended')
    
    return jsonify({"success": True})
```

---

### 4. Architecture finale

```
AltControl/
├── AltControl.lua (Core - 200 lignes)
│   ├── Déclaration addon
│   ├── Socket TCP
│   ├── write_connection_file()
│   ├── get_auto_port()
│   ├── listen_for_commands()
│   ├── load_extended() / unload_extended()
│   └── Events minimaux (load, login, unload)
│
└── AltControlExtended.lua (Module - 900 lignes)
    ├── Toutes les fonctions get_*
    ├── send_alt_info()
    ├── JSON encoding
    ├── Tous les modules tools
    ├── Toutes les commandes
    ├── Tous les events
    └── Boucles de mise à jour
```

---

### 5. Mécanisme de chargement/déchargement

#### Dans AltControl.lua (Core)
```lua
local extended_module = nil
local extended_loaded = false

-- Commande pour charger Extended
windower.register_event('addon command', function(command, ...)
    if command == 'load_extended' then
        if not extended_loaded then
            local success, module = pcall(require, 'AltControlExtended')
            if success then
                extended_module = module
                extended_module.initialize()
                extended_loaded = true
                print('[AltControl] ✅ Extended features loaded')
            end
        end
        
    elseif command == 'unload_extended' then
        if extended_loaded and extended_module then
            extended_module.shutdown()
            extended_module = nil
            extended_loaded = false
            package.loaded['AltControlExtended'] = nil
            collectgarbage()
            print('[AltControl] ✅ Extended features unloaded')
        end
    end
end)
```

#### Dans AltControlExtended.lua (Module)
```lua
local Extended = {}

function Extended.initialize()
    -- Démarrer tout
    -- - Charger les modules tools
    -- - Démarrer les boucles
    -- - Enregistrer les events
    print('[Extended] Initializing...')
end

function Extended.shutdown()
    -- Arrêter tout proprement
    -- - Arrêter les boucles
    -- - Décharger les modules
    -- - Unregister les events
    print('[Extended] Shutting down...')
end

return Extended
```

---

### 6. Workflow utilisateur

1. **Démarrage FFXI**
   - AltControl.lua (Core) se charge automatiquement
   - Crée les fichiers de config
   - Écoute les commandes TCP
   - **N'envoie rien** (pas de ralentissement)

2. **Lancement webapp + serveur Python**
   - Clic sur bouton "Extended: OFF" → "Extended: ON"
   - Serveur envoie `//ac load_extended` à tous les alts
   - Extended se charge et démarre l'envoi de données

3. **Utilisation normale**
   - Toutes les fonctionnalités disponibles
   - Webapp fonctionne normalement

4. **Arrêt du système**
   - Clic sur "Extended: ON" → "Extended: OFF"
   - Serveur envoie `//ac unload_extended`
   - Extended se décharge, jeu redevient fluide

5. **Reload**
   - Clic sur bouton "Reload"
   - Reload Core (1 sec de pause)
   - Si Extended était actif, le recharger

---

### 7. Travail à effectuer

#### Fichiers à créer/modifier

**Lua :**
- ✅ Créer `AltControlExtended.lua` (nouveau fichier)
- ✅ Modifier `AltControl.lua` (découpage)

**Python :**
- ✅ Ajouter variable globale `extended_features_active`
- ✅ Ajouter fonctions `start_extended_features()` / `stop_extended_features()`
- ✅ Ajouter route `/toggle-extended`
- ✅ Modifier route `/reload-lua`

**Webapp :**
- ✅ Ajouter bouton Extended ON/OFF (Home.tsx ou AltAdminPanel.tsx)
- ✅ Ajouter fonction `toggleExtended()` dans backendService.ts
- ✅ Gérer l'état `extendedActive`

---

### 8. Estimation du travail

**Temps estimé : 2-3 heures**

1. Découpage AltControl.lua → AltControlExtended.lua (1h)
2. Modifications serveur Python (30min)
3. Modifications webapp (30min)
4. Tests et debug (1h)

**Complexité : Moyenne**
- Découpage Lua : Attention aux dépendances
- Chargement/déchargement dynamique : Bien gérer la mémoire
- Tests : Vérifier que tout fonctionne comme avant

---

### 9. Risques et précautions

**Risques :**
- ❌ Oublier une dépendance lors du découpage
- ❌ Fuite mémoire si déchargement mal fait
- ❌ Events non unregister

**Précautions :**
- ✅ Backup complet avant de commencer
- ✅ Tester le chargement/déchargement plusieurs fois
- ✅ Vérifier la mémoire avec `collectgarbage("count")`
- ✅ Documenter toutes les dépendances

---

### 10. Conclusion

**Faisabilité : ✅ OUI, totalement possible**

**Avantages :**
- Performance : Jeu fluide quand Extended n'est pas chargé
- Contrôle : Activation/désactivation à la demande
- Maintenance : Plus facile de recharger seulement Extended

**Inconvénients :**
- Complexité : Architecture plus complexe
- Tests : Plus de cas à tester
- Debug : Plus difficile si problème de chargement

**Recommandation : GO ! 🚀**

L'architecture est solide et les bénéfices valent l'effort.
