----------------------------------------------------------
-- DISTANCE FOLLOW - Basé sur FastFollow
-- Version: 1.0.0
----------------------------------------------------------

_addon.name = 'MageFastFollow'
_addon.author = 'FFXI ALT Control Team'
_addon.version = '1.0.0'
_addon.commands = {'mfollow', 'mf'}

require('coroutine')

-- État
local following = false
local target_name = nil
local min_dist = 14^2  -- Distance minimale au carré (14 yalms)
local max_dist = 16^2  -- Distance maximale au carré (16 yalms)
local running = false
local auto_follow_p1 = false  -- Follow automatique de <p1>

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
        auto_follow_p1 = false
        target_name = nil
        running = false
        windower.ffxi.run(false)
        print('[MageFastFollow] Stopped')
        
    elseif command == 'auto' then
        -- Mode auto : follow <p1> automatiquement
        auto_follow_p1 = true
        following = true
        min_dist = 14^2
        max_dist = 16^2
        print('[MageFastFollow] Auto mode: Following <p1> at 15 yalms')
        
    elseif #args >= 1 then
        target_name = args[1]
        local min_val = tonumber(args[2]) or 14
        local max_val = tonumber(args[3]) or 16
        
        min_dist = min_val^2
        max_dist = max_val^2
        following = true
        auto_follow_p1 = false
        
        print('[MageFastFollow] Following: '..target_name)
        print('[MageFastFollow] Distance: '..min_val..' - '..max_val..' yalms')
        
    else
        print('[MageFastFollow] Usage:')
        print('  //mfollow auto - Follow <p1> at 15 yalms')
        print('  //mfollow [name] [min] [max]')
        print('  //mfollow stop')
    end
end)

----------------------------------------------------------
-- PRERENDER (appelé chaque frame)
----------------------------------------------------------
windower.register_event('prerender', function()
    if not following then 
        if running then
            windower.ffxi.run(false)
            running = false
        end
        return 
    end
    
    local self = windower.ffxi.get_mob_by_target('me')
    local player = windower.ffxi.get_player()
    
    if not self or not player then
        if running then
            windower.ffxi.run(false)
            running = false
        end
        return
    end
    
    -- Mode auto : trouver <p1>
    local target
    if auto_follow_p1 then
        local party = windower.ffxi.get_party()
        if party and party.p1 then
            target = windower.ffxi.get_mob_by_id(party.p1.mob and party.p1.mob.id)
        end
    else
        target = windower.ffxi.get_mob_by_name(target_name)
    end
    
    if not target then
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
    
    -- Ajuster la distance selon l'engagement de <p1>
    local target_engaged = false
    if auto_follow_p1 then
        local party = windower.ffxi.get_party()
        if party and party.p1 then
            local p1_mob = party.p1.mob
            if p1_mob then
                target_engaged = (p1_mob.status == 1)  -- 1 = engaged
                -- Debug
                if target_engaged then
                    print('[MageFastFollow] DEBUG: P1 is ENGAGED, switching to 15 yalms')
                end
            end
        end
    end
    
    -- Distance selon engagement
    if target_engaged then
        min_dist = 14^2  -- 14 yalms
        max_dist = 16^2  -- 16 yalms
    else
        min_dist = 0.5^2  -- 0.5 yalms
        max_dist = 1.5^2  -- 1.5 yalms
    end
    
    local distSq = distanceSquared(target, self)
    local distance_yalms = math.sqrt(distSq)
    
    -- Debug distance
    if auto_follow_p1 and target_engaged then
        print(string.format('[MageFastFollow] Distance: %.1f yalms (target: 15)', distance_yalms))
    end
    
    -- Trop proche quand engagé → Reculer avec setkey
    if target_engaged and distance_yalms < 14 then
        if not running then
            print('[MageFastFollow] Too close! Backing up...')
            windower.send_command('setkey numpad2 down;wait 1;setkey numpad2 up')
            running = true
        end
    -- Trop loin → Avancer
    elseif distSq > max_dist and distSq < 50^2 then
        local len = distance_yalms
        if len < 1 then len = 1 end
        windower.ffxi.run((target.x - self.x)/len, (target.y - self.y)/len)
        running = true
    -- Bonne distance → Arrêter
    elseif distSq >= min_dist and distSq <= max_dist then
        if running then
            windower.ffxi.run(false)
            running = false
        end
    end
end)

print('[MageFastFollow] Loaded - Use //mfollow auto for SCH positioning')
