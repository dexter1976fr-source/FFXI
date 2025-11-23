# SESSION FINALE - COMMANDES ALLON / ALLOFF

## 🎯 Solution finale adoptée

**Contrôle manuel avec 2 commandes simples**

Au lieu d'un système automatique complexe avec le serveur Python, tu contrôles tout avec :
- `//ac allon` = Charge Extended sur tous les alts
- `//ac alloff` = Décharge Extended sur tous les alts

## ✅ Modifications appliquées

### Core (AltControl_NEW.lua → AltControl.lua)

**Ajouté : Commandes allon/alloff**
```lua
if command == 'allon' then
    -- Charger Extended sur TOUS les alts
    windower.send_command('input /console send @all input //ac load_extended')
    
elseif command == 'alloff' then
    -- Décharger Extended sur TOUS les alts
    windower.send_command('input /console send @all input //ac unload_extended')
```

**Conservé : listen_for_commands() dans le Core**
```lua
function listen_for_commands()
    -- Socket TCP léger pour recevoir les commandes
    -- Boucle toutes les 0.5 secondes
    -- Permet au serveur Python d'envoyer des commandes
end
```

**Modifié : Message d'initialisation**
```lua
print('[AltControl] 💡 Quick commands:')
print('[AltControl]   //ac allon  = Load Extended on ALL alts')
print('[AltControl]   //ac alloff = Unload Extended on ALL alts')
```

### Extended (AltControlExtended.lua)

**Retiré : listen_for_commands()**
- Plus besoin de socket TCP dans Extended
- Le Core gère déjà les commandes

**Retiré : stop_listening()**
- Plus besoin d'arrêter un socket qui n'existe pas

**Simplifié : initialize() et shutdown()**
- Pas de gestion de socket
- Juste les fonctionnalités (AutoCast, AutoEngage, etc.)

## 🎯 Workflow final

### Démarrage
```
1. Lancer FFXI avec tous tes alts
   → Core se charge automatiquement (léger)

2. Démarrer le serveur Python
   → Serveur écoute les données des alts

3. Dans FFXI : //ac allon
   → Extended se charge sur tous les alts
   → Sockets TCP actifs
   → Webapp fonctionnelle

4. Utiliser la webapp normalement
   → Envoyer des commandes
   → AutoCast, AutoEngage, etc.
```

### Arrêt
```
1. Dans FFXI : //ac alloff
   → Extended se décharge sur tous les alts
   → Sockets TCP fermés
   → Jeu redevient ultra fluide

2. Arrêter le serveur Python (optionnel)
   → Peut rester actif si tu veux

3. Continuer à jouer
   → Core reste chargé (léger)
   → 0 ralentissement
```

## 📊 Architecture finale

```
FFXI + Windower
│
├─ AltControl CORE (toujours actif)
│  ├─ write_connection_file()
│  ├─ get_auto_port()
│  ├─ listen_for_commands() ← Socket TCP léger
│  └─ Commandes: allon, alloff, load, unload, status
│
├─ AltControl EXTENDED (chargé avec //ac allon)
│  ├─ send_alt_info()
│  ├─ AutoCast
│  ├─ AutoEngage
│  ├─ DistanceFollow
│  └─ Toutes les fonctionnalités
│
Python Server (FFXI_ALT_Control.py)
│  ├─ Reçoit les données des alts (port 5007)
│  ├─ Envoie les commandes de la webapp (ports individuels)
│  └─ N'a plus besoin de gérer load/unload automatiquement
│
React WebApp
   └─ Interface de contrôle
```

## 🎉 Avantages de cette solution

### 1. Simplicité
- ✅ 2 commandes faciles à retenir
- ✅ Pas de timing automatique compliqué
- ✅ Pas d'erreurs de connexion au démarrage

### 2. Contrôle total
- ✅ Tu décides quand charger/décharger Extended
- ✅ Prévisible et fiable
- ✅ Facile à débugger

### 3. Performance
- ✅ Core léger (socket TCP minimal)
- ✅ Extended chargé uniquement quand nécessaire
- ✅ Jeu fluide quand Extended est off

