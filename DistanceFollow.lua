----------------------------------------------------------
-- DISTANCE FOLLOW - Basé sur FastFollow
-- Version: 1.0.0
----------------------------------------------------------

_addon.name = 'DistanceFollow'
_addon.author = 'FFXI ALT Control Team'
_addon.version = '1.0.0'
_addon.commands = {'dfollow', 'df'}

require('coroutine')

-- État
local following = false
local target_name = nil
local min_dist = 1.5^2  -- Distance minimale au carré
local max_dist = 2.5^2  -- Distance maximale au carré
local running = false

----------------------------------------------------------
-- CALCUL DE DISTANCE AU CARRÉ (plus rapide)
----------------------------------------------------------
function distanceSquared(target, self)
    if not target or not self then return 999999 end
    local dx = target.x - self.x
    local dy = target.y - self.y
    return dx*dx + dy*dy
end

----------------------------------------------------------
-- COMMANDES
----------------------------------------------------------
windower.register_event('addon command', function(command, ...)
    local args = {...}
    
    if command == 'stop' then
        following = false
        target_name = nil
        running = false
        windower.ffxi.run(false)
        print('[DistanceFollow] Stopped')
        
    elseif #args >= 1 then
        target_name = args[1]
        local min_val = tonumber(args[2]) or 1.5
        local max_val = tonumber(args[3]) or 2.5
        
        min_dist = min_val^2
        max_dist = max_val^2
        following = true
        
        print('[DistanceFollow] Following: '..target_name)
        print('[DistanceFollow] Distance: '..min_val..' - '..max_val..' yalms')
        
    else
        print('[DistanceFollow] Usage:')
        print('  //dfollow [name] [min] [max]')
        print('  //dfollow stop')
        print('Example: //dfollow Dexterbrown 1.5 2.5')
    end
end)

----------------------------------------------------------
-- PRERENDER (appelé chaque frame)
----------------------------------------------------------
windower.register_event('prerender', function()
    if not following or not target_name then 
        if running then
            windower.ffxi.run(false)
            running = false
        end
        return 
    end
    
    local self = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(target_name)
    local player = windower.ffxi.get_player()
    
    if not self or not target or not player then
        if running then
            windower.ffxi.run(false)
            running = false
        end
        return
    end
    
    -- Ne pas bouger si en train de caster
    if player.status == 4 then
        if running then
            windower.ffxi.run(false)
            running = false
        end
        return
    end
    
    local distSq = distanceSquared(target, self)
    local len = math.sqrt(distSq)
    if len < 1 then len = 1 end
    
    -- Trop proche (< min) → Reculer
    if distSq < min_dist then
        windower.ffxi.run(-(target.x - self.x)/len, -(target.y - self.y)/len)
        running = true
    -- Trop loin (> max) → Avancer
    elseif distSq > max_dist and distSq < 50^2 then
        windower.ffxi.run((target.x - self.x)/len, (target.y - self.y)/len)
        running = true
    -- Entre min et max → Bonne distance, arrêter
    elseif running then
        windower.ffxi.run(false)
        running = false
    end
end)

print('[DistanceFollow] Loaded - Use //dfollow [name] [min] [max]')
