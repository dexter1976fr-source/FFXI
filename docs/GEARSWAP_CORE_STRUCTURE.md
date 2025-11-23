# 🏗️ Structure Core de GearSwap

## 📦 Architecture Complète

```
┌─────────────────────────────────────────────────────────┐
│  GearSwap Core (gearswap.lua)                          │
│  - Initialisation addon                                 │
│  - Chargement des modules                               │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Triggers (triggers.lua)                                │
│  - windower.register_event('outgoing text')            │
│  - windower.register_event('incoming chunk')           │
│  - parse.i[0x028] (action packets)                     │
│  → Détecte TOUTES les actions du jeu                   │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Flow (flow.lua)                                        │
│  - equip_sets() - Pipeline principal                   │
│  - Gestion precast/midcast/aftercast                   │
│  - Validation des conditions                            │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Sel-Include.lua (Framework utilisateur)               │
│  - États (state.AutoBuffMode, etc.)                    │
│  - Modes tracking                                       │
│  - Hooks pour jobs                                      │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Job Files (BST.lua, BRD.lua, etc.)                    │
│  - Logique job-specific                                 │
│  - Tables de données                                    │
│  - Auto-modes                                           │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  Gear Files (Charactername_Job_Gear.lua)               │
│  - Sets d'équipement                                    │
│  - Configuration personnelle                            │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Ce que GearSwap Gère en Amont

### 1. Détection Universelle des Actions (triggers.lua)

```lua
-- TOUT passe par ici !
windower.register_event('outgoing text', function(original, modified, blocked, ffxi)
    -- Intercepte TOUTES les commandes tapées
    -- /ma, /ja, /ws, /item, /ra, etc.
    
    -- Parse la commande
    -- Valide la target
    -- Crée un "spell object"
    -- Lance le pipeline precast → midcast → aftercast
end)

-- Détecte les actions qui se terminent
parse.i[0x028] = function(data)
    local act = windower.packets.parse_action(data)
    
    -- act.category :
    -- 1 = melee attack
    -- 3 = spell start
    -- 4 = spell finish
    -- 7 = weaponskill
    -- 8 = item use
    -- 11 = monster TP move
    
    -- Déclenche midcast ou aftercast selon le cas
end)
```

### 2. États Globaux Trackés (Sel-Include.lua)

```lua
-- États automatiquement trackés pour TOUS les jobs :

state.Buff['Light Arts'] = buffactive['Light Arts'] or false
state.Buff['Dark Arts'] = buffactive['Dark Arts'] or false
state.Buff['Invisible'] = buffactive['Invisible'] or false
state.Buff['Sneak'] = buffactive['Sneak'] or false
state.Buff['Warcry'] = buffactive['Warcry'] or false
state.Buff['SJ Restriction'] = buffactive['SJ Restriction'] or false

-- Modes universels :
state.AutoBuffMode = M{['description'] = 'Auto Buff Mode', 'Off', 'Auto'}
state.AutoTankMode = M(false, 'Auto Tank Mode')
state.AutoWSMode = M(false, 'Auto Weaponskill Mode')
state.AutoFoodMode = M(false, 'Auto Food Mode')
state.AutoTrustMode = M(false, 'Auto Trust Mode')
state.Kiting = M(false, 'Kiting')
```

### 3. Conditions Validées Automatiquement

```lua
-- Dans flow.lua, avant d'équiper :

if (buffactive.charm or player.charmed) then
    -- Bloque l'équipement si charmé
    return
end

if player.status == 2 or player.status == 3 then
    -- Bloque si mort/engaged dead
    return
end

-- Vérifie encumbrance (surcharge)
for v,i in pairs(default_slot_map) do
    if equip_list[i] and encumbrance_table[v] then
        -- Ne peut pas équiper ce slot
    end
end
```

---

## 🎮 Events Windower Disponibles

### Events Natifs Utilisés par GearSwap

```lua
-- 1. Texte sortant (commandes)
windower.register_event('outgoing text', function(original, modified, blocked, ffxi)
    -- Intercepte /ma, /ja, /ws, etc.
end)

-- 2. Packets entrants (actions du jeu)
windower.register_event('incoming chunk', function(id, data)
    -- id = type de packet
    -- 0x028 = action packet (cast, WS, abilities)
    -- 0x029 = message packet (spell interrupted, etc.)
    -- 0x037 = update char packet (HP/MP/TP change)
    -- 0x063 = party member update
end)

-- 3. Changement de statut
windower.register_event('status change', function(new_status, old_status)
    -- 0 = Idle
    -- 1 = Engaged
    -- 2 = Resting
    -- 3 = Dead
    -- 4 = Zoning
end)

-- 4. Gain/Perte de buff
windower.register_event('gain buff', function(buff_id)
    -- buff_id = ID du buff (voir resources)
end)

windower.register_event('lose buff', function(buff_id)
    -- Buff perdu
end)

-- 5. Changement de zone
windower.register_event('zone change', function(new_id, old_id)
    -- Changement de zone
end)

-- 6. Changement de target
windower.register_event('target change', function(index)
    -- Target changée
end)

-- 7. Frame-by-frame (60 FPS)
windower.register_event('prerender', function()
    -- S'exécute à chaque frame
    -- Utilisé pour auto-modes continus
end)

-- 8. Login/Logout
windower.register_event('login', function(name)
    -- Connexion
end)

