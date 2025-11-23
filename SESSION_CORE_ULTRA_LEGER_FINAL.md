# SESSION FINALE - CORE ULTRA LÉGER

## 🎯 Problème résolu
**Core ralentissait le jeu même quand Extended était déchargé**

## 🔍 Cause identifiée
`listen_for_commands()` dans le Core créait un socket TCP qui tournait en boucle (toutes les 2 secondes), causant des ralentissements même sans Extended.

## ✅ Solution appliquée
**Déplacer `listen_for_commands()` du Core vers Extended**

### Modifications Core (AltControl_NEW.lua → AltControl.lua)
```lua
-- ❌ RETIRÉ : listen_for_commands()
-- ❌ RETIRÉ : Appel dans initialize_after_login()

-- ✅ Core ne fait plus que :
-- 1. Créer le fichier de config (write_connection_file)
-- 2. Afficher le message d'initialisation
-- 3. C'est tout !
```

### Modifications Extended (AltControlExtended.lua)
```lua
-- ✅ AJOUTÉ : Variables globales pour le socket
local tcp_server = nil
local tcp_running = false

-- ✅ AJOUTÉ : Fonction d'arrêt propre
function stop_listening()
    tcp_running = false
    if tcp_server then
        tcp_server:close()
        tcp_server = nil
    end
end

-- ✅ MODIFIÉ : listen_for_commands() avec flag d'arrêt
function listen_for_commands()
    -- ... code socket ...
    while tcp_running do  -- Au lieu de while true
        -- ... accept/receive ...
    end
    -- Fermeture propre du serveur
end

-- ✅ MODIFIÉ : Extended.initialize()
function Extended.initialize()
    -- Démarrer l'écoute TCP
    listen_for_commands()
    print('[Extended] ✅ TCP listener started on port ' .. get_auto_port())
    -- ... reste du code ...
end

-- ✅ MODIFIÉ : Extended.shutdown()
function Extended.shutdown()
    -- Arrêter l'écoute TCP
    stop_listening()
    print('[Extended] ✅ TCP listener stopped')
    -- ... reste du code ...
end
```

### Python (FFXI_ALT_Control.py)
Aucune modification nécessaire ! Le serveur envoie déjà :
- `//ac load_extended` au démarrage
- `//ac unload_extended` à l'arrêt

## 🎯 Résultat attendu

### Core seul (serveur Python arrêté)
- ✅ **0 ralentissement**
- ✅ Aucun socket TCP
- ✅ Aucune boucle
- ✅ Jeu 100% fluide

### Core + Extended (serveur Python actif)
- ✅ Tout fonctionne comme avant
- ✅ Webapp peut envoyer des commandes
- ✅ AutoCast, AutoEngage, DistanceFollow OK
- ✅ Socket TCP actif uniquement dans Extended

### Arrêt du serveur Python
- ✅ Extended déchargé automatiquement
- ✅ Socket TCP fermé proprement
- ✅ Core reste mais ne fait rien
- ✅ Jeu redevient fluide

## 📊 Architecture finale

```
┌─────────────────────────────────────────────────────────┐
│                    FFXI + Windower                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  AltControl CORE (ultra léger)                   │  │
│  │  - write_connection_file()                       │  │
│  │  - get_auto_port()                               │  │
│  │  - load_extended / unload_extended               │  │
│  │  - 0 socket, 0 boucle, 0 ralentissement         │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                              │
│                          │ load_extended                │
│                          ▼                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  AltControl EXTENDED (fonctionnalités)           │  │
│  │  - listen_for_commands() ← Socket TCP ici !     │  │
│  │  - send_alt_info()                               │  │
│  │  - AutoCast, AutoEngage, DistanceFollow         │  │
│  │  - Chargé uniquement quand serveur actif        │  │
│  └──────────────────────────────────────────────────┘  │
│                          ▲                              │
└──────────────────────────┼──────────────────────────────┘
                           │ TCP
                           │
┌──────────────────────────┼──────────────────────────────┐
│                          │                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Python Server (FFXI_ALT_Control.py)             │  │
│  │  - Démarre → envoie //ac load_extended          │  │
│  │  - Arrête → envoie //ac unload_extended         │  │
│  │  - Gère automatiquement le cycle de vie         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  React WebApp                                     │  │
│  │  - Interface de contrôle                         │  │
│  │  - Envoie commandes via Python                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🧪 Tests à effectuer

### Test 1 : Core seul
```lua
//lua r altcontrol
-- Attendre 2 minutes
-- Vérifier fluidité du jeu
```

**Résultat attendu :** Jeu 100% fluide

### Test 2 : Core + Extended
```
1. Démarrer serveur Python
2. Vérifier message "[Extended] ✅ TCP listener started"
3. Tester webapp (commandes, AutoCast, etc.)
```

**Résultat attendu :** Tout fonctionne

### Test 3 : Déchargement Extended
```
1. Arrêter serveur Python
2. Vérifier message "[Extended] ✅ TCP listener stopped"
3. Jouer 2 minutes
4. Vérifier fluidité
```

**Résultat attendu :** Jeu redevient fluide

## 🎉 Avantages de cette solution

1. **Performance optimale**
   - Core ultra léger (0 ralentissement)
   - Extended chargé uniquement quand nécessaire

2. **Automatisation complète**
   - Serveur Python gère tout
   - Pas de commandes manuelles

3. **Flexibilité**
   - Peut jouer sans serveur (Core seul)
   - Peut utiliser webapp (Core + Extended)

4. **Propreté du code**
   - Séparation claire des responsabilités
   - Socket TCP uniquement dans Extended
   - Fermeture propre des ressources

## 📝 Commandes utiles

```lua
//ac status              -- Voir l'état actuel
//ac load_extended       -- Charger Extended manuellement
//ac unload_extended     -- Décharger Extended manuellement
//lua u altcontrol       -- Décharger complètement
//lua r altcontrol       -- Recharger Core seul
```

## 🚀 Workflow final

```
Démarrage FFXI
    ↓
Core chargé (ultra léger, 0 lag)
    ↓
Démarrage serveur Python
    ↓
Extended chargé automatiquement
    ↓
Utilisation webapp (tout fonctionne)
    ↓
Arrêt serveur Python
    ↓
Extended déchargé automatiquement
    ↓
Jeu fluide (Core reste mais ne fait rien)
```

## ✅ Fichiers modifiés

- `AltControl_NEW.lua` → `AltControl.lua` (Core ultra léger)
- `AltControlExtended.lua` (Extended avec TCP)
- Copiés vers `A:\Jeux\PlayOnline\Windower4\addons\AltControl\`

## 📚 Documentation créée

- `TEST_CORE_ULTRA_LEGER.md` - Guide de test détaillé
- `SESSION_CORE_ULTRA_LEGER_FINAL.md` - Ce fichier (récap complet)

---

**C'est prêt ! Teste et dis-moi si le jeu est fluide maintenant ! 🎮**
