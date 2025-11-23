----------------------------------------------------------
-- AUTO CAST BRD - SMART FOLLOW (VERSION CORRIGÉE)
-- Basé sur les idées de l'autre IA mais adapté correctement
----------------------------------------------------------

local brd = {
    config = {
        healerTarget = nil,
        meleeTarget = nil,
        mageSongs = {},
        meleeSongs = {},
    },
    
    active = false,
    follow_target = nil,
    follow_distance = 3,
    song_queue = {},
    last_queue_process = 0,
    
    -- Smart Follow State
    is_moving = false,
    is_casting = false,
    last_stop_time = 0,
    last_follow_update = 0,
}

----------------------------------------------------------
-- CONFIG
----------------------------------------------------------
function brd.load_config()
    local config_path = windower.addon_path..'data/autocast_config.json'
    local file = io.open(config_path, 'r')
    
    if not file then
        print('[BRD] ⚠️ Config file not found')
        return false
    end
    
    local content = file:read('*all')
    file:close()
    
    local healer = content:match('"healerTarget"%s*:%s*"([^"]+)"')
    local melee = content:match('"meleeTarget"%s*:%s*"([^"]+)"')
    
    if healer then brd.config.healerTarget = healer end
    if melee then brd.config.meleeTarget = melee end
    
    local mage_songs_str = content:match('"mageSongs"%s*:%s*%[([^%]]+)%]')
    if mage_songs_str then
        brd.config.mageSongs = {}
        for song in mage_songs_str:gmatch('"([^"]+)"') do
            table.insert(brd.config.mageSongs, song)
        end
    end
    
    local melee_songs_str = content:match('"meleeSongs"%s*:%s*%[([^%]]+)%]')
    if melee_songs_str then
        brd.config.meleeSongs = {}
        for song in melee_songs_str:gmatch('"([^"]+)"') do
            table.insert(brd.config.meleeSongs, song)
        end
    end
    
    print('[BRD] ✅ Config loaded (Smart Follow)')
    return true
end

----------------------------------------------------------
-- SMART FOLLOW
----------------------------------------------------------
function brd.follow(target_name, distance)
    if not target_name then return end
    
    brd.follow_target = target_name
    brd.follow_distance = distance or 3
    
    print('[BRD] 🎯 Smart Following: '..target_name..' (distance='..brd.follow_distance..')')
end

function brd.stop_follow()
    brd.follow_target = nil
    brd.is_moving = false
    windower.ffxi.run(false)
    print('[BRD] 🛑 Stopped following')
end

function brd.update_follow()
    -- Ne pas bouger si pas de cible ou si en cast
    if not brd.follow_target or brd.is_casting then 
        if brd.is_moving then
            windower.ffxi.run(false)
            brd.is_moving = false
        end
        return 
    end
    
    -- Limiter les updates (toutes les 0.2s)
    local now = os.clock()
    if now - brd.last_follow_update < 0.2 then return end
    brd.last_follow_update = now
    
    local player = windower.ffxi.get_player()
    if not player or player.status == 4 then return end
    
    -- Trouver la cible
    local party = windower.ffxi.get_party()
    if not party then return end
    
    local target_id = nil
    for i = 0, 5 do
        local member = party['p'..i]
        if member and member.name == brd.follow_target then
            target_id = member.mob and member.mob.id
            break
        end
    end
    
    if not target_id then return end
    
    local target = windower.ffxi.get_mob_by_id(target_id)
    if not target then return end
    
    local me = windower.ffxi.get_mob_by_target('me')
    if not me then return end
    
    -- Calculer distance
    local dx = target.x - me.x
    local dy = target.y - me.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Si trop loin, se rapprocher
    if distance > brd.follow_distance then
        local angle = math.atan2(dy, dx)
        windower.ffxi.turn(angle)
        windower.ffxi.run(true)
        brd.is_moving = true
    else
        -- Assez proche, arrêter
        if brd.is_moving then
            windower.ffxi.run(false)
            brd.is_moving = false
            brd.last_stop_time = now
            print('[BRD] ✅ Stopped at target distance')
        end
    end
end

----------------------------------------------------------
-- QUEUE
----------------------------------------------------------
function brd.queue_song(song_name, target)
    table.insert(brd.song_queue, {
        song = song_name,
        target = target or '<me>'
    })
    print('[BRD] 📋 Queued: '..song_name)
end

function brd.process_queue()
    if #brd.song_queue == 0 then return end
    
    local player = windower.ffxi.get_player()
    if not player then return end
    
    -- Ne pas caster si déjà en cast
    if player.status == 4 then return end
    
    -- Ne pas caster si en mouvement
    if brd.is_moving then return end
    
    -- Attendre 0.3s après l'arrêt avant de caster
    local now = os.clock()
    if (now - brd.last_stop_time) < 0.3 then return end
    
    -- Vérifier cooldown
    if (now - brd.last_queue_process) < 0.5 then return end
    
    -- Caster
    brd.is_casting = true
    local next_song = table.remove(brd.song_queue, 1)
    windower.send_command('input /ma "'..next_song.song..'" '..next_song.target)
    brd.last_queue_process = now
    print('[BRD] 🎵 Casting: '..next_song.song)
end

----------------------------------------------------------
-- START/STOP
----------------------------------------------------------
function brd.start()
    print('[BRD] 🎵 Starting AutoCast (Smart Follow)...')
    
    if not brd.load_config() then
        return false
    end
    
    brd.active = true
    brd.song_queue = {}
    brd.is_casting = false
    brd.is_moving = false
    
    if brd.config.healerTarget then
        brd.follow(brd.config.healerTarget, 3)
    end
    
    print('[BRD] ✅ AutoCast started')
    return true
end

function brd.stop()
    brd.active = false
    brd.stop_follow()
    brd.song_queue = {}
    brd.is_casting = false
    print('[BRD] 🛑 AutoCast stopped')
end

----------------------------------------------------------
-- UPDATE
----------------------------------------------------------
function brd.update(config, player)
    if not brd.active then return end
    if not player then return end
    
    brd.update_follow()
    brd.process_queue()
end

----------------------------------------------------------
-- EVENTS
----------------------------------------------------------
function brd.init()
    print('[BRD] Module initialized (Smart Follow)')
end

function brd.cleanup()
    brd.stop()
end

function brd.on_action(action, player)
    if not player then return end
    if action.actor_id ~= player.id then return end
    
    -- Fin de cast
    if action.category == 4 or action.category == 8 then
        brd.is_casting = false
        print('[BRD] ✅ Cast finished')
    end
end

return brd