windower.register_event('logout', function()
    -- Déconnexion
end)

-- 9. Job change
windower.register_event('job change', function(main_job_id, main_job_level, sub_job_id, sub_job_level)
    -- Changement de job
end)
```

---

## 🔍 Détection d'Aggro (Exemple PLD)

### Comment GearSwap Détecte l'Aggro

```lua
-- Dans triggers.lua, parse.i[0x028]
windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then -- Action packet
        local act = windower.packets.parse_action(data)
        
        -- act.actor_id = qui fait l'action
        -- act.targets = liste des cibles
        -- act.category = type d'action
        
        -- Si un mob attaque le player :
        if act.category == 1 then -- Melee attack
            for _, target in pairs(act.targets) do
                if target.id == player.id then
                    -- LE PLAYER VIENT DE SE FAIRE TAPER !
                    -- = Aggro détectée
                    
                    -- Déclencher réaction PLD :
                    if player.main_job == 'PLD' then
                        -- Flash, Provoke, etc.
                    end
                end
            end
        end
        
        -- Si le player change de status Idle → Engaged
        -- = Le player a attaqué ou pris l'aggro
    end
end)

-- Combiné avec status change :
windower.register_event('status change', function(new, old)
    if new == 1 and old == 0 then
        -- Idle → Engaged
        -- = Combat commencé (aggro ou attaque)
        
        if player.main_job == 'PLD' then
            -- Activer defensive stance
            -- Cast Flash si dispo
        end
    end
end)
```

---

## 💡 Ce qu'on Peut Réutiliser pour AutoCast

### 1. Structure d'Events

```lua
-- Un fichier core qui écoute TOUS les events
windower.register_event('status change', function(new, old)
    handle_status_change(new, old)
end)

windower.register_event('gain buff', function(buff_id)
    handle_buff_gain(buff_id)
end)

windower.register_event('lose buff', function(buff_id)
    handle_buff_loss(buff_id)
end)

windower.register_event('prerender', function()
    -- Auto-modes qui tournent en continu
    check_auto_engage()
    check_auto_buff()
    check_auto_heal()
    process_command_queue()
end)
```

### 2. États Globaux

```lua
-- États trackés automatiquement
autocast_state = {
    enabled = false,
    auto_engage = false,
    auto_buff = false,
    auto_heal = false,
    busy = false,
    player_status = 'Idle', -- Idle, Engaged, Resting, Dead
    buffs = {},
    last_action_time = 0
}

-- Mise à jour automatique
windower.register_event('status change', function(new, old)
    if new == 0 then autocast_state.player_status = 'Idle'
    elseif new == 1 then autocast_state.player_status = 'Engaged'
    elseif new == 2 then autocast_state.player_status = 'Resting'
    elseif new == 3 then autocast_state.player_status = 'Dead'
    end
end)
```

### 3. Validation des Conditions

```lua
function can_act()
    -- Reprendre les checks de GearSwap
    if player.status == 3 then return false end -- Dead
    if buffactive.charm then return false end -- Charmed
    if buffactive.sleep then return false end -- Sleep
    if buffactive.stun then return false end -- Stun
    if buffactive.petrification then return false end -- Petrified
    if buffactive.terror then return false end -- Terror
    
    return true
end

function can_cast_spell()
    if not can_act() then return false end
    if buffactive.silence then return false end
    if player.mp == 0 then return false end
    
    return true
end
```

### 4. Queue Robuste

```lua
local command_queue = {}
local last_command_time = 0
local command_delay = 0.5

windower.register_event('prerender', function()
    if #command_queue > 0 then
        local now = os.clock()
        
        -- Vérifier si on peut agir
        if not can_act() then return end
        
        -- Respecter le délai
        if now - last_command_time < command_delay then return end
        
        -- Exécuter la commande
        local cmd = table.remove(command_queue, 1)
        windower.send_command(cmd)
        last_command_time = now
    end
end)
```

---

## 🎯 Réponse à ta Question

### "Il faut un Lua qui remonte tous les états ?"

**OUI !** GearSwap a un **core central** qui :

1. ✅ **Écoute TOUS les events Windower** (triggers.lua)
2. ✅ **Track TOUS les états** (Sel-Include.lua)
3. ✅ **Valide TOUTES les conditions** (flow.lua)
4. ✅ **Fournit des hooks** pour les jobs

### Pour AutoCast, on doit créer :

```
AutoCast_Core.lua
├── Events listeners (status, buffs, actions)
├── État global (player status, buffs, busy)
├── Validation (can_act, can_cast, etc.)
├── Queue de commandes
└── Hooks pour jobs

AutoCast_BRD.lua
├── include('AutoCast_Core.lua')
├── Configuration BRD
├── Auto-songs logic
└── Utilise les hooks du core

AutoCast_WHM.lua
├── include('AutoCast_Core.lua')
├── Configuration WHM
├── Auto-heal logic
└── Utilise les hooks du core
```

---

## 📝 Prochaine Étape

**Créer AutoCast_Core.lua** qui :
- Écoute les events essentiels
- Track l'état du player
- Fournit une queue robuste
- Valide les conditions
- Expose des hooks pour les jobs

Ensuite, chaque job inclut ce core et ajoute sa logique spécifique.

---

**Date:** 22 novembre 2024  
**Source:** GearSwap core files analysis  
**Version:** 1.0
