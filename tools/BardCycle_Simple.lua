--------------------------------------------------------------
-- BardCycle SIMPLE - Version test sans PartyBuffs
--------------------------------------------------------------

local BardCycle = {}
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
    cycle_interval = 30,  -- Check toutes les 30s
}

BardCycle.active = false
BardCycle.state = "IDLE"
BardCycle.last_mage_cast = 0
BardCycle.last_melee_cast = 0
BardCycle.moving = false

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

local function follow_target(target_name, distance)
    local me = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(target_name)
    
    if not me or not target then
        if BardCycle.moving then
            windower.ffxi.run(false)
            BardCycle.moving = false
        end
        return
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
end

local function cast_songs(target_name, songs)
    log('Casting ' .. #songs .. ' songs on ' .. target_name)
    windower.send_command('input /ta ' .. target_name)
    coroutine.sleep(1)
    
    for i, song in ipairs(songs) do
        log('  Casting: ' .. song)
        windower.send_command('input /ma "' .. song .. '" <me>')
        coroutine.sleep(BardCycle.config.song_cast_time)
    end
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
            BardCycle.state = "COMBAT"
            BardCycle.last_mage_cast = 0
            BardCycle.last_melee_cast = 0
        end
        return
    end
    
    -- Retour IDLE si combat terminé
    if not engaged then
        log('=== COMBAT ENDED ===')
        BardCycle.state = "IDLE"
        if BardCycle.moving then
            windower.ffxi.run(false)
            BardCycle.moving = false
        end
        return
    end
    
    -- COMBAT : Alterner entre mage et melee
    if BardCycle.state == "COMBAT" then
        -- Cast mage songs toutes les 30s
        if now - BardCycle.last_mage_cast > BardCycle.config.cycle_interval then
            log('Time to cast mage songs')
            follow_target(BardCycle.config.healer_target, BardCycle.config.healer_distance)
            coroutine.sleep(3)  -- Wait pour se déplacer
            cast_songs(BardCycle.config.healer_target, BardCycle.config.mage_songs)
            BardCycle.last_mage_cast = now
        end
        
        -- Cast melee songs toutes les 30s (décalé de 15s)
        if now - BardCycle.last_melee_cast > BardCycle.config.cycle_interval then
            log('Time to cast melee songs')
            follow_target(BardCycle.config.main_character, BardCycle.config.melee_distance)
            coroutine.sleep(3)  -- Wait pour se déplacer
            cast_songs(BardCycle.config.main_character, BardCycle.config.melee_songs)
            BardCycle.last_melee_cast = now
        end
        
        -- Sinon follow main
        follow_target(BardCycle.config.main_character, BardCycle.config.idle_distance)
    end
end

function BardCycle.start()
    log('========================================')
    log('STARTING BARDCYCLE SIMPLE')
    log('========================================')
    
    if not BardCycle.load_config() then return false end
    
    BardCycle.active = true
    BardCycle.state = "IDLE"
    BardCycle.last_mage_cast = 0
    BardCycle.last_melee_cast = 0
    
    log('BardCycle started!')
    return true
end

function BardCycle.stop()
    log('Stopping BardCycle...')
    BardCycle.active = false
    if BardCycle.moving then
        windower.ffxi.run(false)
        BardCycle.moving = false
    end
    log('BardCycle stopped')
end

function BardCycle.init()
    log('BardCycle SIMPLE module loaded')
    return true
end

return BardCycle
