----------------------------------------------------------
-- DISTANCE FOLLOW - Module intégré AltControl
-- Version: 2.0.0 (Module)
----------------------------------------------------------

local DistanceFollow = {}

-- État
DistanceFollow.enabled = false
DistanceFollow.target_name = nil
DistanceFollow.running = false
DistanceFollow.auto_engage_active = false  -- État d'AutoEngage

-- Configuration des distances (modifiable dynamiquement)
DistanceFollow.config = {
    -- Mode combat (AutoEngage ON)
    combat_min = 0.5,
    combat_max = 1.0,
    
    -- Mode suivi (AutoEngage OFF)
    follow_min = 10,
    follow_max = 18,
    
    -- Distance max pour éviter de courir trop loin
    max_chase_distance = 50
}

-- État actuel des distances (au carré pour optimisation)
local current_min_sq = DistanceFollow.config.follow_min^2
local current_max_sq = DistanceFollow.config.follow_max^2

----------------------------------------------------------
-- CALCUL DE DISTANCE AU CARRÉ (plus rapide)
----------------------------------------------------------
local function distanceSquared(target, self)
    if not target or not self then return 999999 end
    local dx = target.x - self.x
    local dy = target.y - self.y
    return dx*dx + dy*dy
end

----------------------------------------------------------
-- UPDATE DES DISTANCES SELON MODE
----------------------------------------------------------
function DistanceFollow.updateDistances(auto_engage_active, target_engaged)
    -- Logique corrigée:
    -- Si mode combat ET target engagé → Reculer pour laisser le main combattre
    -- Sinon → Rester proche
    
    if auto_engage_active and target_engaged then
        -- Mode combat: le main est engagé, on recule pour le laisser combattre
        current_min_sq = DistanceFollow.config.follow_min^2
        current_max_sq = DistanceFollow.config.follow_max^2
    else
        -- Rester proche (par défaut ou si le main n'est pas engagé)
        current_min_sq = DistanceFollow.config.combat_min^2
        current_max_sq = DistanceFollow.config.combat_max^2
    end
end

----------------------------------------------------------
-- DÉMARRER LE SUIVI
----------------------------------------------------------
function DistanceFollow.start(target, auto_engage_active)
    -- Convertir <p1> en nom réel
    if target == '<p1>' then
        local party = windower.ffxi.get_party()
        if party and party.p1 and party.p1.name then
            target = party.p1.name
        else
            print('[DistanceFollow] ❌ Cannot find party leader')
            return
        end
    end
    
    DistanceFollow.target_name = target
    DistanceFollow.enabled = true
    DistanceFollow.auto_engage_active = auto_engage_active or false
    
    -- Démarrer toujours en mode combat (0.5-1)
    current_min_sq = DistanceFollow.config.combat_min^2
    current_max_sq = DistanceFollow.config.combat_max^2
    
    print('[DistanceFollow] Following: '..target..' (AutoEngage: '..(auto_engage_active and 'ON' or 'OFF')..')')
    print('[DistanceFollow] Distance: '..DistanceFollow.config.combat_min..' - '..DistanceFollow.config.combat_max..' yalms')
    print('[DistanceFollow] Will retreat to '..DistanceFollow.config.follow_min..'-'..DistanceFollow.config.follow_max..' if target engages and AutoEngage is OFF')
end

----------------------------------------------------------
-- ARRÊTER LE SUIVI
----------------------------------------------------------
function DistanceFollow.stop()
    DistanceFollow.enabled = false
    DistanceFollow.target_name = nil
    if DistanceFollow.running then
        windower.ffxi.run(false)
        DistanceFollow.running = false
    end
    print('[DistanceFollow] Stopped')
end

----------------------------------------------------------
-- TOGGLE ON/OFF
----------------------------------------------------------
function DistanceFollow.toggle(target, auto_engage_active)
    if DistanceFollow.enabled then
        DistanceFollow.stop()
    else
        DistanceFollow.start(target, auto_engage_active)
    end
end

----------------------------------------------------------
-- CONFIGURATION DES DISTANCES
----------------------------------------------------------
function DistanceFollow.setDistances(combat_min, combat_max, follow_min, follow_max)
    if combat_min then DistanceFollow.config.combat_min = combat_min end
    if combat_max then DistanceFollow.config.combat_max = combat_max end
    if follow_min then DistanceFollow.config.follow_min = follow_min end
    if follow_max then DistanceFollow.config.follow_max = follow_max end
    
    print('[DistanceFollow] Config updated:')
    print('  Combat: '..DistanceFollow.config.combat_min..' - '..DistanceFollow.config.combat_max)
    print('  Follow: '..DistanceFollow.config.follow_min..' - '..DistanceFollow.config.follow_max)
end

----------------------------------------------------------
-- UPDATE (appelé chaque frame depuis AltControl)
----------------------------------------------------------
function DistanceFollow.update()
    if not DistanceFollow.enabled or not DistanceFollow.target_name then 
        if DistanceFollow.running then
            windower.ffxi.run(false)
            DistanceFollow.running = false
        end
        return 
    end
    
    local self = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(DistanceFollow.target_name)
    local player = windower.ffxi.get_player()
    
    if not self or not target or not player then
        if DistanceFollow.running then
            windower.ffxi.run(false)
            DistanceFollow.running = false
        end
        return
    end
    
    -- Ne pas bouger si en train de caster
    if player.status == 4 then
        if DistanceFollow.running then
            windower.ffxi.run(false)
            DistanceFollow.running = false
        end
        return
    end
    
    -- 🆕 Détecter si le target est engagé (status == 1)
    local target_engaged = (target.status == 1)
    
    -- 🆕 Ajuster automatiquement les distances selon l'état
    DistanceFollow.updateDistances(DistanceFollow.auto_engage_active, target_engaged)
    
    local distSq = distanceSquared(target, self)
    local len = math.sqrt(distSq)
    if len < 1 then len = 1 end
    
    local max_chase_sq = DistanceFollow.config.max_chase_distance^2
    
    -- Trop proche (< min) → Reculer
    if distSq < current_min_sq then
        windower.ffxi.run(-(target.x - self.x)/len, -(target.y - self.y)/len)
        DistanceFollow.running = true
    -- Trop loin (> max) → Avancer
    elseif distSq > current_max_sq and distSq < max_chase_sq then
        windower.ffxi.run((target.x - self.x)/len, (target.y - self.y)/len)
        DistanceFollow.running = true
    -- Entre min et max → Bonne distance, arrêter
    elseif DistanceFollow.running then
        windower.ffxi.run(false)
        DistanceFollow.running = false
    end
end

----------------------------------------------------------
-- COMMANDES
----------------------------------------------------------
function DistanceFollow.handleCommand(...)
    local args = {...}
    
    -- Debug: afficher tous les arguments reçus
    print('[DistanceFollow] 🐛 handleCommand called with '..#args..' args')
    for i, arg in ipairs(args) do
        print('[DistanceFollow] 🐛 arg['..i..'] = '..tostring(arg))
    end
    
    if #args == 0 then
        print('[DistanceFollow] Usage:')
        print('  //ac dfollow [mode] [name]')
        print('  //ac dfollow stop')
        print('  //ac dfollow config [combat_min] [combat_max] [follow_min] [follow_max]')
        print('Example: //ac dfollow combat Dexterbrown')
        return
    end
    
    local command = args[1]
    
    if command == 'stop' then
        DistanceFollow.stop()
        
    elseif command == 'config' then
        if #args >= 5 then
            local c_min = tonumber(args[2])
            local c_max = tonumber(args[3])
            local f_min = tonumber(args[4])
            local f_max = tonumber(args[5])
            DistanceFollow.setDistances(c_min, c_max, f_min, f_max)
        else
            print('[DistanceFollow] Current config:')
            print('  Combat: '..DistanceFollow.config.combat_min..' - '..DistanceFollow.config.combat_max)
            print('  Follow: '..DistanceFollow.config.follow_min..' - '..DistanceFollow.config.follow_max)
        end
        
    elseif command == 'combat' or command == 'follow' then
        -- Syntaxe: //ac dfollow [mode] [target]
        local mode = command
        local target = args[2] or '<p1>'
        local auto_engage = (mode == 'combat')
        DistanceFollow.start(target, auto_engage)
        
    else
        -- Fallback: si le premier arg n'est pas une commande connue, on assume que c'est le nom
        -- Syntaxe alternative: //ac dfollow [name] [mode]
        local target = args[1]
        local auto_engage = args[2] == 'combat' or args[2] == 'true'
        DistanceFollow.start(target, auto_engage)
    end
end

return DistanceFollow
