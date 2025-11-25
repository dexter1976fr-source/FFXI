# 🏗️ REFACTORING - Architecture modulaire (inspirée GearSwap)

## 📊 Analyse de l'existant

### ❌ Problèmes actuels

1. **Performance**
   - Lua envoie TOUTES les données toutes les 0.5s
   - Même quand serveur Python est OFF → LAG énorme
   - Pas de delta updates, tout est renvoyé à chaque fois

2. **Structure**
   - Tout dans un seul fichier `AltControl.lua` (500+ lignes)
   - Logique BRD/SCH mélangée avec commandes de base
   - Impossible de désactiver un module sans tout casser

3. **Maintenabilité**
   - Code difficile à lire et modifier
   - Pas de séparation des responsabilités
   - Ajout d'un nouveau job = modifier plusieurs fichiers

---

## 🎯 Architecture cible (inspirée GearSwap)

### Structure des fichiers

```
AltControl/                      # UN SEUL addon, tout dans ce dossier
├── AltControl.lua               # Point d'entrée (nom officiel addon)
├── libs/                        # Bibliothèques core
│   ├── communication.lua        # Gestion serveur Python + IP/Port
│   ├── events.lua               # Système d'événements
│   ├── commands.lua             # Commandes de base (assist, attack, etc.)
│   └── distance_follow.lua      # DistanceFollow intégré (pas addon séparé)
├── jobs/                        # Modules par job (même structure pour tous)
│   ├── BRD.lua                  # Module BRD
│   ├── SCH.lua                  # Module SCH
│   └── WHM.lua                  # Module WHM (futur)
└── data/
    ├── alt_registry.json        # IP/Port des ALTs (créé par GUI)
    └── settings.lua             # Configuration utilisateur
```

