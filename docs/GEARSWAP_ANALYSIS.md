# 🔍 Analyse GearSwap - Structure et Patterns

## 📚 Architecture en 2 Niveaux

```
┌─────────────────────────────────────────────┐
│  BST.lua (Template Job - Logique)          │
│  - Events Windower                          │
│  - États et modes                           │
│  - Fonctions job-specific                   │
│  - Tables de données (ready moves, etc.)    │
└──────────────┬──────────────────────────────┘
               │ include()
┌──────────────▼──────────────────────────────┐
│  Dexterbrown_Bst_Gear.lua (Gear Personnel) │
│  - Sets d'équipement                        │
│  - Configuration personnelle                │
│  - Overrides de fonctions                   │
└─────────────────────────────────────────────┘
```

## 🎯 Séparation des Responsabilités

### Fichier Job (BST.lua, BRD.lua, etc.)
**Contient la LOGIQUE du job :**
- ✅ Events Windower (precast, midcast, aftercast)
- ✅ États et modes (state.AutoReadyMode, state.PetMode)
- ✅ Conditions intelligentes (buffactive, player.status)
- ✅ Tables de données job-specific
- ✅ Automatismes (auto-reward, auto-ready, etc.)

### Fichier Gear (Charactername_Job_Gear.lua)
**Contient l'ÉQUIPEMENT personnel :**
- ✅ Sets de gear (precast, midcast, idle, engaged)
- ✅ Configuration des modes
- ✅ Binds de touches
- ✅ Overrides de fonctions si nécessaire

---

## 🎮 Events Windower Clés

### 1. Cycle de Cast
```lua
-- PRECAST : Avant le cast (Fast Cast gear)
function job_precast(spell, action, spellMap, eventArgs)
    if spell.type == 'BardSong' then
        -- Équiper Fast Cast + instrument
    end
end

-- MIDCAST : Pendant le cast (Potency gear)
function job_midcast(spell, action, spellMap, eventArgs)
    if spell.type == 'BardSong' then
        -- Équiper Song Duration + Instrument spécifique
    end
end

-- AFTERCAST : Après le cast (Retour idle/engaged)
function job_aftercast(spell, action, spellMap, eventArgs)
    -- Retour au set idle ou engaged
end
```

### 2. Changements d'État
```lua
-- Status change : idle, engaged, resting, dead
windower.register_event('status change', function(new_status, old_status)
    if new_status == 'Engaged' then
        -- Activer auto-engage logic
    elseif new_status == 'Idle' then
        -- Désactiver auto-engage
    end
end)

-- Buff change : gain/lose buffs
windower.register_event('gain buff', function(buff_id)
    if buff_id == 214 then -- Pianissimo
        -- Ajuster song logic
    end
end)

windower.register_event('lose buff', function(buff_id)
    -- Réagir à la perte de buff
end)
```

### 3. Actions et Targets
```lua
-- Action : détecte toutes les actions (cast, WS, abilities)
windower.register_event('action', function(act)
    if act.actor_id == player.id then
        -- Réagir à nos propres actions
    end
end)

-- Target change
windower.register_event('target change', function(index)
    -- Réagir au changement de cible
end)
```

### 4. Prerender (Frame-by-frame)
```lua
-- S'exécute à chaque frame (60 FPS)
windower.register_event('prerender', function()
    -- Auto-modes qui checkent en continu
    if state.AutoReadyMode.value then
        check_ready_move()
    end
    if state.AutoRewardMode.value then
        check_pet_hp()
    end
end)
```

---

## 🎭 Système de Modes (States)

### Définition des Modes
```lua
-- Mode avec options multiples
state.PetMode = M{['description']='Pet Mode', 'Tank', 'DD'}
state.JugMode = M{['description']='Jug Mode', 'ScissorlegXerin', 'BlackbeardRandy', ...}

-- Mode boolean (on/off)
state.AutoReadyMode = M(false, 'Auto Ready Mode')
state.AutoRewardMode = M(true, 'Auto Reward Mode')

-- Mode avec tracking de buff
state.Buff['Killer Instinct'] = buffactive['Killer Instinct'] or false
state.Buff['Unleash'] = buffactive['Unleash'] or false
```

### Utilisation des Modes
```lua
-- Toggle
gs c toggle AutoReadyMode

-- Cycle entre options
gs c cycle PetMode  -- Tank → DD → Tank

-- Set direct
gs c set JugMode BlackbeardRandy
```

---

## 📊 Tables de Données Job-Specific

