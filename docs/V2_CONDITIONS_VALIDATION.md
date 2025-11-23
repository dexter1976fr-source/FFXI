# ✅ AutoCast V2 - Validation des Conditions

## 🎯 Objectif

Lister **TOUTES** les conditions à vérifier avant d'exécuter une action, pour éviter les échecs et interruptions.

---

## 🚦 Conditions Globales (Toutes Actions)

### 1. État du Player

```lua
function can_act()
    -- Statut invalide
    if player.status == 3 then return false, "Player is dead" end
    if player.status == 4 then return false, "Player is zoning" end
    
    -- Buffs bloquants
    if buffactive.charm then return false, "Player is charmed" end
    if buffactive.sleep then return false, "Player is asleep" end
    if buffactive.stun then return false, "Player is stunned" end
    if buffactive.petrification then return false, "Player is petrified" end
    if buffactive.terror then return false, "Player is terrified" end
    if buffactive.amnesia then return false, "Player has amnesia" end
    
    -- Animations bloquantes
    if player.in_combat_animation then return false, "Player in combat animation" end
    
    return true, "OK"
end
```

### 2. Mouvement

```lua
local last_position = {x = 0, y = 0, z = 0}
local movement_threshold = 0.1

function is_player_moving()
    local pos = windower.ffxi.get_mob_by_target('me')
    if not pos then return false end
    
    local moved = math.sqrt(
        (pos.x - last_position.x)^2 +
        (pos.y - last_position.y)^2 +
        (pos.z - last_position.z)^2
    ) > movement_threshold
    
    last_position = {x = pos.x, y = pos.y, z = pos.z}
    return moved
end
```

### 3. Busy State

```lua
local busy_state = {
    casting = false,
    using_ability = false,
    using_item = false,
    weaponskill = false,
    last_action_time = 0
}

function is_busy()
    local now = os.clock()
    
    -- Timeout de sécurité (3 secondes)
    if now - busy_state.last_action_time > 3 then
        reset_busy_state()
        return false
    end
    
    return busy_state.casting 
        or busy_state.using_ability 
        or busy_state.using_item
        or busy_state.weaponskill
end
```

---

## 🎭 Conditions par Type d'Action

### 1. Cast Spell (Magic)

```lua
function can_cast_spell(spell_name)
    -- Conditions globales
    local can, reason = can_act()
    if not can then return false, reason end
    
    -- Mouvement
    if is_player_moving() then 
        return false, "Player is moving" 
    end
    
    -- Busy
    if is_busy() then 
        return false, "Player is busy" 
    end
    
    -- Silence
    if buffactive.silence then 
        return false, "Player is silenced" 
    end
    
    -- MP
    local spell = res.spells:with('name', spell_name)
    if not spell then 
        return false, "Spell not found" 
    end
    
    if player.mp < spell.mp_cost then 
        return false, "Not enough MP" 
    end
    
    -- Recast
    local recast = windower.ffxi.get_spell_recasts()[spell.id]
    if recast and recast > 0 then 
        return false, "Spell on recast: " .. recast .. "s" 
    end
    
    -- Job/Subjob
    if not has_spell(spell.id) then 
        return false, "Spell not available" 
    end
    
    return true, "OK"
end
```

### 2. Use Ability (JA)

```lua
function can_use_ability(ability_name)
    -- Conditions globales
    local can, reason = can_act()
    if not can then return false, reason end
    
    -- Busy
    if is_busy() then 
        return false, "Player is busy" 
    end
    
    -- Ability data
    local ability = res.job_abilities:with('name', ability_name)
    if not ability then 
        return false, "Ability not found" 
    end
    
    -- Recast
    local recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
    if recast and recast > 0 then 
        return false, "Ability on recast: " .. recast .. "s" 
    end
    
    -- TP (pour certaines abilities)
    if ability.tp_cost and player.tp < ability.tp_cost then 
        return false, "Not enough TP" 
    end
    
    -- Job/Subjob
    if not has_ability(ability.id) then 
        return false, "Ability not available" 
    end
    
    return true, "OK"
end
```

### 3. Weaponskill

