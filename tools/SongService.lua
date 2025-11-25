--------------------------------------------------------------
-- SONG SERVICE - Pull-based Bard system
-- Clients request songs, Bard serves them
--------------------------------------------------------------

local SongService = {}
local json = require('tools/dkjson')

-- Configuration
SongService.config = {
    mainCharacter = "",
    healerCharacter = "",
    bardName = "",
    clients = {},
    followDistance = 0.75,
    checkInterval = 30,
}

-- État
SongService.active = false
SongService.role = nil  -- "BARD" ou "CLIENT"
SongService.state = "IDLE"  -- IDLE, STANDBY, SERVING
SongService.queue = {}  -- Queue de requêtes pour le Bard
SongService.last_check = 0  -- Dernier check de buffs (clients)
SongService.moving = false
SongService.current_request = nil

-- Mapping songs → buff names
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
}

local function log(msg)
    print("[SongService] " .. msg)
end

-- Charger la config
function SongService.load_config()
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local config_path = addon_dir .. "data/autocast_config.json"
    local file = io.open(config_path, "r")
    if not file then 
        log('Config file not found')
        return false 
    end
    
    local content = file:read("*all")
    file:close()
    
    local data = json.decode(content)
    if not data or not data.SongService then 
        log('SongService config not found')
        return false 
    end
    
    local cfg = data.SongService
    SongService.config.mainCharacter = cfg.mainCharacter or ""
    SongService.config.healerCharacter = cfg.healerCharacter or ""
    SongService.config.bardName = cfg.bardName or ""
    SongService.config.clients = cfg.clients or {}
    SongService.config.followDistance = cfg.followDistance or 0.75
    
    return true
end

-- Déterminer le rôle
function SongService.detect_role()
    local player = windower.ffxi.get_player()
    if not player then return nil end
    
    if player.name == SongService.config.bardName then
        return "BARD"
    elseif SongService.config.clients[player.name] then
        return "CLIENT"
    end
    
    return nil
end

-- Vérifier si le main est engaged
local function is_main_engaged()
    local main = windower.ffxi.get_mob_by_name(SongService.config.mainCharacter)
    return main and main.status == 1
end

-- Distance au carré
local function distance_sq(m1, m2)
    if not m1 or not m2 then return 99999 end
    local dx = m1.x - m2.x
    local dy = m1.y - m2.y
    return dx*dx + dy*dy
end

