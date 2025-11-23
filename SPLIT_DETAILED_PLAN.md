# Plan détaillé du découpage AltControl

## AltControl.lua (Core - LÉGER)

### À GARDER (lignes approximatives)

**Déclaration addon (lignes 1-14)**
```lua
_addon.name = 'AltControl'
_addon.author = 'FFXI ALT Control Team'
_addon.version = '1.1.0'
_addon.commands = {'altcontrol', 'ac'}

local socket = require('socket')
local host = "127.0.0.1"
local base_port = 5007
```

**Variables Extended (NOUVEAU)**
```lua
local extended_module = nil
local extended_loaded = false
```

**Fonctions essentielles**
- `get_auto_port()` (lignes ~700-710)
- `write_connection_file()` (lignes ~840-850)
- `listen_for_commands()` (lignes ~860-880)

**Commandes load/unload Extended (NOUVEAU)**
```lua
windower.register_event('addon command', function(command, ...)
    if command == 'load_extended' then
        -- Charger Extended
    elseif command == 'unload_extended' then
        -- Décharger Extended
    end
end)
```

**Events minimaux**
- `windower.register_event('load')` (lignes ~920-940)
- `windower.register_event('login')` (lignes ~945-960)
- `windower.register_event('unload')` (ligne ~965)

**Fonction initialize_after_login** (lignes ~900-920)

---

## AltControlExtended.lua (Module - LOURD)

### Structure du module

```lua
local Extended = {}

-- TOUT le reste du code actuel va ici

function Extended.initialize()
    print('[Extended] Initializing features...')
    
    -- Démarrer la boucle principale
    coroutine.schedule(function()
        -- Boucle existante
    end, 0)
    
    -- Charger l'overlay si Dexterbrown
    local player = windower.ffxi.get_player()
    if player and player.name == 'Dexterbrown' then
        load_tool('AltPetOverlay')
    end
end

function Extended.shutdown()
    print('[Extended] Shutting down features...')
    
    -- Arrêter tout mouvement
    windower.ffxi.run(false)
    
    -- Décharger les modules
    if autocast then
        autocast.stop()
    end
    
    -- Unregister tous les events
    -- (Windower le fait automatiquement quand on unload)
end

return Extended
```

### À INCLURE dans Extended

**Tout sauf :**
- Déclaration addon
- get_auto_port()
- write_connection_file()
- listen_for_commands()
- initialize_after_login()
- Events load/login/unload

**Donc inclure :**
- Tous les modules tools
- Toutes les fonctions get_*
- send_alt_info()
- JSON encoding
- Toutes les commandes addon
- Tous les events (pet, job, equip, prerender, action, outgoing chunk)
- Boucle principale

---

## Modifications à faire

### 1. AltControl.lua (Core)

**Supprimer :**
- Lignes 17-23 (modules tools)
- Lignes 26-78 (load_tool, load_autocast, start_autocast, stop_autocast)
- Lignes 82-435 (toutes les commandes sauf load/unload_extended)
- Lignes 440-840 (JSON, get_*, send_alt_info, etc.)
- Lignes 970-1110 (events lourds, boucles)

**Garder :**
- Lignes 1-14 (déclaration)
- Lignes 700-710 (get_auto_port)
- Lignes 840-850 (write_connection_file)
- Lignes 860-880 (listen_for_commands)
- Lignes 900-920 (initialize_after_login)
- Lignes 920-965 (events load/login/unload)

**Ajouter :**
- Variables extended_module, extended_loaded
- Commandes load_extended / unload_extended

### 2. AltControlExtended.lua (Module)

**Transformer en module :**
```lua
local Extended = {}

-- Déplacer toutes les variables globales ici
local autocast = nil
local autoengage = nil
local distancefollow = nil
-- etc.

-- Toutes les fonctions existantes

function Extended.initialize()
    -- Code de démarrage
end

function Extended.shutdown()
    -- Code d'arrêt
end

return Extended
```

---

## Ordre d'exécution

1. ✅ Copier AltControl.lua → AltControlExtended.lua (FAIT)
2. ⏳ Modifier AltControlExtended.lua (transformer en module)
3. ⏳ Modifier AltControl.lua (garder seulement le core)
4. ⏳ Tester le chargement/déchargement
5. ⏳ Modifier le serveur Python (commandes load/unload)

---

## Tests à faire

1. **Core seul** : `//lua l altcontrol` → Doit charger sans erreur
2. **Load Extended** : `//ac load_extended` → Doit charger toutes les features
3. **Fonctionnalités** : Tester AutoEngage, DistanceFollow, etc.
4. **Unload Extended** : `//ac unload_extended` → Doit libérer la mémoire
5. **Reload** : `//lua r altcontrol` puis `//ac load_extended` → Doit fonctionner
