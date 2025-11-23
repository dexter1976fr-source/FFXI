# 🏗️ AutoCast V2 - Architecture Complète

## 🎯 Vision Globale

Une architecture **robuste, modulaire et extensible** inspirée de GearSwap, adaptée pour le contrôle multi-personnages.

---

## 📦 Structure des Fichiers

```
Windower4/addons/AutoCast/
├── AutoCast.lua                    # Core principal
├── AutoCast_Core.lua               # Events & État global
├── AutoCast_Queue.lua              # Queue de commandes
├── AutoCast_Validation.lua         # Validation des conditions
├── AutoCast_Utils.lua              # Fonctions utilitaires
│
├── jobs/
│   ├── AutoCast_BRD.lua           # Logique BRD
│   ├── AutoCast_WHM.lua           # Logique WHM
│   ├── AutoCast_BST.lua           # Logique BST
│   ├── AutoCast_SMN.lua           # Logique SMN
│   ├── AutoCast_GEO.lua           # Logique GEO
│   ├── AutoCast_COR.lua           # Logique COR
│   └── ...
│
├── data/
│   ├── spell_data.lua             # Données des sorts
│   ├── ability_data.lua           # Données des abilities
│   └── job_configs.lua            # Configurations par job
│
└── libs/
    ├── modes.lua                  # Système de modes
    └── events.lua                 # Gestionnaire d'events
```

---

## 🧠 AutoCast_Core.lua - Le Cerveau

### Responsabilités

1. **Écouter tous les events Windower**
2. **Tracker l'état global du player**
3. **Fournir des hooks pour les jobs**
4. **Gérer la communication IPC**

### Structure

