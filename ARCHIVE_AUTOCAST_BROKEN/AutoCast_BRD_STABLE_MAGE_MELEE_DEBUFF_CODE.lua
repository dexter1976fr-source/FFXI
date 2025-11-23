----------------------------------------------------------
-- AUTO CAST BRD - BACKUP STABLE (Mages + Melee)
-- Version: 1.0.0 - STABLE
-- Date: 2025-11-19
----------------------------------------------------------

require('sets')
require('tables')

local brd = {
    -- État des chansons
    active_songs = {},
    song_timers = {},
    max_songs = 2,
    
    -- Positions
    home_target_name = nil,
    temp_target = nil,
    is_moving = false,
    last_movement_time = 0,
    
    -- File d'attente de cast
    pending_cast = nil,
    
    -- État du cycle automatique
    cycle_phase = "idle",
    cycle_song_index = 1,
    cycle_last_cast = 0,
    cycle_cooldown = 5,
    cycle_phase_start = 0,
    cycle_phase_timeout = 30,
    
    -- Configuration par défaut
    default_config = {
        enabled = true,
        max_songs = 2,
        
        mage_songs = {
            "Mage's Ballad III",
            "Victory March",
        },
        melee_songs = {
            "Valor Minuet V",
            "Sword Madrigal",
        },
        debuff_songs = {
            "Foe Requiem VII",
        },
        
        distances = {
            home = {min = 0.5, max = 2},
            melee = {min = 1, max = 3},
            debuff = {min = 7, max = 8.5},  -- Range flûte = 9
        },
        
        auto_songs = false,
        auto_movement = true,
        use_debuffs = false,  -- Désactivé par défaut
    },
}

----------------------------------------------------------
-- 🔹 CLASSIFICATION DES JOBS
----------------------------------------------------------

local job_roles = {
    melee = S{'WAR', 'MNK', 'THF', 'DRK', 'BST', 'SAM', 'NIN', 'DRG', 'BLU', 'PUP', 'DNC', 'PLD', 'RUN'},
}

----------------------------------------------------------
-- 🔹 UTILITAIRES - DISTANCE ET MOUVEMENT
----------------------------------------------------------

function brd.distance_to(target)
    local player = windower.ffxi.get_mob_by_target('me')
    if not player or not target then return 999 end
    
    local dx = target.x - player.x
    local dy = target.y - player.y
    return math.sqrt(dx*dx + dy*dy)
end

function brd.move_to_target(target, min_dist, max_dist)
    if not target then return end
    
    local player = windower.ffxi.get_mob_by_target('me')
    if not player then return end
    
    local dx = target.x - player.x
    local dy = target.y - player.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist < 0.1 then return end
    
    if dist > max_dist then
        windower.ffxi.run(dx/dist, dy/dist)
        brd.is_moving = true
        brd.last_movement_time = os.clock()
    elseif dist < min_dist then
        windower.ffxi.run(-dx/dist, -dy/dist)
        brd.is_moving = true
        brd.last_movement_time = os.clock()
    else
        if brd.is_moving then
            windower.ffxi.run(false)
            brd.is_moving = false
        end
    end
end

----------------------------------------------------------
-- 🔹 RECHERCHE DE CIBLES
----------------------------------------------------------

function brd.find_melee_target()
    local party = windower.ffxi.get_party()
    if not party then return nil end
    
    local player = windower.ffxi.get_player()
    for i = 0, 5 do
        local member = party['p'..i]
        if member and member.name and member.name ~= player.name then
            local mob = windower.ffxi.get_mob_by_name(member.name)
            if mob then
                return mob
            end
        end
    end
    
    return nil
end

function brd.find_enemy_target()
    local target = windower.ffxi.get_mob_by_target('t')
    if target and target.is_npc and target.spawn_type == 16 and target.hpp > 0 then
        return target
    end
    return nil
end

----------------------------------------------------------
-- 🔹 CAST DE CHANSONS
----------------------------------------------------------

