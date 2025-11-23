----------------------------------------------------------
-- AUTO CAST BRD - VERSION MINIMALE
-- Cast 2 songs quand on appelle force_cast_mages()
----------------------------------------------------------

local brd = {}

-- Configuration
brd.mage_songs = {
    "Mage's Ballad III",
    "Victory March",
}

brd.melee_songs = {
    "Valor Minuet V",
    "Sword Madrigal",
}

-- État
brd.casting = false
brd.song_index = 0
brd.last_cast = 0
brd.cast_delay = 3  -- 3 secondes entre chaque song

----------------------------------------------------------
-- INIT
----------------------------------------------------------
function brd.init()
    print('[BRD MINIMAL] Initialized')
end

----------------------------------------------------------
-- UPDATE (appelé toutes les 0.1s)
----------------------------------------------------------
function brd.update(config, player)
    if not brd.casting then return end
    
    local now = os.clock()
    if now - brd.last_cast < brd.cast_delay then
        return  -- Attendre le délai
    end
    
    -- Caster le prochain song
    if brd.song_index <= #brd.current_songs then
        local song = brd.current_songs[brd.song_index]
        windower.send_command('input /ma "'..song..'" <me>')
        print('[BRD MINIMAL] Casting: '..song)
        
        brd.song_index = brd.song_index + 1
        brd.last_cast = now
    else
        -- Tous les songs castés
        print('[BRD MINIMAL] Done!')
        brd.casting = false
    end
end

----------------------------------------------------------
-- FORCE CAST MAGES
----------------------------------------------------------
function brd.force_cast_mages()
    print('[BRD MINIMAL] Force cast mages')
    brd.current_songs = brd.mage_songs
    brd.song_index = 1
    brd.casting = true
    brd.last_cast = 0  -- Cast immédiatement
end

----------------------------------------------------------
-- FORCE CAST MELEES
----------------------------------------------------------
function brd.force_cast_melees()
    print('[BRD MINIMAL] Force cast melees')
    brd.current_songs = brd.melee_songs
    brd.song_index = 1
    brd.casting = true
    brd.last_cast = 0  -- Cast immédiatement
end

----------------------------------------------------------
-- CLEANUP
----------------------------------------------------------
function brd.cleanup()
    brd.casting = false
    print('[BRD MINIMAL] Cleaned up')
end

----------------------------------------------------------
-- AUTRES FONCTIONS (vides pour compatibilité)
----------------------------------------------------------
function brd.on_action(action, player) end
function brd.set_follow_target(target_name) end

return brd
