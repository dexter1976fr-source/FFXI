----------------------------------------------------------
-- BARD CYCLE - Module intégré AltControl
-- Version: 1.0.0 (Tool Module)
-- Cycle automatique de songs pour BRD
----------------------------------------------------------

local BardCycle = {}

-- Configuration
BardCycle.config = {
    healer_target = nil,
    melee_target = nil,
    mage_songs = {},
    melee_songs = {},
    cycle_cooldown = 20,  -- Secondes entre chaque cycle complet
    song_cast_time = 4,   -- Temps d'attente entre chaque song
}

-- État
BardCycle.active = false
BardCycle.state = "idle"
BardCycle.song_queue = {}
BardCycle.last_song_cast = 0
BardCycle.cycle_start_time = 0
BardCycle.last_state_change = 0

-- États possibles
local STATES = {
    IDLE = "idle",
    MOVING_TO_HEALER = "moving_to_healer",
    CHECKING_MAGE = "checking_mage",
    CASTING_MAGE = "casting_mage",
    CHECKING_MELEE = "checking_melee",
    MOVING_TO_MELEE = "moving_to_melee",
    CASTING_MELEE = "casting_melee",
    RETURNING = "returning",
    COOLDOWN = "cooldown"
}

-- Buff IDs des songs
local SONG_BUFFS = {
    ["Ballad"] = 195,
    ["March"] = 214,
    ["Minuet"] = 198,
    ["Madrigal"] = 199,
    ["Mambo"] = 200,
    ["Paeon"] = 196,
    ["Minne"] = 197,
    ["Etude"] = 424,  -- Base ID, varie selon l'étude
}

-- Fonctions utilitaires
local function log(message)
    print('[BardCycle] ' .. message)
end

local function change_state(new_state)
    if BardCycle.state ~= new_state then
        log('State: ' .. BardCycle.state .. ' → ' .. new_state)
        BardCycle.state = new_state
        BardCycle.last_state_change = os.clock()
    end
end