```lua
-- ============================================
-- AUTOCAST CORE - État Global & Events
-- ============================================

_addon.name = 'AutoCast'
_addon.version = '2.0.0'
_addon.author = 'Dexter'
_addon.commands = {'autocast', 'ac'}

require('logger')
require('tables')
require('sets')
require('lists')

-- Modules
local queue = require('AutoCast_Queue')
local validation = require('AutoCast_Validation')
local utils = require('AutoCast_Utils')

-- ============================================
-- ÉTAT GLOBAL
-- ============================================

autocast = {
    enabled = false,
    version = '2.0.0',
    
    -- État du player
    player = {
        status = 'Idle',        -- Idle, Engaged, Resting, Dead, Zoning
        moving = false,
        busy = false,
        last_action_time = 0,
        position = {x = 0, y = 0, z = 0}
    },
    
    -- Buffs actifs
    buffs = {},
    
    -- Combat state
    combat = {
        engaged = false,
        first_hit_done = false,
        stable_since = 0,
        target_id = 0
    },
    
    -- Modes
    modes = {
        auto_engage = false,
        auto_buff = false,
        auto_heal = false,
        debug = false
    },
    
    -- Job-specific state (sera rempli par les job files)
    job_state = {}
}

-- ============================================
-- EVENTS WINDOWER
-- ============================================

-- Status Change (Idle, Engaged, Resting, Dead)
windower.register_event('status change', function(new_status, old_status)
    autocast.player.status = get_status_name(new_status)
    
    -- Hooks pour jobs
    if user_status_change then
        user_status_change(new_status, old_status)
    end
    
    if job_status_change then
        job_status_change(new_status, old_status)
    end
    
    -- Reset combat state si désengagement
    if new_status == 0 and old_status == 1 then
        reset_combat_state()
    end
end)

-- Gain Buff
windower.register_event('gain buff', function(buff_id)
    autocast.buffs[buff_id] = true
    
    if user_gain_buff then
        user_gain_buff(buff_id)
    end
    
    if job_gain_buff then
        job_gain_buff(buff_id)
    end
end)

-- Lose Buff
windower.register_event('lose buff', function(buff_id)
    autocast.buffs[buff_id] = nil
    
    if user_lose_buff then
        user_lose_buff(buff_id)
    end
    
    if job_lose_buff then
        job_lose_buff(buff_id)
    end
end)

-- Action (Détecte toutes les actions)
windower.register_event('action', function(act)
    -- Player action
    if act.actor_id == player.id then
        handle_player_action(act)
        
        if user_action then
            user_action(act)
        end
        
        if job_action then
            job_action(act)
        end
    end
    
    -- Action sur le player
    for _, target in pairs(act.targets) do
        if target.id == player.id then
            handle_action_on_player(act, target)
        end
    end
end)

-- Prerender (60 FPS)
windower.register_event('prerender', function()
    -- Update position & movement
    update_player_position()
    
    -- Process queue
    queue.process()
    
    -- Auto-modes
    if autocast.enabled then
        if user_prerender then
            user_prerender()
        end
        
        if job_prerender then
            job_prerender()
        end
    end
end)

-- Zone Change
windower.register_event('zone change', function(new_id, old_id)
    reset_all_states()
    
    if user_zone_change then
        user_zone_change(new_id, old_id)
    end
end)

-- IPC Messages (depuis Python)
windower.register_event('ipc message', function(msg)
    handle_ipc_message(msg)
end)

-- ============================================
-- FONCTIONS CORE
-- ============================================

function handle_player_action(act)
    autocast.player.last_action_time = os.clock()
    
    -- Melee attack
    if act.category == 1 then
        if not autocast.combat.first_hit_done then
            autocast.combat.first_hit_done = true
            autocast.combat.stable_since = os.clock()
        end
    end
    
    -- Spell start
    if act.category == 3 then
        autocast.player.busy = true
    end
    
    -- Spell finish
    if act.category == 4 then
        autocast.player.busy = false
    end
    
    -- Weaponskill
    if act.category == 7 then
        autocast.player.busy = true
        coroutine.schedule(function()
            autocast.player.busy = false
        end, 2)
    end
end

function update_player_position()
    local mob = windower.ffxi.get_mob_by_target('me')
    if not mob then return end
    
    local old_pos = autocast.player.position
    local new_pos = {x = mob.x, y = mob.y, z = mob.z}
    
    -- Détection mouvement
    local distance = math.sqrt(
        (new_pos.x - old_pos.x)^2 +
        (new_pos.y - old_pos.y)^2 +
        (new_pos.z - old_pos.z)^2
    )
    
    autocast.player.moving = distance > 0.1
    autocast.player.position = new_pos
end

function reset_combat_state()
    autocast.combat.engaged = false
    autocast.combat.first_hit_done = false
    autocast.combat.stable_since = 0
    autocast.combat.target_id = 0
end

function reset_all_states()
    reset_combat_state()
    autocast.player.busy = false
    autocast.player.moving = false
    queue.clear()
end

-- ============================================
-- IPC HANDLING
-- ============================================

function handle_ipc_message(msg)
    -- Format: "autocast_command_value"
    local parts = msg:split('_')
    if parts[1] ~= 'autocast' then return end
    
    local command = parts[2]
    local value = parts[3]
    
    if command == 'enable' then
        autocast.enabled = (value == 'on')
        
    elseif command == 'mode' then
        local mode = parts[3]
        local state = parts[4]
        autocast.modes[mode] = (state == 'on')
        
    elseif command == 'execute' then
        -- Commande directe
        local cmd = table.concat(parts, '_', 3)
        queue.add(cmd)
    end
    
    -- Hook utilisateur
    if user_ipc_message then
        user_ipc_message(msg)
    end
end

-- ============================================
-- API PUBLIQUE
-- ============================================

function autocast.queue_command(cmd, priority)
    queue.add(cmd, priority)
end

function autocast.can_act()
    return validation.can_act()
end

function autocast.can_cast_spell(spell_name)
    return validation.can_cast_spell(spell_name)
end

function autocast.can_use_ability(ability_name)
    return validation.can_use_ability(ability_name)
end

-- ============================================
-- HELPERS
-- ============================================

function get_status_name(status_id)
    local statuses = {
        [0] = 'Idle',
        [1] = 'Engaged',
        [2] = 'Resting',
        [3] = 'Dead',
        [4] = 'Zoning'
    }
    return statuses[status_id] or 'Unknown'
end

-- ============================================
-- LOAD JOB FILE
-- ============================================

function load_job_file()
    local job = player.main_job
    local job_file = 'jobs/AutoCast_' .. job .. '.lua'
    
    if windower.file_exists(windower.addon_path .. job_file) then
        include(job_file)
        windower.add_to_chat(122, '[AutoCast] Loaded ' .. job .. ' module')
    else
        windower.add_to_chat(123, '[AutoCast] No module for ' .. job)
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

windower.register_event('load', function()
    load_job_file()
    windower.add_to_chat(122, '[AutoCast] v' .. autocast.version .. ' loaded')
end)

windower.register_event('job change', function()
    reset_all_states()
    load_job_file()
end)
```

---

## 🎯 AutoCast_Queue.lua - Queue Robuste

```lua
-- ============================================
-- QUEUE DE COMMANDES
-- ============================================

local queue = {}

local command_queue = {}
local last_command_time = 0
local command_delay = 0.5

-- Priorités
local PRIORITY = {
    CRITICAL = 1,   -- Urgence (heal critique)
    HIGH = 2,       -- Important (buff manquant)
    NORMAL = 3,     -- Normal (rotation)
    LOW = 4         -- Optionnel
}

function queue.add(cmd, priority)
    priority = priority or PRIORITY.NORMAL
    
    table.insert(command_queue, {
        cmd = cmd,
        priority = priority,
        time = os.clock()
    })
    
    -- Trier par priorité
    table.sort(command_queue, function(a, b)
        return a.priority < b.priority
    end)
end

function queue.process()
    if #command_queue == 0 then return end
    
    local now = os.clock()
    
    -- Respecter le délai
    if now - last_command_time < command_delay then return end
    
    -- Vérifier si on peut agir
    if not autocast.can_act() then return end
    
    -- Exécuter la commande
    local item = table.remove(command_queue, 1)
    windower.send_command('input ' .. item.cmd)
    last_command_time = now
end

function queue.clear()
    command_queue = {}
end

function queue.size()
    return #command_queue
end

return queue
```