### Exemple BST : Ready Moves
```lua
-- Moves par catégorie
ready_moves = {}
ready_moves.default = {
    ['DroopyDortwin'] = 'Foot Kick',
    ['HeraldHenry'] = 'Big Scissors',
    ['WarlikePatrick'] = 'Fireball',
    -- ...
}

ready_moves.aoe = {
    ['DroopyDortwin'] = 'Whirl Claws',
    ['HeraldHenry'] = 'Bubble Shower',
    -- ...
}

ready_moves.buff = {
    ['DroopyDortwin'] = 'Wild Carrot',
    ['RhymingShizuna'] = 'Rage',
    -- ...
}

-- Listes de moves par type
magic_ready_moves = S{'Dust Cloud', 'Sheep Song', 'Fireball', ...}
debuff_ready_moves = S{'Dust Cloud', 'Sheep Song', 'Spoil', ...}
multi_hit_ready_moves = S{'Pentapeck', 'Tickling Tendrils', ...}
```

### Exemple BRD : Song Categories
```lua
-- Dans Sel-Mappings.lua ou job file
classes.BardSong = {
    ['Ballad'] = S{'Mage\'s Ballad', 'Mage\'s Ballad II', ...},
    ['March'] = S{'Advancing March', 'Victory March', ...},
    ['Minuet'] = S{'Sword Madrigal', 'Blade Madrigal', ...},
    ['Madrigal'] = S{'Sword Madrigal', 'Blade Madrigal', ...},
    ['Paeon'] = S{'Army\'s Paeon', 'Army\'s Paeon II', ...},
}
```

---

## 🤖 Automatismes Intelligents

### BST Auto-Reward
```lua
state.AutoRewardMode = M(true, 'Auto Reward Mode')
state.RewardMode = M{['description']='Reward Mode', 'Theta', 'Zeta', 'Eta'}

-- Dans prerender
windower.register_event('prerender', function()
    if state.AutoRewardMode.value and pet.isvalid then
        local pet_hpp = pet.hpp
        if pet_hpp < 85 and not buffactive['Reward'] then
            local food = 'Pet Food ' .. state.RewardMode.value
            send_command('input /ja "Reward" <me>')
        end
    end
end)
```

### BST Auto-Ready
```lua
state.AutoReadyMode = M(false, 'Auto Ready Mode')

function check_ready_move()
    if not pet.isvalid or pet.status ~= 'Engaged' then return end
    
    local target = windower.ffxi.get_mob_by_target('t')
    if not target or target.hpp == 0 then return end
    
    -- Sélectionner le ready move approprié
    local move = ready_moves.default[pet.name]
    if move and ready_available() then
        send_command('input /pet "'..move..'" <t>')
    end
end
```

### BRD Auto-Songs (Concept)
```lua
state.AutoSongMode = M(false, 'Auto Song Mode')

local song_rotation = {
    "Valor Minuet IV",
    "Valor Minuet V", 
    "Victory March",
    "Advancing March"
}

local current_song_index = 1
local last_song_time = 0

function check_auto_songs()
    if not state.AutoSongMode.value then return end
    if player.status ~= 'Idle' then return end
    
    local now = os.clock()
    if now - last_song_time < 3 then return end -- Délai entre songs
    
    local song = song_rotation[current_song_index]
    send_command('input /ma "'..song..'" <me>')
    
    current_song_index = current_song_index + 1
    if current_song_index > #song_rotation then
        current_song_index = 1
    end
    
    last_song_time = now
end
```

---

## 🔧 Fonctions Utilitaires Windower

### Informations Player
```lua
player.status           -- 'Idle', 'Engaged', 'Resting', 'Dead'
player.hp               -- HP actuel
player.hpp              -- HP en pourcentage
player.mp               -- MP actuel
player.mpp              -- MP en pourcentage
player.tp               -- TP actuel
player.main_job         -- 'BRD', 'BST', etc.
player.sub_job          -- Subjob
```

### Informations Pet
```lua
pet.isvalid             -- Pet existe
pet.name                -- Nom du pet
pet.status              -- 'Idle', 'Engaged'
pet.hp                  -- HP du pet
pet.hpp                 -- HP% du pet
pet.tp                  -- TP du pet
```

### Informations Target
```lua
local target = windower.ffxi.get_mob_by_target('t')
target.name             -- Nom
target.hpp              -- HP%
target.distance         -- Distance
target.is_npc           -- Est un NPC
target.claim_id         -- ID du claimer
```

### Buffs Actifs
```lua
buffactive['Haste']             -- true/false
buffactive['Pianissimo']        -- true/false
buffactive[214]                 -- Par ID de buff
```