-- Charge la config depuis autocast_config.json
function BardCycle.load_config()
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local config_path = addon_dir .. "../data/autocast_config.json"
    
    local file = io.open(config_path, "r")
    if not file then
        log('⚠️ Config file not found')
        return false
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Parser JSON basique
    local healer = content:match('"healerTarget"%s*:%s*"([^"]+)"')
    local melee = content:match('"meleeTarget"%s*:%s*"([^"]+)"')
    
    if healer then BardCycle.config.healer_target = healer end
    if melee then BardCycle.config.melee_target = melee end
    
    -- Parser mage songs
    local mage_songs_str = content:match('"mageSongs"%s*:%s*%[([^%]]+)%]')
    if mage_songs_str then
        BardCycle.config.mage_songs = {}
        for song in mage_songs_str:gmatch('"([^"]+)"') do
            table.insert(BardCycle.config.mage_songs, song)
        end
    end
    
    -- Parser melee songs
    local melee_songs_str = content:match('"meleeSongs"%s*:%s*%[([^%]]+)%]')
    if melee_songs_str then
        BardCycle.config.melee_songs = {}
        for song in melee_songs_str:gmatch('"([^"]+)"') do
            table.insert(BardCycle.config.melee_songs, song)
        end
    end
    
    log('✅ Config loaded')
    log('Healer: ' .. (BardCycle.config.healer_target or 'none'))
    log('Melee: ' .. (BardCycle.config.melee_target or 'none'))
    log('Mage songs: ' .. #BardCycle.config.mage_songs)
    log('Melee songs: ' .. #BardCycle.config.melee_songs)
    
    return true
end

-- Vérifie les buffs d'un target
local function check_buffs(target_name, song_names)
    local target = windower.ffxi.get_mob_by_name(target_name)
    if not target or not target.id then
        return 0
    end
    
    -- Récupérer les buffs du target depuis la party
    local party = windower.ffxi.get_party()
    if not party then return 0 end
    
    local target_buffs = nil
    for i = 0, 5 do
        local member = party['p' .. i]
        if member and member.name == target_name then
            target_buffs = member.buffs
            break
        end
    end
    
    if not target_buffs then return 0 end
    
    -- Compter combien de songs sont actifs
    local buff_count = 0
    for _, song_name in ipairs(song_names) do
        local buff_id = SONG_BUFFS[song_name]
        if buff_id then
            for _, buff in ipairs(target_buffs) do
                if buff == buff_id then
                    buff_count = buff_count + 1
                    break
                end
            end
        end
    end
    
    return buff_count
end

-- Ajoute un song à la queue
local function queue_song(song_name, target)
    table.insert(BardCycle.song_queue, {
        song = song_name,
        target = target or '<me>'
    })
    log('📋 Queued: ' .. song_name .. ' → ' .. (target or '<me>'))
end

-- Traite la queue de songs
local function process_song_queue()
    if #BardCycle.song_queue == 0 then return false end
    
    local player = windower.ffxi.get_player()
    if not player then return false end
    
    -- Ne pas caster si déjà en train de caster
    if player.status == 4 then return false end
    
    -- Attendre le cooldown entre songs
    local now = os.clock()
    if now - BardCycle.last_song_cast < BardCycle.config.song_cast_time then
        return false
    end
    
    -- Caster le prochain song
    local next_song = table.remove(BardCycle.song_queue, 1)
    windower.send_command('input /ma "' .. next_song.song .. '" ' .. next_song.target)
    BardCycle.last_song_cast = now
    log('🎵 Casting: ' .. next_song.song .. ' (queue=' .. #BardCycle.song_queue .. ')')
    
    return true
end

-- Détecte si le main character est engagé
local function is_main_engaged()
    -- Lire party_roles.json pour savoir qui est le main
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local file_path = addon_dir .. "../data_json/party_roles.json"
    
    local file = io.open(file_path, "r")
    if not file then return false end
    
    local content = file:read("*all")
    file:close()
    
    local main_character = content:match('"main_character"%s*:%s*"([^"]+)"')
    if not main_character then return false end
    
    local main = windower.ffxi.get_mob_by_name(main_character)
    if not main then return false end
    
    return main.status == 1  -- 1 = engaged
end

-- Machine à états
local function update_state_machine()
    local now = os.clock()
    
    if BardCycle.state == STATES.IDLE then
        -- Attendre que le main engage
        if is_main_engaged() then
            log('🎯 Main engaged! Starting cycle...')
            change_state(STATES.MOVING_TO_HEALER)
            BardCycle.cycle_start_time = now
        end
        
    elseif BardCycle.state == STATES.MOVING_TO_HEALER then
        -- Se déplacer vers le healer avec DistanceFollow
        if distancefollow then
            distancefollow.start(BardCycle.config.healer_target, false, 10, 18)
        end
        change_state(STATES.CHECKING_MAGE)
        
    elseif BardCycle.state == STATES.CHECKING_MAGE then
        -- Vérifier les buffs mage
        local buff_count = check_buffs(BardCycle.config.healer_target, BardCycle.config.mage_songs)
        log('Mage buffs: ' .. buff_count .. '/' .. #BardCycle.config.mage_songs)
        
        if buff_count < #BardCycle.config.mage_songs then
            -- Manque des buffs, caster
            for _, song in ipairs(BardCycle.config.mage_songs) do
                queue_song(song, BardCycle.config.healer_target)
            end
            change_state(STATES.CASTING_MAGE)
        else
            -- Buffs OK, passer au melee
            change_state(STATES.CHECKING_MELEE)
        end
        
    elseif BardCycle.state == STATES.CASTING_MAGE then
        -- Attendre que la queue soit vide
        if #BardCycle.song_queue == 0 and now - BardCycle.last_song_cast > BardCycle.config.song_cast_time then
            change_state(STATES.CHECKING_MELEE)
        end
        
    elseif BardCycle.state == STATES.CHECKING_MELEE then
        -- Vérifier les buffs melee
        local buff_count = check_buffs(BardCycle.config.melee_target, BardCycle.config.melee_songs)
        log('Melee buffs: ' .. buff_count .. '/' .. #BardCycle.config.melee_songs)
        
        if buff_count < #BardCycle.config.melee_songs then
            -- Manque des buffs, se déplacer vers melee
            change_state(STATES.MOVING_TO_MELEE)
        else
            -- Buffs OK, retourner au healer
            change_state(STATES.RETURNING)
        end
        
    elseif BardCycle.state == STATES.MOVING_TO_MELEE then
        -- Se déplacer vers le melee
        if distancefollow then
            distancefollow.start(BardCycle.config.melee_target, false, 10, 18)
        end
        -- Caster les songs melee
        for _, song in ipairs(BardCycle.config.melee_songs) do
            queue_song(song, BardCycle.config.melee_target)
        end
        change_state(STATES.CASTING_MELEE)
        
    elseif BardCycle.state == STATES.CASTING_MELEE then
        -- Attendre que la queue soit vide
        if #BardCycle.song_queue == 0 and now - BardCycle.last_song_cast > BardCycle.config.song_cast_time then
            change_state(STATES.RETURNING)
        end
        
    elseif BardCycle.state == STATES.RETURNING then
        -- Retourner au healer
        if distancefollow then
            distancefollow.start(BardCycle.config.healer_target, false, 10, 18)
        end
        change_state(STATES.COOLDOWN)
        
    elseif BardCycle.state == STATES.COOLDOWN then
        -- Attendre le cooldown avant de recommencer
        if now - BardCycle.cycle_start_time > BardCycle.config.cycle_cooldown then
            log('⏰ Cooldown finished, restarting cycle')
            change_state(STATES.CHECKING_MAGE)
            BardCycle.cycle_start_time = now
        end
    end
end

-- Update (appelé chaque frame par AltControl)
function BardCycle.update()
    if not BardCycle.active then return end
    
    -- Traiter la queue de songs
    process_song_queue()
    
    -- Mettre à jour la machine à états
    update_state_machine()
end

-- Démarrer le cycle
function BardCycle.start()
    log('🎵 Starting BardCycle...')
    
    if not BardCycle.load_config() then
        log('❌ Failed to load config')
        return false
    end
    
    BardCycle.active = true
    BardCycle.state = STATES.IDLE
    BardCycle.song_queue = {}
    BardCycle.cycle_start_time = 0
    
    log('✅ BardCycle started')
    return true
end

-- Arrêter le cycle
function BardCycle.stop()
    BardCycle.active = false
    BardCycle.song_queue = {}
    
    -- Arrêter DistanceFollow
    if distancefollow then
        distancefollow.stop()
    end
    
    log('🛑 BardCycle stopped')
end

-- Initialize
function BardCycle.init()
    log('Tool initialized')
    return true
end

-- Cleanup
function BardCycle.unload()
    BardCycle.stop()
end

return BardCycle
