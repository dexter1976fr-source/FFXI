# ⚠️ CurePlease - Analyse d'un Anti-Pattern

## 🎯 Qu'est-ce que CurePlease ?

Un addon Windower qui envoie les données de buffs/debuffs à une **application externe (.exe)** qui décide quand heal.

**Note:** L'exe contient probablement un **API codé** (compilé) avec toute la logique de décision, mais le problème reste le même : la logique est **externe** au jeu.

---

## 🏗️ Architecture CurePlease

```
┌─────────────────────────────────────────┐
│  CurePlease_Addon.lua (Windower)       │
│  - Écoute packets (0x076 = party buffs)│
│  - Envoie via UDP socket                │
└──────────────┬──────────────────────────┘
               │ UDP (127.0.0.1:19769)
┌──────────────▼──────────────────────────┐
│  CurePlease.exe (Application externe)   │
│  - Reçoit les données                   │
│  - DÉCIDE quand heal                    │
│  - Envoie commandes via UDP             │
└──────────────┬──────────────────────────┘
               │ UDP
┌──────────────▼──────────────────────────┐
│  Windower (exécute commandes)           │
│  - Cast Cure                            │
└─────────────────────────────────────────┘
```

---

## 📊 Ce que fait le Lua (Minimal)

### 1. Envoie les Buffs Party

```lua
-- Packet 0x076 = Party buffs update
windower.register_event('incoming chunk', function (id, data)
  if id == 0x076 then
    Run_Buff_Function(id, data)
  end
end)

function Run_Buff_Function(id, data)
  -- Parse les buffs de chaque party member
  for k = 0, 4 do
    local Uid = data:unpack('I', k * 48 + 5)
    -- ...
    -- Construit string: "CUREPLEASE_buffs_CharName_1,2,3,4"
    -- Envoie via UDP
    local CP_connect = assert(socket.udp())
    assert(CP_connect:sendto(formattedString, ip, port))
    CP_connect:close()
  end
end
```

### 2. Envoie l'État du Cast

```lua
windower.register_event('action', function (data)
  if data.actor_id == windower.ffxi.get_player().id then
    if data.category == 4 then
      casting = 'CUREPLEASE_casting_finished'
    elseif data.category == 8 then
      if data.param == 28787 then
        casting = 'CUREPLEASE_casting_interrupted'
      elseif data.param == 24931 then
        casting = 'CUREPLEASE_casting_blocked'
      end
    end
    
    -- Envoie via UDP
    local CP_connect = assert(socket.udp())
    assert(CP_connect:sendto(casting, ip, port))
    CP_connect:close()
  end
end)
```

### 3. Reçoit des Commandes

```lua
windower.register_event('addon command', function(input, ...)
  if cmd == "cmd" then
    -- Reçoit commande de l'exe
    local CP_connect = assert(socket.udp())
    assert(CP_connect:sendto("CUREPLEASE_command_"..args[1]:lower(), ip, port))
    CP_connect:close()
  end
end)
```

---

## ❌ Pourquoi C'est Problématique

### 1. Logique Externe = Latence

```
Windower → UDP → .exe → Décision → UDP → Windower → Cast
   ↓         ↓      ↓        ↓        ↓       ↓        ↓
  1ms      5ms    ?ms      ?ms      5ms     1ms      2s

Total: ~15ms + temps de décision de l'exe
```

**Problème:** Trop lent pour réagir en combat

### 2. Pas de Validation Locale

```lua
// L'exe dit "Cast Cure IV"
// Le Lua exécute SANS vérifier :
- Player silenced ?
- Player moving ?
- Player busy ?
- Enough MP ?
- Spell on recast ?
- Target in range ?

= ÉCHEC GARANTI
```

### 3. Pas de Gestion d'État

```lua
// L'exe ne sait pas :
- Player status (Idle/Engaged/Dead)
- Player position
- Player movement
- Combat state
- Busy state

= Décisions basées sur données incomplètes
```

### 4. Spam de Commandes

```lua
// L'exe peut envoyer :
"Cast Cure IV"
"Cast Cure IV"  // 0.1s plus tard
"Cast Cure IV"  // 0.1s plus tard

// Windower essaie d'exécuter tout
// = Queue saturée, MP gaspillé
```

### 5. Pas de Priorités

```lua
// Tout est traité pareil :
- Heal critique (tank à 10% HP)
- Heal normal (DD à 80% HP)
- Buff refresh

// Pas de système de priorité
// = Mauvaises décisions
```

---

## 🎭 Ton Expérience

> "Les heal se retrouvent à sec de MP très vite et en plein combat pas de heal, plus de MP"

### Pourquoi ça arrive :

```
Combat commence
  ↓
Party prend des dégâts
  ↓
CurePlease.exe voit HP bas
  ↓
Spam "Cure IV" sur tout le monde
  ↓
Windower exécute sans vérifier MP
  ↓
MP = 0 en 10 secondes
  ↓
Plus de heal possible
  ↓
WIPE
```

### Ce qui manque :

1. **MP Management**
   ```lua
   if player.mp < 100 then
       -- Ne pas heal sauf critique
   end
   ```

2. **Priorité des Heals**
   ```lua
   if target.hpp < 30 then
       -- Heal critique
   elseif player.mp > 500 then
       -- Heal normal
   else
       -- Attendre
   end
   ```

