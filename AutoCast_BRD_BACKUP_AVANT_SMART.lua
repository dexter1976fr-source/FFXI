----------------------------------------------------------
-- AUTO CAST BRD - VERSION 2.0 PROPRE
-- Gestion par le serveur Python uniquement
----------------------------------------------------------

local brd = {
    -- Configuration
    config = {
        healerTarget = nil,
        meleeTarget = nil,
        mageSongs = {},
        meleeSongs = {},
    },
    
    -- État
    active = false,
    follow_target = nil,
    song_queue = {},
    last_queue_process = 0,
    queue_cooldown = 4,  -- 4 secondes entre chaque song (temps de cast)
    is_casting = false,  -- Flag pour bloquer le mouvement pendant cast
}

----------------------------------------------------------
-- CHARGEMENT DE LA CONFIG
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
    
    -- Parser le JSON manuellement (simple)
    local healer = content:match('"healerTarget"%s*:%s*"([^"]+)"')
    local melee = content:match('"meleeTarget"%s*:%s*"([^"]+)"')
    
    if healer then brd.config.healerTarget = healer end
    if melee then brd.config.meleeTarget = melee end
    
    -- Parser les songs
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
    
    print('[BRD] ✅ Config loaded')
    print('[BRD] Healer: '..(brd.config.healerTarget or 'none'))
    print('[BRD] Melee: '..(brd.config.meleeTarget or 'none'))
    
    return true
end

----------------------------------------------------------
-- FOLLOW
----------------------------------------------------------
function brd.follow(target_name, distance)
    if not target_name then return end
    
    distance = distance or 1  -- Distance par défaut = 1
    brd.follow_target = target_name
    brd.follow_distance = distance
    
    windower.send_command('input /follow '..target_name)
    print('[BRD] 🎯 Following: '..target_name..' (distance='..distance..')')
end

function brd.stop_follow()
    brd.follow_target = nil
    windower.ffxi.run(false)
    print('[BRD] 🛑 Stopped following')
end

----------------------------------------------------------
-- QUEUE DE SONGS
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
    if not player then 
        print('[BRD] 🐛 DEBUG: No player')
        return 
    end
    
    print('[BRD] 🐛 DEBUG: Queue size='..#brd.song_queue..', status='..player.status)
    
    -- Ne pas caster si en mouvement ou déjà en train de caster
    if player.status == 4 then 
        print('[BRD] 🐛 DEBUG: Already casting')
        return 
    end  -- 4 = casting
    
    -- Ne pas caster si en mouvement (status 5)
    if player.status == 5 then
        print('[BRD] 🐛 DEBUG: Moving, waiting...')
        return
    end
    
    -- Vérifier qu'on est inactif depuis au moins 0.5 seconde
    local now = os.clock()
    if player.status == 0 or player.status == 1 then  -- 0 = idle, 1 = engaged
        local time_since_last = now - brd.last_queue_process
        
        if time_since_last >= 0.5 then
            -- ARRÊTER le follow avant de caster
            windower.send_command('input /follow')
            
            -- Attendre un peu que le mouvement s'arrête
            coroutine.sleep(0.5)
            
            -- Marquer qu'on cast
            brd.is_casting = true
            
            -- Caster le prochain song
            local next_song = table.remove(brd.song_queue, 1)
            windower.send_command('input /ma "'..next_song.song..'" '..next_song.target)
            brd.last_queue_process = now
            print('[BRD] 🎵 Casting: '..next_song.song..' (queue='..#brd.song_queue..')')
        end
    end
end

----------------------------------------------------------
-- DÉMARRAGE
----------------------------------------------------------
function brd.start()
    print('[BRD] 🎵 Starting AutoCast...')
    
    if not brd.load_config() then
        print('[BRD] ❌ Failed to load config')
        return false
    end
    
    brd.active = true
    brd.song_queue = {}
    
    -- Follow le healer par défaut
    if brd.config.healerTarget then
        brd.follow(brd.config.healerTarget)
    end
    
    print('[BRD] ✅ AutoCast started')
    return true
end

function brd.stop()
    brd.active = false
    brd.stop_follow()
    brd.song_queue = {}
    print('[BRD] 🛑 AutoCast stopped')
end

----------------------------------------------------------
-- UPDATE (appelé toutes les 0.1s)
----------------------------------------------------------
function brd.update(config, player)
    if not brd.active then return end
    if not player then return end
    
    -- Traiter la queue de songs
    brd.process_queue()
end

----------------------------------------------------------
-- INIT / CLEANUP
----------------------------------------------------------
function brd.init()
    print('[BRD] Module initialized')
end

function brd.cleanup()
    brd.stop()
end

function brd.on_action(action, player)
    if not player then return end
    if action.actor_id ~= player.id then return end
    
    -- Détecter la fin du cast
    if action.category == 4 or action.category == 8 then  -- 4 = spell finish, 8 = spell interrupt
        brd.is_casting = false
        print('[BRD] ✅ Cast finished, can move again')
    end
end

return brd