---

## ✅ AutoCast_Validation.lua - Validation

```lua
-- ============================================
-- VALIDATION DES CONDITIONS
-- ============================================

local validation = {}

function validation.can_act()
    if player.status == 3 then return false, "Dead" end
    if player.status == 4 then return false, "Zoning" end
    if buffactive.charm then return false, "Charmed" end
    if buffactive.sleep then return false, "Sleep" end
    if buffactive.stun then return false, "Stun" end
    if buffactive.petrification then return false, "Petrified" end
    if buffactive.terror then return false, "Terror" end
    
    return true, "OK"
end

function validation.can_cast_spell(spell_name)
    local can, reason = validation.can_act()
    if not can then return false, reason end
    
    if autocast.player.moving then return false, "Moving" end
    if autocast.player.busy then return false, "Busy" end
    if buffactive.silence then return false, "Silenced" end
    
    -- TODO: Check MP, recast, etc.
    
    return true, "OK"
end

function validation.can_use_ability(ability_name)
    local can, reason = validation.can_act()
    if not can then return false, reason end
    
    if autocast.player.busy then return false, "Busy" end
    
    -- TODO: Check recast, TP, etc.
    
    return true, "OK"
end

return validation
```

---

## 🎭 Exemple Job File - AutoCast_BRD.lua

```lua
-- ============================================
-- AUTOCAST BRD - Bard Logic
-- ============================================

-- Configuration
local brd_config = {
    songs = {
        "Valor Minuet IV",
        "Valor Minuet V",
        "Victory March",
        "Advancing March"
    },
    cycle_delay = 3.0,
    stability_required = 2.0
}

-- État BRD
local brd_state = {
    current_song_index = 1,
    last_song_time = 0,
    songs_active = false
}

-- ============================================
-- HOOKS
-- ============================================

function job_status_change(new_status, old_status)
    if new_status == 1 and old_status == 0 then
        -- Engaged
        brd_state.songs_active = false
    elseif new_status == 0 and old_status == 1 then
        -- Disengaged
        brd_state.current_song_index = 1
        brd_state.songs_active = false
    end
end

function job_prerender()
    if not autocast.modes.auto_buff then return end
    
    check_auto_songs()
end

-- ============================================
-- AUTO-SONGS
-- ============================================

function check_auto_songs()
    if not can_start_songs() then return end
    
    local now = os.clock()
    if now - brd_state.last_song_time < brd_config.cycle_delay then return end
    
    cast_next_song()
end

function can_start_songs()
    -- Engaged
    if autocast.player.status ~= 'Engaged' then return false end
    
    -- Premier coup effectué
    if not autocast.combat.first_hit_done then return false end
    
    -- Stabilité
    local stable_time = os.clock() - autocast.combat.stable_since
    if stable_time < brd_config.stability_required then return false end
    
    -- Pas en mouvement
    if autocast.player.moving then return false end
    
    -- Peut caster
    local can, reason = autocast.can_cast_spell(brd_config.songs[1])
    if not can then return false end
    
    return true
end

function cast_next_song()
    local song = brd_config.songs[brd_state.current_song_index]
    
    autocast.queue_command('/ma "' .. song .. '" <me>')
    
    brd_state.last_song_time = os.clock()
    brd_state.current_song_index = brd_state.current_song_index + 1
    
    if brd_state.current_song_index > #brd_config.songs then
        brd_state.current_song_index = 1
        brd_state.songs_active = true
    end
end

windower.add_to_chat(122, '[AutoCast] BRD module loaded')
```

---

## 🔄 Flow d'Exécution

```
1. Event Windower déclenché
   ↓
2. Core met à jour l'état global
   ↓
3. Core appelle les hooks job
   ↓
4. Job décide d'une action
   ↓
5. Job ajoute commande à la queue
   ↓
6. Queue valide les conditions
   ↓
7. Queue exécute la commande
   ↓
8. Event action détecté
   ↓
9. Core met à jour busy state
   ↓
10. Cycle recommence
```

---

## 🎯 Avantages de cette Architecture

1. **Modulaire** : Chaque job est indépendant
2. **Robuste** : Validation centralisée
3. **Extensible** : Facile d'ajouter des jobs
4. **Maintenable** : Code organisé et documenté
5. **Performant** : Queue optimisée
6. **Fiable** : Gestion des edge cases

---

**Date:** 22 novembre 2024  
**Version:** 2.0 - Blueprint complet  
**Status:** Documentation de conception