### 4. Flexibilité
- ✅ Peut jouer sans serveur Python (Core seul)
- ✅ Peut utiliser webapp (Core + Extended)
- ✅ Peut charger/décharger à volonté

## 🧪 Tests à effectuer

### Test 1 : Core seul
```lua
//lua r altcontrol
```

**Résultat attendu :**
```
[AltControl] ✅ Core initialized for [Nom]
[AltControl] Port: 5XXX
[AltControl] 💡 Quick commands:
[AltControl]   //ac allon  = Load Extended on ALL alts
[AltControl]   //ac alloff = Unload Extended on ALL alts
```

### Test 2 : Charger Extended
```lua
//ac allon
```

**Résultat attendu (sur chaque alt) :**
```
[AltControl] 🚀 Loading Extended on all alts...
[AltControl] Loading Extended features...
[Extended] 🚀 Initializing features...
[Extended] ✅ All features initialized
[AltControl] ✅ Extended features loaded
```

### Test 3 : Vérifier le status
```lua
//ac status
```

**Résultat attendu :**
```
[AltControl] Core: ACTIVE
[AltControl] Extended: LOADED
```

### Test 4 : Tester la webapp
- Ouvrir la webapp
- Sélectionner un alt
- Envoyer une commande (ex: spell, ability)
- Vérifier que ça fonctionne dans FFXI

### Test 5 : Décharger Extended
```lua
//ac alloff
```

**Résultat attendu (sur chaque alt) :**
```
[AltControl] 🛑 Unloading Extended on all alts...
[AltControl] Unloading Extended features...
[Extended] 🛑 Shutting down features...
[Extended] ✅ All features stopped
[AltControl] ✅ Extended features unloaded
```

### Test 6 : Vérifier la fluidité
- Jouer normalement pendant 2-3 minutes
- Vérifier qu'il n'y a pas de ralentissement
- Core reste actif mais ultra léger

## 📝 Commandes disponibles

### Commandes globales (tous les alts)
```lua
//ac allon   -- Charge Extended sur tous les alts
//ac alloff  -- Décharge Extended sur tous les alts
```

### Commandes individuelles (un seul alt)
```lua
//ac load_extended    -- Charge Extended sur cet alt
//ac unload_extended  -- Décharge Extended sur cet alt
//ac status           -- Affiche l'état de cet alt
```

## 🚀 Optimisations possibles

### Macro Windower
Créer des alias dans `init.txt` :
```
alias allon ac allon
alias alloff ac alloff
```

Ensuite :
```
//allon
//alloff
```

### Bind clavier
Dans Windower, tu peux bind une touche :
```
bind f9 ac allon
bind f10 ac alloff
```

## ✅ Fichiers modifiés

- `AltControl_NEW.lua` → `AltControl.lua`
  - Ajouté commandes allon/alloff
  - Conservé listen_for_commands()
  - Modifié messages d'initialisation

- `AltControlExtended.lua`
  - Retiré listen_for_commands()
  - Retiré stop_listening()
  - Simplifié initialize() et shutdown()

- Copiés vers `A:\Jeux\PlayOnline\Windower4\addons\AltControl\`

## 📚 Documentation créée

- `GUIDE_ALLON_ALLOFF.md` - Guide complet des commandes
- `SESSION_ALLON_ALLOFF_FINAL.md` - Ce fichier (récap complet)

## 🎯 Prochaines étapes

1. **Tester dans FFXI**
   - `//lua r altcontrol` sur tous les alts
   - `//ac allon` pour charger Extended
   - Tester la webapp
   - `//ac alloff` pour décharger

2. **Vérifier la performance**
   - Jouer avec Extended off
   - Vérifier qu'il n'y a pas de ralentissement
   - Comparer avec Extended on

3. **Ajuster si nécessaire**
   - Si Core ralentit encore, augmenter le délai dans listen_for_commands()
   - Si besoin, créer des macros/binds pour plus de rapidité

---

**C'est prêt ! Teste avec `//ac allon` et dis-moi si ça marche ! 🎮**
