--------------------------------------------------------------
-- BardCycle - Version corrigée (utilise PartyBuffs correctement)
--------------------------------------------------------------

local BardCycle = {}

-- Charger PartyBuffs de manière protégée
local PartyBuffs = nil
local function load_partybuffs()
    if not PartyBuffs then
        local success, module = pcall(require, 'tools/PartyBuffs')
        if success then
            PartyBuffs = module
            print('[BardCycle] PartyBuffs loaded')
        else
            print('[BardCycle] ERROR loading PartyBuffs: ' .. tostring(module))
        end
    end
    return PartyBuffs ~= nil
end

local json = require('tools/dkjson')

-- Configuration
BardCycle.config = {
    main_character = "Dexterbrown",
    healer_target = "Deedeebrown",
    mage_songs = {},
    melee_songs = {},
    idle_distance = 0.75,
    healer_distance = 0.75,
    melee_distance = 1.75,
    song_cast_time = 5,
    buff_verify_delay = 2,  -- Augmenté à 2s pour laisser le temps au serveur
    cycle_interval = 10,
    max_follow_distance = 5.0,
}

BardCycle.active = false
BardCycle.state = "IDLE"
BardCycle.phase = nil
BardCycle.current_song_index = 1
BardCycle.last_action_time = 0
BardCycle.last_cycle_check = 0
BardCycle.moving = false
BardCycle.current_target = nil

local function log(msg)
    print("[BardCycle] " .. msg)
end