function brd.cast_song(song_name, target)
    target = target or '<me>'
    
    if brd.is_moving then
        brd.pending_cast = {
            song = song_name,
            target = target,
            queued_at = os.clock()
        }
        print('[BRD AutoCast] 📋 Queued: '..song_name)
    else
        windower.send_command('input /ma "'..song_name..'" '..target)
        brd.song_timers[song_name] = os.clock()
        print('[BRD AutoCast] 🎵 Casting '..song_name)
    end
end

----------------------------------------------------------
-- 🔹 INITIALISATION
----------------------------------------------------------

function brd.init()
    print('[BRD AutoCast] 🎵 Initialized')
    brd.song_timers = {}
    brd.active_songs = {}
end

----------------------------------------------------------
-- 🔹 MISE À JOUR PRINCIPALE
----------------------------------------------------------

function brd.update(config, player)
    if not player then return end
    
    local cfg = {}
    for k, v in pairs(brd.default_config) do
        if type(v) == 'table' then
            cfg[k] = {}
            for k2, v2 in pairs(v) do
                cfg[k][k2] = v2
            end
        else
            cfg[k] = v
        end
    end
    
    if config then
        for k, v in pairs(config) do 
            cfg[k] = v 
        end
    end
    
    if cfg.auto_movement then
        brd.update_movement(cfg, player)
    end
    
    if cfg.auto_songs then
        brd.update_songs(cfg, player)
    end
end

----------------------------------------------------------
-- 🔹 GESTION DU MOUVEMENT
----------------------------------------------------------

function brd.update_movement(cfg, player)
    if player.status == 4 then
        return
    end
    
    -- Caster le sort en attente si on vient de s'arrêter
    if not brd.is_moving and brd.pending_cast then
        local cast = brd.pending_cast
        brd.pending_cast = nil
        
        windower.send_command('input /ma "'..cast.song..'" '..cast.target)
        brd.song_timers[cast.song] = os.clock()
        print('[BRD AutoCast] ✅ Casting queued: '..cast.song)
        -- Ne pas return ici! On doit continuer pour update_songs
    end
    
    if not brd.home_target_name then
        local party = windower.ffxi.get_party()
        if party and party['p1'] and party['p1'].name then
            brd.home_target_name = party['p1'].name
            print('[BRD AutoCast] 🏠 Home target: '..brd.home_target_name)
        end
    end
    
    local target = nil
    if brd.temp_target then
        target = brd.temp_target
    elseif brd.home_target_name then
        target = windower.ffxi.get_mob_by_name(brd.home_target_name)
    end
    
    if not target then return end
    
    local distances = cfg.distances.home
    if brd.temp_target then
        -- Vérifier si c'est un ennemi ou un allié
        if target.is_npc and target.spawn_type == 16 then
            distances = cfg.distances.debuff
        else
            distances = cfg.distances.melee
        end
    end
    
    brd.move_to_target(target, distances.min, distances.max)
end

----------------------------------------------------------
-- 🔹 GESTION DES CHANSONS
----------------------------------------------------------