3. **Throttling**
   ```lua
   if last_heal_time + 2 > os.clock() then
       -- Pas de spam
       return
   end
   ```

4. **Validation**
   ```lua
   if not can_cast_spell("Cure IV") then
       return
   end
   ```

---

## ✅ Ce qu'on Peut en Apprendre

### 1. Ne PAS Faire

❌ Logique dans une app externe  
❌ Pas de validation locale  
❌ Pas de gestion d'état  
❌ Spam de commandes  
❌ Pas de priorités  

### 2. À Faire

✅ **Toute la logique en Lua**
```lua
-- Décision locale, instantanée
if should_heal(target) and can_cast_spell("Cure IV") then
    cast_heal(target)
end
```

✅ **Validation avant exécution**
```lua
function can_cast_spell(spell)
    -- Vérifier TOUTES les conditions
    return validation.can_cast_spell(spell)
end
```

✅ **Gestion d'état complète**
```lua
-- Tracker tout localement
autocast.player.status
autocast.player.moving
autocast.player.busy
autocast.combat.stable
```

✅ **Queue avec priorités**
```lua
queue.add(cmd, PRIORITY.CRITICAL)  -- Heal tank
queue.add(cmd, PRIORITY.NORMAL)    -- Heal DD
```

✅ **MP Management**
```lua
function should_heal(target)
    if player.mp < 100 then
        return target.hpp < 30  -- Seulement critique
    end
    return target.hpp < 75
end
```

---

## 🎯 Comparaison avec Notre V2

| Aspect | CurePlease | AutoCast V2 |
|--------|-----------|-------------|
| Logique | .exe externe | Lua local |
| Latence | ~15ms+ | <1ms |
| Validation | ❌ Aucune | ✅ Complète |
| État | ❌ Partiel | ✅ Complet |
| Queue | ❌ Aucune | ✅ Avec priorités |
| MP Management | ❌ Non | ✅ Oui |
| Priorités | ❌ Non | ✅ Oui |
| Throttling | ❌ Non | ✅ Oui |
| Robustesse | ⚠️ Faible | ✅ Forte |

---

## 💡 Leçons pour AutoCast V2

### 1. Tout en Lua

```lua
-- ✅ BON
function check_auto_heal()
    local target = find_heal_target()
    if target and can_cast_spell("Cure IV") then
        if should_heal(target) then
            cast_heal(target)
        end
    end
end

-- ❌ MAUVAIS (CurePlease style)
function check_auto_heal()
    send_to_external_app(party_data)
    wait_for_decision()
    execute_command_from_app()
end
```

### 2. Validation Locale

```lua
function can_cast_spell(spell)
    -- Vérifier TOUT localement
    if not can_act() then return false end
    if player.moving then return false end
    if player.busy then return false end
    if buffactive.silence then return false end
    if player.mp < spell.mp_cost then return false end
    if spell_on_recast(spell) then return false end
    return true
end
```

### 3. MP Management Intelligent

```lua
function should_heal(target)
    local mp_percent = player.mp / player.max_mp * 100
    
    if mp_percent < 20 then
        -- MP critique : seulement heals d'urgence
        return target.hpp < 30
    elseif mp_percent < 50 then
        -- MP bas : heals importants
        return target.hpp < 50
    else
        -- MP OK : heals normaux
        return target.hpp < 75
    end
end
```

### 4. Priorités Intelligentes

```lua
function find_heal_target()
    local targets = get_party_members()
    
    -- Trier par priorité
    table.sort(targets, function(a, b)
        -- Tank en danger = priorité max
        if a.is_tank and a.hpp < 30 then return true end
        if b.is_tank and b.hpp < 30 then return false end
        
        -- Sinon, HP le plus bas
        return a.hpp < b.hpp
    end)
    
    return targets[1]
end
```

### 5. Throttling

```lua
local last_heal_time = 0
local heal_cooldown = 2.0

function cast_heal(target)
    local now = os.clock()
    if now - last_heal_time < heal_cooldown then
        return  -- Pas de spam
    end
    
    queue.add('/ma "Cure IV" ' .. target.name, PRIORITY.HIGH)
    last_heal_time = now
end
```

---

## 🎯 Conclusion

**CurePlease est un parfait exemple de ce qu'il NE FAUT PAS faire :**

1. ❌ Logique externe = latence
2. ❌ Pas de validation = échecs
3. ❌ Pas de gestion MP = à sec
4. ❌ Pas de priorités = mauvaises décisions
5. ❌ Spam = gaspillage

**AutoCast V2 fait l'inverse :**

1. ✅ Logique locale = instantané
2. ✅ Validation complète = fiable
3. ✅ MP management = durable
4. ✅ Priorités = intelligent
5. ✅ Queue = contrôlé

---

## 📝 Note Finale

CurePlease a essayé de faire comme toi (logique externe), mais en pire :
- Toi : Python (au moins c'est scriptable)
- Eux : .exe compilé (boîte noire)

Résultat : **Les deux ne marchent pas bien** pour les mêmes raisons.

**La solution : Tout en Lua, comme GearSwap !** 🎯

---

**Date:** 22 novembre 2024  
**Source:** CurePlease_Addon.lua analysis  
**Version:** 1.0 - Anti-pattern documentation