**Important** :
- ✅ Tout dans le dossier `AltControl/` (pas d'addon séparé)
- ✅ `AltControl.lua` = nom officiel de l'addon
- ✅ `require()` pour charger les modules (pas `//lua load`)
- ✅ Structure identique pour tous les jobs

### Principe de fonctionnement

#### 1. **AltControl.lua** (Point d'entrée - toujours chargé)
```lua
-- Fichier léger (< 150 lignes)
_addon.name = 'AltControl'
_addon.version = '2.0.0'
_addon.author = 'FFXI ALT Control Team'
_addon.commands = {'ac', 'altcontrol'}

-- Charger les bibliothèques core
local comm = require('libs/communication')  -- Gestion serveur + IP/Port
local events = require('libs/events')       -- Système d'événements
local commands = require('libs/commands')   -- Commandes de base

-- État global
local state = {
    server_active = false,
    current_job = nil,
    job_module = nil
}

-- Au chargement de l'addon
windower.register_event('addon command', function(command, ...)
    commands.handle(command, ...)
end)

-- Au login
windower.register_event('login', function()
    -- 1. Charger/Créer le fichier alt_registry.json (IP/Port)
    comm.load_registry()
    
    -- 2. Vérifier si serveur Python répond
    state.server_active = comm.check_server()
    
    -- 3. Si serveur actif, charger le module job
    if state.server_active then
        local player = windower.ffxi.get_player()
        load_job_module(player.main_job)
    else
        print('[AltControl] Serveur Python inactif - Mode minimal')
    end
end)

-- Changement de job
windower.register_event('job change', function(main_job_id)
    if state.server_active then
        unload_job_module()
        local player = windower.ffxi.get_player()
        load_job_module(player.main_job)
    end
end)

-- Charger un module job
function load_job_module(job_name)
    local success, module = pcall(require, 'jobs/'..job_name)
    if success then
        state.job_module = module
        state.current_job = job_name
        if module.init then module.init() end
        print('[AltControl] Module '..job_name..' chargé')
    else
        print('[AltControl] Pas de module pour '..job_name)
    end
end

-- Décharger un module job
function unload_job_module()
    if state.job_module and state.job_module.cleanup then
        state.job_module.cleanup()
    end
    state.job_module = nil
    state.current_job = nil
end
```

#### 2. **core/communication.lua** (Envoi optimisé)
```lua
-- Envoie seulement les CHANGEMENTS
local last_data = {}

function send_delta_update()
    if not server_active then return end
    
    local current_data = get_player_data()
    local changes = {}
    
    -- Comparer avec last_data
    for key, value in pairs(current_data) do
        if last_data[key] ~= value then
            changes[key] = value
        end
    end
    
    -- Envoyer seulement si changements
    if next(changes) then
        send_to_python(changes)
        last_data = current_data
    end
end

-- Événements importants (envoi immédiat)
windower.register_event('status change', function(new_status)
    send_event('status_change', {status = new_status})
end)

windower.register_event('gain buff', function(buff_id)
    send_event('buff_gained', {buff = buff_id})
end)

windower.register_event('lose buff', function(buff_id)
    send_event('buff_lost', {buff = buff_id})
end)
```

#### 3. **libs/communication.lua** (Gestion IP/Port + Serveur)
```lua
local comm = {}

-- Fichier de registre des ALTs (créé par GUI Python)
local registry_file = windower.addon_path..'data/alt_registry.json'

-- Charger le registre IP/Port
function comm.load_registry()
    if windower.file_exists(registry_file) then
        local file = io.open(registry_file, 'r')
        local content = file:read('*all')
        file:close()
        comm.registry = json.decode(content)
    else
        -- Créer fichier vide si n'existe pas
        comm.registry = {}
        comm.save_registry()
    end
end

-- Sauvegarder le registre
function comm.save_registry()
    local file = io.open(registry_file, 'w')
    file:write(json.encode(comm.registry))
    file:close()
end

-- Vérifier si serveur Python répond
function comm.check_server()
    -- Tentative de connexion simple
    local socket = require('socket')
    local client = socket.tcp()
    client:settimeout(1)
    local result = client:connect('127.0.0.1', 5007)
    client:close()
    return result ~= nil
end

-- Envoyer seulement les changements (delta)
local last_data = {}
function comm.send_delta(data)
    local changes = {}
    for key, value in pairs(data) do
        if last_data[key] ~= value then
            changes[key] = value
        end
    end
    if next(changes) then
        comm.send_to_server(changes)
        last_data = data
    end
end

return comm
```

#### 4. **jobs/BRD.lua** (Module job - STRUCTURE STANDARD)
```lua
-- ============================================================
-- STRUCTURE STANDARD POUR TOUS LES JOBS
-- Copier cette structure pour créer un nouveau job
-- ============================================================

local BRD = {}

-- ============================================================
-- 1. CONFIGURATION (éditable par l'utilisateur)
-- ============================================================
BRD.config = {
    -- Songs à utiliser
    mage_songs = {"Mage's Ballad II", "Mage's Ballad III"},
    melee_songs = {"Blade Madrigal", "Sword Madrigal"},
    
    -- Comportement
    auto_follow = true,
    cycle_delay = 3.0,
    
    -- Cibles
    healer_target = nil,  -- Auto-détecté
    melee_target = nil    -- Auto-détecté
}

-- ============================================================
-- 2. ÉTAT INTERNE (ne pas modifier directement)
-- ============================================================
BRD.state = {
    active = false,
    current_phase = "mage",
    songs_cast = 0,
    waiting_for_buffs = false,
    last_update = 0
}

-- ============================================================
-- 3. FONCTIONS OBLIGATOIRES (tous les modules doivent les avoir)
-- ============================================================

-- Initialisation du module
function BRD.init()
    print('[BRD] Module initialized')
    -- Charger config depuis fichier si existe
    BRD.load_config()
end

-- Nettoyage du module
function BRD.cleanup()
    BRD.stop()
    print('[BRD] Module cleaned up')
end

-- Démarrer l'AutoCast
function BRD.start()
    BRD.state.active = true
    BRD.state.last_update = os.clock()
    print('[BRD] AutoCast started')
end

-- Arrêter l'AutoCast
function BRD.stop()
    BRD.state.active = false
    BRD.reset_state()
    print('[BRD] AutoCast stopped')
end

-- Update appelé régulièrement (toutes les 0.1s)
function BRD.update()
    if not BRD.state.active then return end
    
    local now = os.clock()
    if now - BRD.state.last_update < BRD.config.cycle_delay then
        return
    end
    
    BRD.state.last_update = now
    -- Logique du cycle BRD ici
end

-- ============================================================
-- 4. ÉVÉNEMENTS (optionnels selon le job)
-- ============================================================

function BRD.on_engage()
    if BRD.state.active then
        print('[BRD] Engaged - Starting cycle')
        -- Démarrer le cycle
    end
end

function BRD.on_disengage()
    if BRD.state.active then
        print('[BRD] Disengaged - Resetting cycle')
        BRD.reset_state()
    end
end

function BRD.on_buff_gained(buff_id)
    -- Réagir aux buffs gagnés
end

function BRD.on_buff_lost(buff_id)
    -- Réagir aux buffs perdus
end

-- ============================================================
-- 5. FONCTIONS INTERNES (spécifiques au job)
-- ============================================================

function BRD.reset_state()
    BRD.state.current_phase = "mage"
    BRD.state.songs_cast = 0
    BRD.state.waiting_for_buffs = false
end

function BRD.load_config()
    -- Charger depuis data/BRD_config.lua si existe
end

function BRD.save_config()
    -- Sauvegarder dans data/BRD_config.lua
end

-- ============================================================
-- 6. RETOUR DU MODULE
-- ============================================================
return BRD
```

**Cette structure est IDENTIQUE pour tous les jobs** :
- SCH.lua aura les mêmes sections (config, state, fonctions obligatoires, etc.)
- WHM.lua aura les mêmes sections
- Etc.

Seul le contenu des fonctions change selon la logique du job.

#### 5. **libs/distance_follow.lua** (DistanceFollow intégré)
```lua
-- Au lieu d'être un addon séparé, DistanceFollow est une lib
-- Appelé avec require('libs/distance_follow')

local dfollow = {}

dfollow.state = {
    active = false,
    target = nil,
    min_distance = 0.5,
    max_distance = 1.0
}

function dfollow.start(target_name, min_dist, max_dist)
    dfollow.state.active = true
    dfollow.state.target = target_name
    dfollow.state.min_distance = min_dist or 0.5
    dfollow.state.max_distance = max_dist or 1.0
    print('[DistanceFollow] Following '..target_name)
end

function dfollow.stop()
    dfollow.state.active = false
    windower.ffxi.run(false)
    print('[DistanceFollow] Stopped')
end

function dfollow.update()
    if not dfollow.state.active then return end
    -- Logique de follow avec distance
end

return dfollow
```

**Avantage** : Tout dans le même addon, pas besoin de `//lua load DistanceFollow`

---

## 🔄 Plan de migration

### Phase 1 : Préparation (1-2h)
- [x] Créer backup complet
- [ ] Créer structure de dossiers
- [ ] Créer `AltControl.lua` v2 (core léger)
- [ ] Créer `core/communication.lua`

### Phase 2 : Migration BRD (2-3h)
- [ ] Extraire logique BRD dans `modules/BRD.lua`
- [ ] Tester en parallèle avec ancien système
- [ ] Valider que tout fonctionne
- [ ] Supprimer ancien code BRD

### Phase 3 : Migration SCH (1-2h)
- [ ] Extraire logique SCH dans `modules/SCH.lua`
- [ ] Tester
- [ ] Valider
- [ ] Supprimer ancien code SCH

### Phase 4 : Nettoyage (1h)
- [ ] Supprimer ancien `AltControl.lua`
- [ ] Renommer `AltControl_v2.lua` → `AltControl.lua`
- [ ] Tests finaux
- [ ] Documentation

---

## 📈 Gains attendus

### Performance
- ⚡ **90% moins de données** envoyées (delta updates)
- ⚡ **Zéro lag** quand serveur OFF
- ⚡ **Modules chargés** seulement si nécessaires

### Code
- 📁 **Fichiers < 200 lignes** chacun
- 🔧 **Facile à modifier** (un fichier par job)
- 🐛 **Bugs isolés** par module

### Utilisateur
- ✏️ **Éditable** comme GearSwap
- 🎨 **Personnalisable** facilement
- 🚀 **Extensible** (nouveaux jobs)

---

## 🤔 Questions à décider

### 1. Logique BRD : Lua ou Python ?

**Option A : Tout en Lua** (recommandé)
```lua
-- modules/BRD.lua contient TOUTE la logique
-- Python = juste serveur de données
✅ Éditable facilement
✅ Pas de dépendance Python
✅ Performance maximale
❌ Plus complexe à coder en Lua
```

**Option B : Hybride**
```lua
-- Lua = Interface + Événements
-- Python = Logique complexe (cycles)
✅ Plus facile à coder (Python)
❌ Dépendance au serveur
❌ Moins personnalisable
```

### 2. Communication : Événements ou Polling ?

**Option A : Événements** (recommandé)
```lua
-- Envoie seulement quand quelque chose change
windower.register_event('gain buff', send_event)
✅ Minimal data
✅ Temps réel
```

**Option B : Polling optimisé**
```lua
-- Check toutes les 0.5s mais envoie seulement delta
✅ Plus simple
❌ Toujours un peu de overhead
```

---

## 🎯 Recommandation finale

Je recommande :
1. **Logique en Lua** (comme GearSwap) pour performance et personnalisation
2. **Événements** pour communication minimale
3. **Migration progressive** pour éviter de tout casser
4. **Python = API REST** simple (pas de logique métier)

**Temps estimé total** : 5-7 heures de travail
**Risque** : Faible (migration progressive avec backups)
**Gain** : Énorme (performance + maintenabilité)

---

**Prochaine étape** : Valider cette architecture avec toi avant de commencer l'implémentation.