### Recast Info
```lua
-- Spell recast
local recast = windower.ffxi.get_spell_recasts()[spell_id]

-- Ability recast
local recast = windower.ffxi.get_ability_recasts()[ability_id]
```

---

## 💡 Patterns à Réutiliser pour AutoCast

### 1. Structure de Base
```lua
-- États
state.AutoEngageMode = M(false, 'Auto Engage')
state.AutoBuffMode = M(false, 'Auto Buff')

-- Queue de commandes
local command_queue = {}
local last_command_time = 0

function queue_command(cmd)
    table.insert(command_queue, {
        cmd = cmd,
        time = os.clock()
    })
end

-- Process queue
windower.register_event('prerender', function()
    if #command_queue > 0 then
        local now = os.clock()
        if now - last_command_time > 0.5 then -- Délai entre commandes
            local cmd = table.remove(command_queue, 1)
            windower.send_command(cmd.cmd)
            last_command_time = now
        end
    end
end)
```

### 2. Auto-Engage Pattern
```lua
function check_auto_engage()
    if not state.AutoEngageMode.value then return end
    if player.status == 'Engaged' then return end
    
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then
        target = find_nearest_enemy()
    end
    
    if target and target.hpp > 0 and target.distance < 20 then
        queue_command('input /attack <t>')
    end
end

function find_nearest_enemy()
    local mob_array = windower.ffxi.get_mob_array()
    local nearest = nil
    local min_distance = 999
    
    for i, mob_id in pairs(mob_array) do
        local mob = windower.ffxi.get_mob_by_id(mob_id)
        if mob and mob.hpp > 0 and mob.spawn_type == 16 then -- Monster
            if mob.distance < min_distance and mob.distance < 20 then
                nearest = mob
                min_distance = mob.distance
            end
        end
    end
    
    return nearest
end
```

### 3. Auto-Buff Cycle Pattern
```lua
local buff_rotation = {
    "Haste",
    "Protect V",
    "Shell V"
}

local current_buff_index = 1
local last_buff_time = 0

function check_auto_buff()
    if not state.AutoBuffMode.value then return end
    if player.status ~= 'Idle' then return end
    
    local now = os.clock()
    if now - last_buff_time < 2 then return end
    
    local buff = buff_rotation[current_buff_index]
    
    -- Check si buff déjà actif
    if not buffactive[buff] then
        queue_command('input /ma "'..buff..'" <me>')
        last_buff_time = now
    end
    
    current_buff_index = current_buff_index + 1
    if current_buff_index > #buff_rotation then
        current_buff_index = 1
    end
end
```

### 4. Commandes IPC (depuis Python)
```lua
-- Recevoir commandes externes
windower.register_event('ipc message', function(msg)
    if msg:startswith('autocast_') then
        handle_autocast_command(msg)
    end
end)

function handle_autocast_command(msg)
    local parts = msg:split('_')
    local command = parts[2]
    local value = parts[3]
    
    if command == 'engage' then
        if value == 'on' then
            state.AutoEngageMode:set(true)
        else
            state.AutoEngageMode:set(false)
        end
    elseif command == 'buff' then
        if value == 'on' then
            state.AutoBuffMode:set(true)
        else
            state.AutoBuffMode:set(false)
        end
    end
end
```

---

## 🎯 Ce qu'on Doit Adapter

### Pour AutoCast Template

1. **Reprendre la structure d'events**
   - prerender pour auto-modes
   - status change pour idle/engaged
   - buff tracking

2. **Système de modes (states)**
   - state.AutoEngageMode
   - state.AutoBuffMode
   - state.AutoSongsMode (BRD)
   - state.AutoReadyMode (BST)

3. **Queue de commandes robuste**
   - Délai entre commandes
   - Gestion des priorités
   - Retry sur échec

4. **Tables de données job-specific**
   - Song rotations (BRD)
   - Ready moves (BST)
   - Spell priorities (WHM)
   - Roll combinations (COR)

5. **Conditions intelligentes**
   - player.status checks
   - buffactive checks
   - target validation
   - distance checks

---

## 📝 Différences avec Notre Approche

### GearSwap
- ✅ Gear swapping automatique
- ✅ Events natifs Windower
- ✅ Très mature et testé
- ❌ Complexe pour débutants
- ❌ Focalisé sur le gear

### Notre AutoCast
- ✅ Focalisé sur les automatismes
- ✅ Contrôle via Web App
- ✅ Plus simple à configurer
- ✅ Pas de gear swapping (optionnel)
- ✅ Queue robuste pour latence réseau

---

**Date:** 22 novembre 2024  
**Source:** GearSwap addons (BST.lua, BRD.lua, helper_functions.lua)  
**Version:** 1.0