-- Follow un target
local function follow_target(target_name, distance)
    local me = windower.ffxi.get_mob_by_target('me')
    local target = windower.ffxi.get_mob_by_name(target_name)
    
    if not me or not target then
        if SongService.moving then
            windower.ffxi.run(false)
            SongService.moving = false
        end
        return
    end
    
    local d2 = distance_sq(me, target)
    local tolerance = 0.3
    
    if d2 > (distance + tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run((target.x - me.x)/len, (target.y - me.y)/len)
        SongService.moving = true
    elseif d2 < (distance - tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run(-(target.x - me.x)/len, -(target.y - me.y)/len)
        SongService.moving = true
    elseif SongService.moving then
        windower.ffxi.run(false)
        SongService.moving = false
    end
end

--------------------------------------------------------------
-- CLIENT LOGIC
--------------------------------------------------------------

-- Vérifier si un buff est actif
local function has_buff(buff_name)
    local player = windower.ffxi.get_player()
    if not player or not player.buffs then return false end
    
    local res = require('resources')
    buff_name = buff_name:lower()
    
    for _, buff_id in ipairs(player.buffs) do
        local buff = res.buffs[buff_id]
        if buff and buff.en:lower():find(buff_name, 1, true) then
            return true
        end
    end
    
    return false
end

-- Check si les songs sont actifs
local function check_my_songs()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local my_songs = SongService.config.clients[player.name]
    if not my_songs or #my_songs == 0 then return end
    
    -- Vérifier chaque song
    for _, song in ipairs(my_songs) do
        local buff_name = SONG_TO_BUFF[song:lower()]
        if buff_name and not has_buff(buff_name) then
            log('Missing: ' .. song .. ' → requesting')
            -- Envoyer requête au Bard
            windower.send_command('input /tell ' .. SongService.config.bardName .. ' //ac songrequest ' .. player.name)
            return  -- Une seule requête à la fois
        end
    end
end

function SongService.client_update()
    if not is_main_engaged() then return end
    
    local now = os.clock()
    if now - SongService.last_check < SongService.config.checkInterval then
        return
    end
    
    SongService.last_check = now
    check_my_songs()
end

--------------------------------------------------------------
-- BARD LOGIC
--------------------------------------------------------------

-- Ajouter une requête à la queue
function SongService.add_request(requester)
    -- Vérifier si déjà dans la queue
    for _, req in ipairs(SongService.queue) do
        if req.requester == requester then
            log('Request from ' .. requester .. ' already in queue')
            return
        end
    end
    
    table.insert(SongService.queue, {
        requester = requester,
        timestamp = os.clock()
    })
    
    log('Added request from ' .. requester .. ' (queue: ' .. #SongService.queue .. ')')
end

-- Cast songs sur un client
local function cast_songs_on_client(client_name)
    local songs = SongService.config.clients[client_name]
    if not songs or #songs == 0 then
        log('No songs configured for ' .. client_name)
        return
    end
    
    log('Casting ' .. #songs .. ' songs on ' .. client_name)
    windower.send_command('input /ta ' .. client_name)
    coroutine.sleep(1)
    
    for _, song in ipairs(songs) do
        log('  → ' .. song)
        windower.send_command('input /ma "' .. song .. '" <me>')
        coroutine.sleep(5)  -- Temps de cast
    end
    
    log('Finished casting on ' .. client_name)
end

function SongService.bard_update()
    local engaged = is_main_engaged()
    
    -- IDLE : hors combat, follow main
    if not engaged then
        if SongService.state ~= "IDLE" then
            log('Combat ended → IDLE')
            SongService.state = "IDLE"
            SongService.queue = {}  -- Vider la queue
        end
        follow_target(SongService.config.mainCharacter, SongService.config.followDistance)
        return
    end
    
    -- STANDBY : en combat, queue vide, follow healer
    if #SongService.queue == 0 then
        if SongService.state ~= "STANDBY" then
            log('Queue empty → STANDBY (following healer)')
            SongService.state = "STANDBY"
        end
        follow_target(SongService.config.healerCharacter, SongService.config.followDistance)
        return
    end
    
    -- SERVING : traiter la queue
    if SongService.state ~= "SERVING" then
        log('Processing queue → SERVING')
        SongService.state = "SERVING"
    end
    
    -- Prendre la première requête
    local request = table.remove(SongService.queue, 1)
    if not request then return end
    
    log('Serving: ' .. request.requester)
    
    -- Aller vers le client
    follow_target(request.requester, SongService.config.followDistance)
    coroutine.sleep(3)  -- Wait pour arriver
    
    -- Cast songs
    cast_songs_on_client(request.requester)
    
    -- Retourner vers healer
    log('Returning to healer')
    follow_target(SongService.config.healerCharacter, SongService.config.followDistance)
    coroutine.sleep(2)
end

--------------------------------------------------------------
-- UPDATE PRINCIPAL
--------------------------------------------------------------

function SongService.update()
    if not SongService.active then return end
    
    if SongService.role == "CLIENT" then
        SongService.client_update()
    elseif SongService.role == "BARD" then
        SongService.bard_update()
    end
end

--------------------------------------------------------------
-- COMMANDES
--------------------------------------------------------------

function SongService.start()
    log('========================================')
    log('STARTING SONG SERVICE')
    log('========================================')
    
    if not SongService.load_config() then
        log('ERROR: Cannot load config')
        return false
    end
    
    SongService.role = SongService.detect_role()
    if not SongService.role then
        log('ERROR: Not configured as Bard or Client')
        return false
    end
    
    SongService.active = true
    SongService.state = "IDLE"
    SongService.queue = {}
    SongService.last_check = 0
    
    log('Role: ' .. SongService.role)
    log('SongService started!')
    return true
end

function SongService.stop()
    log('Stopping SongService...')
    SongService.active = false
    SongService.queue = {}
    if SongService.moving then
        windower.ffxi.run(false)
        SongService.moving = false
    end
    log('SongService stopped')
end

function SongService.status()
    log('========================================')
    log('SONG SERVICE STATUS')
    log('========================================')
    log('Active: ' .. tostring(SongService.active))
    log('Role: ' .. tostring(SongService.role))
    if SongService.role == "BARD" then
        log('State: ' .. SongService.state)
        log('Queue: ' .. #SongService.queue .. ' requests')
        for i, req in ipairs(SongService.queue) do
            log('  [' .. i .. '] ' .. req.requester)
        end
    end
    log('========================================')
end

function SongService.init()
    log('SongService module loaded')
    return true
end

return SongService
