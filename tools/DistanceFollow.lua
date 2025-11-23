----------------------------------------------------------
-- DISTANCE FOLLOW - Module intégré AltControl
-- Version: 2.0.0 (Module)
----------------------------------------------------------

local DistanceFollow = {}

-- État
DistanceFollow.enabled = false
DistanceFollow.target_name = nil
DistanceFollow.running = false

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
function DistanceFollow.updateDistances(auto_engage_active)
    if auto_engage_active then
        -- Mode combat : distance de mêlée
        current_min_sq = DistanceFollow.config.combat_min^2
        current_max_sq = DistanceFollow.config.combat_max^2
    else
        -- Mode suivi : distance safe
        current_min_sq = DistanceFollow.config.follow_min^2
        current_max_sq = DistanceFollow.config.follow_max^2
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
    DistanceFollow.updateDistances(auto_engage_active or false)
    
    local mode = auto_engage_active and "combat" or "follow"
    local min_val = auto_engage_active and DistanceFollow.config.combat_min or DistanceFollow.config.follow_min
    local max_val = auto_engage_active and DistanceFollow.config.combat_max or DistanceFollow.config.follow_max
    
    print('[DistanceFollow] Following: '..target..' (mode: '..mode..')')
    print('[DistanceFollow] Distance: '..min_val..' - '..max_val..' yalms')
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
function DistanceFollow.handleCommand(command, ...)
    local args = {...}
    
    if command == 'stop' then
        DistanceFollow.stop()
        
    elseif command == 'config' then
        if #args >= 4 then
            local c_min = tonumber(args[1])
            local c_max = tonumber(args[2])
            local f_min = tonumber(args[3])
            local f_max = tonumber(args[4])
            DistanceFollow.setDistances(c_min, c_max, f_min, f_max)
        else
            print('[DistanceFollow] Current config:')
            print('  Combat: '..DistanceFollow.config.combat_min..' - '..DistanceFollow.config.combat_max)
            print('  Follow: '..DistanceFollow.config.follow_min..' - '..DistanceFollow.config.follow_max)
        end
        
    elseif #args >= 1 then
        local target = args[1]
        local auto_engage = args[2] == 'combat' or args[2] == 'true'
        DistanceFollow.start(target, auto_engage)
        
    else
        print('[DistanceFollow] Usage:')
        print('  //ac dfollow [name] [mode]')
        print('  //ac dfollow stop')
        print('  //ac dfollow config [combat_min] [combat_max] [follow_min] [follow_max]')
        print('Example: //ac dfollow Dexterbrown combat')
    end
end

return DistanceFollow