function BardCycle.load_config()
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local config_path = addon_dir .. "data/autocast_config.json"
    local file = io.open(config_path, "r")
    if not file then 
        log('ERROR: Config file not found') 
        return false 
    end
    
    local content = file:read("*all")
    file:close()
    
    local data = json.decode(content)
    if not data or not data.BRD then 
        log('ERROR: Invalid config') 
        return false 
    end
    
    local brd = data.BRD
    BardCycle.config.healer_target = brd.healerTarget or BardCycle.config.healer_target
    BardCycle.config.main_character = brd.meleeTarget or BardCycle.config.main_character
    BardCycle.config.mage_songs = brd.mageSongs or {}
    BardCycle.config.melee_songs = brd.meleeSongs or {}
    
    log('Config loaded')
    log('  Main: ' .. BardCycle.config.main_character)
    log('  Healer: ' .. BardCycle.config.healer_target)
    log('  Mage Songs: ' .. #BardCycle.config.mage_songs)
    log('  Melee Songs: ' .. #BardCycle.config.melee_songs)
    
    return true
end

local function distance_sq(m1, m2)
    if not m1 or not m2 then return 99999 end
    local dx = m1.x - m2.x
    local dy = m1.y - m2.y
    return dx*dx + dy*dy
end

local function is_main_engaged()
    local mob = windower.ffxi.get_mob_by_name(BardCycle.config.main_character)
    return mob and mob.status == 1
end

-- Follow non-bloquant avec distance check
local function follow_target(target_name, distance)
    local me = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(target_name)
    
    if not me or not target then
        if BardCycle.moving then
            windower.ffxi.run(false)
            BardCycle.moving = false
        end
        return 99999
    end
    
    local d2 = distance_sq(me, target)
    local tolerance = 0.3
    
    if d2 > (distance + tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run((target.x - me.x)/len, (target.y - me.y)/len)
        BardCycle.moving = true
    elseif d2 < (distance - tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run(-(target.x - me.x)/len, -(target.y - me.y)/len)
        BardCycle.moving = true
    elseif BardCycle.moving then
        windower.ffxi.run(false)
        BardCycle.moving = false
    end
    
    return d2
end

-- Vérifie si on est assez proche pour caster
local function is_in_cast_range(target_name, max_distance)
    local me = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(target_name)
    if not me or not target then return false end
    
    local d2 = distance_sq(me, target)
    local max_sq = max_distance * max_distance
    return d2 <= max_sq
end

-- Mapping manuel des songs vers les noms de buffs
local SONG_TO_BUFF = {
    ["mage's ballad"] = "ballad",
    ["mage's ballad ii"] = "ballad",
    ["mage's ballad iii"] = "ballad",
    ["army's paeon"] = "paeon",
    ["army's paeon ii"] = "paeon",
    ["army's paeon iii"] = "paeon",
    ["army's paeon iv"] = "paeon",
    ["army's paeon v"] = "paeon",
    ["valor minuet"] = "minuet",
    ["valor minuet ii"] = "minuet",
    ["valor minuet iii"] = "minuet",
    ["valor minuet iv"] = "minuet",
    ["valor minuet v"] = "minuet",
    ["sword madrigal"] = "madrigal",
    ["blade madrigal"] = "madrigal",
    ["advancing march"] = "march",
    ["victory march"] = "march",
    ["sheepfoe mambo"] = "mambo",
    ["dragonfoe mambo"] = "mambo",
    ["fowl aubade"] = "aubade",
    ["herb pastoral"] = "pastoral",
    ["shining fantasia"] = "fantasia",
    ["scop's operetta"] = "operetta",
    ["puppet's operetta"] = "operetta",
    ["battlefield elegy"] = "elegy",
    ["carnage elegy"] = "elegy",
    ["hunter's prelude"] = "prelude",
    ["archer's prelude"] = "prelude",
    ["knight's minne"] = "minne",
    ["knight's minne ii"] = "minne",
    ["knight's minne iii"] = "minne",
    ["knight's minne iv"] = "minne",
    ["maiden's virelai"] = "virelai",
    ["raptor mazurka"] = "mazurka",
    ["chocobo mazurka"] = "mazurka",
}

-- Vérifier si un song est actif en cherchant son nom de buff
local function is_song_active(who, song)
    if not song then return false end
    
    -- Trouver le nom du buff via mapping
    local song_lower = song:lower()
    local buff_name = SONG_TO_BUFF[song_lower]
    
    if not buff_name then
        log('WARNING: Unknown song: ' .. song)
        return false
    end
    
    -- Récupérer les buffs via PartyBuffs
    local buffs = PartyBuffs.get_buffs(who)
    if not buffs or #buffs == 0 then
        log('DEBUG: No buffs for ' .. who)
        return false
    end
    
    -- Chercher le nom du buff (case insensitive)
    for _, buff in ipairs(buffs) do
        if buff:lower():find(buff_name, 1, true) then
            log('✓ "' .. song .. '" active on ' .. who)
            return true
        end
    end
    
    log('✗ "' .. song .. '" missing on ' .. who)
    return false
end

local function all_songs_active(songs, who)
    for _, song in ipairs(songs) do
        if not is_song_active(who, song) then
            return false, song
        end
    end
    return true, nil
end

local function can_cast()
    local p = windower.ffxi.get_player()
    if not p then return false end
    
    -- Statut 4 = casting, 2 = engaged+casting, 3 = dead
    if p.status == 4 or p.status == 2 or p.status == 3 then
        return false
    end
    
    if BardCycle.moving then
        return false
    end
    
    return true
end

local function target_party_member(target_name)
    log('Targeting: ' .. target_name)
    windower.send_command('input /ta ' .. target_name)
    BardCycle.current_target = target_name
end

local function cast_song(song)
    if not can_cast() then
        log('Cannot cast (casting, dead, or moving)')
        return false
    end
    
    log('>>> Casting: ' .. song .. ' on ' .. (BardCycle.current_target or 'unknown'))
    windower.send_command('input /ma "' .. song .. '" <me>')
    return true
end

function BardCycle.update()
    if not BardCycle.active then return end
    
    local now = os.clock()
    local engaged = is_main_engaged()
    
    -- IDLE : Follow main
    if BardCycle.state == "IDLE" then
        follow_target(BardCycle.config.main_character, BardCycle.config.idle_distance)
        if engaged then
            log('=== COMBAT STARTED ===')
            BardCycle.state = "CYCLE_MAGE_CHECK"
            BardCycle.current_song_index = 1
            BardCycle.phase = "READY"
            BardCycle.last_cycle_check = 0
        end
        return
    end
    
    -- Retour IDLE si combat terminé
    if not engaged then
        log('=== COMBAT ENDED ===')
        BardCycle.state = "IDLE"
        BardCycle.phase = nil
        BardCycle.current_song_index = 1
        BardCycle.current_target = nil
        if BardCycle.moving then
            windower.ffxi.run(false)
            BardCycle.moving = false
        end
        return
    end
    
    -- ==========================================
    -- CYCLE MAGE CHECK
    -- ==========================================
    if BardCycle.state == "CYCLE_MAGE_CHECK" then
        follow_target(BardCycle.config.healer_target, BardCycle.config.healer_distance)
        
        if not is_in_cast_range(BardCycle.config.healer_target, BardCycle.config.max_follow_distance) then
            return  -- Continue à follow
        end
        
        if BardCycle.last_cycle_check > 0 and now - BardCycle.last_cycle_check < BardCycle.config.cycle_interval then return end
        
        BardCycle.last_cycle_check = now
        log('--- Checking Mage Songs on ' .. BardCycle.config.healer_target)
        
        -- 🔥 Refresh avant vérification
        PartyBuffs.refresh()
        
        -- Attendre 0.5s que le serveur réponde avant de continuer
        BardCycle.state = "CYCLE_MAGE_CHECK_WAIT"
        BardCycle.last_action_time = now
        return
    end
    
    -- État d'attente après refresh
    if BardCycle.state == "CYCLE_MAGE_CHECK_WAIT" then
        follow_target(BardCycle.config.healer_target, BardCycle.config.healer_distance)
        
        -- Attendre 0.5s que le serveur réponde
        if now - BardCycle.last_action_time < 0.5 then
            return
        end
        
        local buffs = PartyBuffs.get_buffs(BardCycle.config.healer_target)
        if buffs and type(buffs) == "table" then
            log('Healer buffs (' .. #buffs .. '): ' .. table.concat(buffs, ', '))
        else
            log('Healer buffs: ERROR - invalid data')
            buffs = {}
        end
        
        local all_active, missing = all_songs_active(BardCycle.config.mage_songs, BardCycle.config.healer_target)
        
        if all_active then
            log('✓ All mage songs active → switching to melee')
            BardCycle.state = "CYCLE_MELEE_CHECK"
            BardCycle.current_song_index = 1
            BardCycle.phase = "READY"
        else
            log('✗ Missing: ' .. (missing or 'unknown') .. ' → casting mage songs')
            target_party_member(BardCycle.config.healer_target)
            BardCycle.state = "CYCLE_MAGE_CAST"
            BardCycle.current_song_index = 1
            BardCycle.phase = "READY"
            BardCycle.last_action_time = now + 3.5  -- 🔥 Wait 3.5s pour se déplacer avant de caster
        end
        return
    end
    
    -- ==========================================
    -- CYCLE MAGE CAST
    -- ==========================================
    if BardCycle.state == "CYCLE_MAGE_CAST" then
        follow_target(BardCycle.config.healer_target, BardCycle.config.healer_distance)
        
        if not is_in_cast_range(BardCycle.config.healer_target, BardCycle.config.max_follow_distance) then
            return
        end
        
        local song = BardCycle.config.mage_songs[BardCycle.current_song_index]
        
        if not song then
            log('All mage songs cast → verify')
            BardCycle.state = "CYCLE_MAGE_CHECK"
            BardCycle.last_cycle_check = now
            return
        end
        
        if BardCycle.phase == "READY" then
            if now < BardCycle.last_action_time then
                return
            end
            
            -- Vérifier si déjà actif AVANT de caster
            if is_song_active(BardCycle.config.healer_target, song) then
                log('  ✓ ' .. song .. ' already active')
                BardCycle.current_song_index = BardCycle.current_song_index + 1
                return
            end
            
            if cast_song(song) then
                BardCycle.phase = "CASTING"
                BardCycle.last_action_time = now
            end
            return
        end
        
        if BardCycle.phase == "CASTING" then
            if now - BardCycle.last_action_time < BardCycle.config.song_cast_time then return end
            log('  Cast finished, waiting for buff...')
            BardCycle.phase = "WAITING"
            BardCycle.last_action_time = now
            return
        end
        
        if BardCycle.phase == "WAITING" then
            if now - BardCycle.last_action_time < BardCycle.config.buff_verify_delay then return end
            BardCycle.phase = "VERIFY"
            return
        end
        
        if BardCycle.phase == "VERIFY" then
            PartyBuffs.refresh()
            -- Attendre que le serveur réponde
            BardCycle.phase = "VERIFY_WAIT"
            BardCycle.last_action_time = now
            return
        end
        
        if BardCycle.phase == "VERIFY_WAIT" then
            if now - BardCycle.last_action_time < 0.5 then
                return
            end
            
            local song = BardCycle.config.mage_songs[BardCycle.current_song_index]
            if is_song_active(BardCycle.config.healer_target, song) then
                log('  ✓ Confirmed: ' .. song)
                BardCycle.current_song_index = BardCycle.current_song_index + 1
                BardCycle.phase = "READY"
                BardCycle.last_action_time = now + 0.5
            else
                log('  ✗ Not detected, retry: ' .. song)
                BardCycle.phase = "READY"
                BardCycle.last_action_time = now + 1
            end
            return
        end
    end
    
    -- ==========================================
    -- CYCLE MELEE CHECK
    -- ==========================================
    if BardCycle.state == "CYCLE_MELEE_CHECK" then
        follow_target(BardCycle.config.main_character, BardCycle.config.melee_distance)
        
        if not is_in_cast_range(BardCycle.config.main_character, BardCycle.config.max_follow_distance) then
            return
        end
        
        log('--- Checking Melee Songs on ' .. BardCycle.config.main_character)
        PartyBuffs.refresh()
        BardCycle.state = "CYCLE_MELEE_CHECK_WAIT"
        BardCycle.last_action_time = now
        return
    end
    
    if BardCycle.state == "CYCLE_MELEE_CHECK_WAIT" then
        follow_target(BardCycle.config.main_character, BardCycle.config.melee_distance)
        
        if now - BardCycle.last_action_time < 0.5 then
            return
        end
        
        local buffs = PartyBuffs.get_buffs(BardCycle.config.main_character)
        if buffs and type(buffs) == "table" then
            log('Melee buffs (' .. #buffs .. '): ' .. table.concat(buffs, ', '))
        else
            log('Melee buffs: ERROR - invalid data')
            buffs = {}
        end
        
        local all_active, missing = all_songs_active(BardCycle.config.melee_songs, BardCycle.config.main_character)
        
        if all_active then
            log('✓ All melee songs active → back to mage check')
            BardCycle.state = "CYCLE_MAGE_CHECK"
            BardCycle.current_song_index = 1
            BardCycle.phase = "READY"
        else
            log('✗ Missing: ' .. (missing or 'unknown') .. ' → casting melee songs')
            target_party_member(BardCycle.config.main_character)
            BardCycle.state = "CYCLE_MELEE_CAST"
            BardCycle.current_song_index = 1
            BardCycle.phase = "READY"
            BardCycle.last_action_time = now + 3.5  -- 🔥 Wait 3.5s pour se déplacer avant de caster
        end
        return
    end
    
    -- ==========================================
    -- CYCLE MELEE CAST
    -- ==========================================
    if BardCycle.state == "CYCLE_MELEE_CAST" then
        follow_target(BardCycle.config.main_character, BardCycle.config.melee_distance)
        
        if not is_in_cast_range(BardCycle.config.main_character, BardCycle.config.max_follow_distance) then
            return
        end
        
        local song = BardCycle.config.melee_songs[BardCycle.current_song_index]
        
        if not song then
            log('All melee songs cast → back to mage')
            BardCycle.state = "CYCLE_MAGE_CHECK"
            BardCycle.last_cycle_check = now
            return
        end
        
        if BardCycle.phase == "READY" then
            if now < BardCycle.last_action_time then
                return
            end
            
            if is_song_active(BardCycle.config.main_character, song) then
                log('  ✓ ' .. song .. ' already active')
                BardCycle.current_song_index = BardCycle.current_song_index + 1
                return
            end
            
            if cast_song(song) then
                BardCycle.phase = "CASTING"
                BardCycle.last_action_time = now
            end
            return
        end
        
        if BardCycle.phase == "CASTING" then
            if now - BardCycle.last_action_time < BardCycle.config.song_cast_time then return end
            log('  Cast finished, waiting for buff...')
            BardCycle.phase = "WAITING"
            BardCycle.last_action_time = now
            return
        end
        
        if BardCycle.phase == "WAITING" then
            if now - BardCycle.last_action_time < BardCycle.config.buff_verify_delay then return end
            BardCycle.phase = "VERIFY"
            return
        end
        
        if BardCycle.phase == "VERIFY" then
            PartyBuffs.refresh()
            BardCycle.phase = "VERIFY_WAIT"
            BardCycle.last_action_time = now
            return
        end
        
        if BardCycle.phase == "VERIFY_WAIT" then
            if now - BardCycle.last_action_time < 0.5 then
                return
            end
            
            local song = BardCycle.config.melee_songs[BardCycle.current_song_index]
            if is_song_active(BardCycle.config.main_character, song) then
                log('  ✓ Confirmed: ' .. song)
                BardCycle.current_song_index = BardCycle.current_song_index + 1
                BardCycle.phase = "READY"
                BardCycle.last_action_time = now + 0.5
            else
                log('  ✗ Not detected, retry: ' .. song)
                BardCycle.phase = "READY"
                BardCycle.last_action_time = now + 1
            end
            return
        end
    end
end

function BardCycle.start()
    log('========================================')
    log('STARTING BARDCYCLE')
    log('========================================')
    
    -- Charger PartyBuffs
    if not load_partybuffs() then
        log('ERROR: Cannot load PartyBuffs module')
        return false
    end
    
    if not BardCycle.load_config() then return false end
    
    BardCycle.active = true
    BardCycle.state = "IDLE"
    BardCycle.phase = nil
    BardCycle.current_song_index = 1
    BardCycle.last_action_time = 0
    BardCycle.last_cycle_check = 0
    BardCycle.current_target = nil
    
    log('BardCycle started! Following ' .. BardCycle.config.main_character)
    return true
end

function BardCycle.stop()
    log('Stopping BardCycle...')
    BardCycle.active = false
    BardCycle.current_target = nil
    if BardCycle.moving then
        windower.ffxi.run(false)
        BardCycle.moving = false
    end
    log('BardCycle stopped')
end

function BardCycle.init()
    log('BardCycle module loaded')
    return true
end

return BardCycle