```lua
function can_use_weaponskill(ws_name)
    -- Conditions globales
    local can, reason = can_act()
    if not can then return false, reason end
    
    -- Engaged
    if player.status ~= 1 then 
        return false, "Not engaged" 
    end
    
    -- TP
    if player.tp < 1000 then 
        return false, "Not enough TP" 
    end
    
    -- Target
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then 
        return false, "No target" 
    end
    
    if target.hpp == 0 then 
        return false, "Target is dead" 
    end
    
    -- Distance
    if target.distance > 6 then 
        return false, "Target out of range" 
    end
    
    -- WS data
    local ws = res.weapon_skills:with('name', ws_name)
    if not ws then 
        return false, "Weaponskill not found" 
    end
    
    return true, "OK"
end
```

### 4. Engage/Attack

```lua
function can_engage()
    -- Conditions globales
    local can, reason = can_act()
    if not can then return false, reason end
    
    -- Déjà engaged
    if player.status == 1 then 
        return false, "Already engaged" 
    end
    
    -- Target
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then 
        return false, "No target" 
    end
    
    if target.hpp == 0 then 
        return false, "Target is dead" 
    end
    
    -- Distance
    if target.distance > 20 then 
        return false, "Target too far" 
    end
    
    -- Type de mob
    if target.spawn_type ~= 16 then 
        return false, "Invalid target type" 
    end
    
    -- Claim
    if target.claim_id ~= 0 and target.claim_id ~= player.id then 
        return false, "Target claimed by another" 
    end
    
    return true, "OK"
end
```

---

## 🎵 Conditions Spécifiques BRD

### Auto-Songs : Attendre Stabilité Combat

```lua
local brd_combat_state = {
    engaged_flag = false,
    first_hit_done = false,
    stable_since = 0,
    stability_required = 2.0  -- 2 secondes
}

-- Détection premier coup
windower.register_event('action', function(act)
    if act.actor_id == player.id and act.category == 1 then
        if not brd_combat_state.first_hit_done then
            brd_combat_state.first_hit_done = true
            brd_combat_state.stable_since = os.clock()
        end
    end
end)

function can_start_brd_songs()
    -- Conditions globales de cast
    local can, reason = can_cast_spell("Valor Minuet IV")
    if not can then return false, reason end
    
    -- Engaged
    if player.status ~= 1 then 
        return false, "Not engaged" 
    end
    
    -- Premier coup effectué
    if not brd_combat_state.first_hit_done then 
        return false, "Waiting for first hit" 
    end
    
    -- Stabilité
    local stable_time = os.clock() - brd_combat_state.stable_since
    if stable_time < brd_combat_state.stability_required then 
        return false, "Waiting for stability: " .. 
                     string.format("%.1f", brd_combat_state.stability_required - stable_time) .. "s" 
    end
    
    -- Pas en mouvement
    if is_player_moving() then 
        return false, "Player is moving" 
    end
    
    return true, "OK"
end

-- Reset au désengagement
windower.register_event('status change', function(new, old)
    if new == 0 and old == 1 then
        brd_combat_state.first_hit_done = false
        brd_combat_state.stable_since = 0
    end
end)
```

---

## 🩹 Conditions Spécifiques WHM

### Auto-Heal : Vérifications

```lua
function can_auto_heal()
    -- Conditions globales de cast
    local can, reason = can_cast_spell("Cure IV")
    if not can then return false, reason end
    
    -- Pas en combat actif (optionnel)
    if player.in_combat and player.hpp > 50 then 
        return false, "In active combat, HP not critical" 
    end
    
    return true, "OK"
end

function find_heal_target()
    local party = windower.ffxi.get_party()
    local targets = {}
    
    for i = 0, 5 do
        local member = party['p' .. i]
        if member and member.mob then
            local mob = windower.ffxi.get_mob_by_id(member.mob.id)
            if mob and mob.hpp > 0 and mob.hpp < 75 then
                -- Distance check
                if mob.distance < 21 then
                    table.insert(targets, {
                        name = member.name,
                        hpp = mob.hpp,
                        distance = mob.distance,
                        id = member.mob.id
                    })
                end
            end
        end
    end
    
    -- Trier par HP le plus bas
    table.sort(targets, function(a, b) return a.hpp < b.hpp end)
    
    return targets[1]
end
```