function brd.update_songs(cfg, player)
    local party = windower.ffxi.get_party()
    if not party then return end
    
    local someone_engaged = false
    for i = 0, 5 do
        local member = party['p'..i]
        if member and member.name then
            local mob = windower.ffxi.get_mob_by_name(member.name)
            if mob and mob.status == 1 then
                someone_engaged = true
                break
            end
        end
    end
    
    if not someone_engaged then
        if brd.cycle_phase ~= "idle" then
            print('[BRD AutoCast] 🛑 Combat terminé')
            brd.cycle_phase = "idle"
            brd.temp_target = nil
        end
        return
    end
    
    local time_since_cast = os.clock() - brd.cycle_last_cast
    if time_since_cast < brd.cycle_cooldown then
        return
    end
    
    -- Timeout
    if brd.cycle_phase ~= "idle" then
        local phase_duration = os.clock() - brd.cycle_phase_start
        if phase_duration > brd.cycle_phase_timeout then
            print('[BRD AutoCast] ⏱️ Timeout, retour idle')
            brd.cycle_phase = "idle"
            brd.temp_target = nil
            return
        end
    end
    
    if brd.cycle_phase == "idle" then
        print('[BRD AutoCast] 🎵 Phase MAGES')
        brd.cycle_phase = "mages"
        brd.cycle_song_index = 1
        brd.cycle_phase_start = os.clock()
        
    elseif brd.cycle_phase == "mages" then
        local songs = cfg.mage_songs or {}
        if brd.cycle_song_index <= #songs then
            local song = songs[brd.cycle_song_index]
            
            if not brd.pending_cast then
                brd.cast_song(song, '<me>')
                brd.cycle_song_index = brd.cycle_song_index + 1
                brd.cycle_last_cast = os.clock()
            end
        else
            print('[BRD AutoCast] 🎵 Phase MELEE')
            brd.cycle_phase = "melee"
            brd.cycle_song_index = 1
            brd.cycle_phase_start = os.clock()
            
            local melee = brd.find_melee_target()
            if melee then
                brd.temp_target = melee
                print('[BRD AutoCast] 🎯 Moving to: '..melee.name)
            else
                print('[BRD AutoCast] ⚠️ No melee found')
                brd.cycle_phase = "idle"
                brd.temp_target = nil
            end
        end
        
    elseif brd.cycle_phase == "melee" then
        local songs = cfg.melee_songs or {}
        if brd.cycle_song_index <= #songs then
            local song = songs[brd.cycle_song_index]
            
            if not brd.pending_cast then
                brd.cast_song(song, '<me>')
                brd.cycle_song_index = brd.cycle_song_index + 1
                brd.cycle_last_cast = os.clock()
            end
        else
            -- Vérifier si on doit faire les debuffs
            if cfg.use_debuffs then
                print('[BRD AutoCast] 🎵 Phase DEBUFF')
                brd.cycle_phase = "debuff"
                brd.cycle_song_index = 1
                brd.cycle_phase_start = os.clock()
                
                local enemy = brd.find_enemy_target()
                if enemy then
                    brd.temp_target = enemy
                    print('[BRD AutoCast] 🎯 Moving to enemy: '..enemy.name)
                else
                    print('[BRD AutoCast] ⚠️ No enemy target')
                    brd.cycle_phase = "idle"
                    brd.temp_target = nil
                end
            else
                print('[BRD AutoCast] 🎵 Cycle terminé')
                brd.cycle_phase = "idle"
                brd.temp_target = nil
                brd.cycle_song_index = 1
            end
        end
        
    elseif brd.cycle_phase == "debuff" then
        local songs = cfg.debuff_songs or {}
        if brd.cycle_song_index <= #songs then
            local song = songs[brd.cycle_song_index]
            
            if not brd.pending_cast then
                brd.cast_song(song, '<t>')
                brd.cycle_song_index = brd.cycle_song_index + 1
                brd.cycle_last_cast = os.clock()
            end
        else
            print('[BRD AutoCast] 🎵 Cycle terminé - Retour healer')
            brd.cycle_phase = "idle"
            brd.temp_target = nil
            brd.cycle_song_index = 1
        end
    end
end

----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS
----------------------------------------------------------

function brd.on_action(action, player)
end

----------------------------------------------------------
-- 🔹 CLEANUP
----------------------------------------------------------

function brd.cleanup()
    if brd.is_moving then
        windower.ffxi.run(false)
        brd.is_moving = false
    end
    brd.temp_target = nil
    brd.home_target_name = nil
    print('[BRD AutoCast] 🧹 Cleaned up')
end

----------------------------------------------------------
-- 🔹 COMMANDE MANUELLE
----------------------------------------------------------

function brd.set_follow_target(target_name)
    brd.home_target_name = target_name
    print('[BRD AutoCast] 🎯 Follow: '..target_name)
end

----------------------------------------------------------
-- 🔹 EXPORT
----------------------------------------------------------

return brd