---

## 🐾 Conditions Spécifiques BST

### Auto-Ready : Vérifications Pet

```lua
function can_use_ready()
    -- Conditions globales
    local can, reason = can_use_ability("Sic")
    if not can then return false, reason end
    
    -- Pet existe
    if not pet.isvalid then 
        return false, "No pet" 
    end
    
    -- Pet vivant
    if pet.hpp == 0 then 
        return false, "Pet is dead" 
    end
    
    -- Pet engaged
    if pet.status ~= 1 then 
        return false, "Pet not engaged" 
    end
    
    -- Pet TP
    if pet.tp < 1000 then 
        return false, "Pet TP too low" 
    end
    
    -- Target
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then 
        return false, "No target" 
    end
    
    if target.hpp == 0 then 
        return false, "Target is dead" 
    end
    
    -- Distance pet-target
    local pet_mob = windower.ffxi.get_mob_by_id(pet.id)
    if pet_mob and target then
        local distance = math.sqrt(
            (pet_mob.x - target.x)^2 +
            (pet_mob.y - target.y)^2 +
            (pet_mob.z - target.z)^2
        )
        if distance > 20 then 
            return false, "Pet too far from target" 
        end
    end
    
    return true, "OK"
end
```

---

## 🎯 Conditions Spécifiques SMN

### Auto-Blood Pact

```lua
function can_use_blood_pact()
    -- Pet existe
    if not pet.isvalid then 
        return false, "No avatar" 
    end
    
    -- Pet vivant
    if pet.hpp == 0 then 
        return false, "Avatar is dead" 
    end
    
    -- MP pour maintenir avatar
    if player.mp < 50 then 
        return false, "MP too low to maintain avatar" 
    end
    
    -- Recast Blood Pact
    local recast = windower.ffxi.get_ability_recasts()[173] -- Blood Pact: Rage
    if recast and recast > 0 then 
        return false, "Blood Pact on recast: " .. recast .. "s" 
    end
    
    -- Target
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then 
        return false, "No target" 
    end
    
    if target.hpp == 0 then 
        return false, "Target is dead" 
    end
    
    return true, "OK"
end
```

---

## 📊 Matrice de Validation

| Action Type | Global | Moving | Busy | Silence | MP | TP | Recast | Target | Distance | Stability |
|-------------|--------|--------|------|---------|----|----|--------|--------|----------|-----------|
| Cast Spell  | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ⚠️ | ⚠️ | ❌ |
| Use Ability | ✅ | ❌ | ✅ | ❌ | ❌ | ⚠️ | ✅ | ⚠️ | ⚠️ | ❌ |
| Weaponskill | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Engage      | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| BRD Songs   | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| WHM Heal    | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| BST Ready   | ✅ | ❌ | ✅ | ❌ | ❌ | ⚠️ | ✅ | ✅ | ✅ | ❌ |
| SMN BP      | ✅ | ❌ | ✅ | ❌ | ⚠️ | ❌ | ✅ | ✅ | ⚠️ | ❌ |

**Légende:**
- ✅ = Requis
- ❌ = Non applicable
- ⚠️ = Dépend du contexte

---

## 🔧 Implémentation Recommandée

```lua
-- Validation centralisée
local validators = {
    spell = can_cast_spell,
    ability = can_use_ability,
    weaponskill = can_use_weaponskill,
    engage = can_engage,
    brd_songs = can_start_brd_songs,
    whm_heal = can_auto_heal,
    bst_ready = can_use_ready,
    smn_bp = can_use_blood_pact
}

function validate_action(action_type, action_name)
    local validator = validators[action_type]
    if not validator then
        return false, "Unknown action type"
    end
    
    return validator(action_name)
end

-- Utilisation
local can, reason = validate_action('spell', 'Cure IV')
if can then
    execute_action('spell', 'Cure IV')
else
    log_debug("Cannot cast Cure IV: " .. reason)
end
```

---

**Date:** 22 novembre 2024  
**Version:** 1.0 - Blueprint V2  
**Status:** Documentation de conception
