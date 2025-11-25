--------------------------------------------------------------
-- SONG SERVICE - Pull-based Bard system (Version optimisée)
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

-- États (simplifiés)
SongService.active = false
SongService.role = nil
SongService.state = "IDLE"
SongService.requests_by_target = {}  -- Regroupement par target
SongService.song_queue = {}          -- Queue globale des songs
SongService.current_target = nil     -- Target actuelle en cours
SongService.cast_phase = nil         -- "MOVING_TO_TARGET" ou "CASTING"
SongService.last_cast_time = 0       -- Pour timing des casts
SongService.last_check = 0
SongService.moving = false

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

-- 🆕 Chargement des rôles depuis party_roles.json
function SongService.load_party_roles()
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local roles_path = addon_dir .. "../data_json/party_roles.json"
    local file = io.open(roles_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content)
        if data then
            SongService.config.mainCharacter = data.main_character or ""
            SongService.config.healerCharacter = data.alt1 or ""  -- alt1 = healer
            SongService.config.bardName = data.alt2 or ""          -- alt2 = bard
            log("Party roles loaded: Main=" .. SongService.config.mainCharacter .. ", Healer=" .. SongService.config.healerCharacter .. ", Bard=" .. SongService.config.bardName)
            return true
        end
    end
    log("ERROR: Could not load party roles from " .. roles_path)
    return false
end

-- 🆕 Chargement des configs de songs depuis alt_configs.json
function SongService.load_song_configs()
    local addon_dir = windower.addon_path:match("^(.+[/\\])")
    local configs_path = addon_dir .. "../data_json/alt_configs.json"
    local file = io.open(configs_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = json.decode(content)
        if data then
            SongService.config.clients = {}
            -- Pour chaque config d'alt
            for config_key, config in pairs(data) do
                local alt_name = config.alt_name
                -- Config automatique basée sur les rôles
                if alt_name == SongService.config.healerCharacter then
                    -- Healer reçoit les mage songs (Ballad + Paeon)
                    SongService.config.clients[alt_name] = {
                        "Mage's Ballad II",
                        "Army's Paeon IV"
                    }
                    log("Configured healer " .. alt_name .. " with mage songs")
                elseif alt_name == SongService.config.mainCharacter then
                    -- Main reçoit les melee songs (Minuet + Madrigal)
                    SongService.config.clients[alt_name] = {
                        "Valor Minuet IV",
                        "Sword Madrigal"
                    }
                    log("Configured main " .. alt_name .. " with melee songs")
                end
            end
            
            local count = 0
            for _ in pairs(SongService.config.clients) do count = count + 1 end
            log("Song configs loaded for " .. count .. " clients")
            return true
        end
    end
    log("ERROR: Could not load song configs from " .. configs_path)
    return false
end

-- 🆕 Nouvelle fonction init() universelle
function SongService.load_config()
    log("🎵 Universal SongService initializing...")
    
    -- Paramètres par défaut
    SongService.config.followDistance = 0.75
    SongService.config.checkInterval = 30
    
    -- Charger les rôles automatiquement
    if not SongService.load_party_roles() then
        log("ERROR: Failed to load party roles")
        return false
    end
    
    -- Détecter le rôle automatiquement  
    SongService.role = SongService.detect_role()
    
    -- Si c'est un BRD, charger les configs de songs
    if SongService.role == "BARD" then
        if not SongService.load_song_configs() then
            log("ERROR: Failed to load song configs")
            return false
        end
    end
    
    log("✅ SongService initialized as " .. tostring(SongService.role))
    return true
end

function SongService.detect_role()
    local player = windower.ffxi.get_player()
    if not player then return nil end
    
    -- Détecter automatiquement le Bard par son job
    if player.main_job == 'BRD' then
        log("AUTO-DETECTED as BARD (job: BRD)")
        -- Mettre à jour le nom du bard dans la config
        SongService.config.bardName = player.name
        return "BARD"
    elseif SongService.config.clients[player.name] then
        log("AUTO-DETECTED as CLIENT")
        return "CLIENT"
    end
    
    return nil
end

-- Distance squared
local function distance_sq(m1, m2)
    if not m1 or not m2 then return 99999 end
    local dx = m1.x - m2.x
    local dy = m1.y - m2.y
    return dx*dx + dy*dy
end

-- Follow target, retourne true si arrivé
local function follow_target(target_name, distance)
    local me = windower.ffxi.get_mob_by_target("me")
    local target = windower.ffxi.get_mob_by_name(target_name)
    
    -- 🔥 NE PAS BOUGER SI EN TRAIN DE CASTER
    local player = windower.ffxi.get_player()
    if player and player.status == 4 then
        if SongService.moving then
            windower.ffxi.run(false)
            SongService.moving = false
        end
        return false  -- Pas arrivé, on attend la fin du cast
    end
    
    if not me or not target then
        if SongService.moving then
            windower.ffxi.run(false)
            SongService.moving = false
        end
        return false
    end
    
    local d2 = distance_sq(me, target)
    local tolerance = 0.3
    
    if d2 > (distance + tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run((target.x - me.x)/len, (target.y - me.y)/len)
        SongService.moving = true
        return false
    elseif d2 < (distance - tolerance)^2 then
        local len = math.sqrt(d2)
        windower.ffxi.run(-(target.x - me.x)/len, -(target.y - me.y)/len)
        SongService.moving = true
        return false
    else
        if SongService.moving then
            windower.ffxi.run(false)
            SongService.moving = false
        end
        return true
    end
end

-- Vérifie si un buff est actif (local check)
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

-- Check si le main est engaged
local function is_engaged()
    local main = windower.ffxi.get_mob_by_name(SongService.config.mainCharacter)
    return main and main.status == 1
end

--------------------------------------------------------------
-- CLIENT LOGIC
--------------------------------------------------------------

local function client_request_songs()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local my_songs = SongService.config.clients[player.name]
    if not my_songs or #my_songs == 0 then return end
    
    -- Vérifier si AU MOINS UN buff manque
    local missing_any = false
    local missing_list = {}
    
    for _, song in ipairs(my_songs) do
        local buff_name = SONG_TO_BUFF[song:lower()]
        if buff_name and not has_buff(buff_name) then
            missing_any = true
            table.insert(missing_list, song)
        end
    end
    
    -- Si au moins un buff manque, demander TOUS les songs
    if missing_any then
        log("Missing buffs: " .. table.concat(missing_list, ", ") .. " → requesting ALL songs")
        windower.send_command('input //send ' .. SongService.config.bardName .. ' ac songrequest ' .. player.name)
    end
end

function SongService.client_update()
    if not is_engaged() then return end
    
    local now = os.clock()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    -- Décalage initial selon le rôle
    local initial_delay = 0
    if player.name == SongService.config.healerCharacter then
        initial_delay = 5  -- Healer check à 5s
    elseif player.name == SongService.config.mainCharacter then
        initial_delay = 20  -- Melee check à 20s
    end
    
    -- Premier check après le délai initial
    if SongService.last_check == 0 then
        if now < initial_delay then
            return
        end
    else
        -- Checks suivants toutes les 30s
        if now - SongService.last_check < SongService.config.checkInterval then
            return
        end
    end
    
    SongService.last_check = now
    client_request_songs()
end

--------------------------------------------------------------
-- BARD LOGIC (OPTIMISÉE)
--------------------------------------------------------------

function SongService.add_request(requester)
    -- Marquer que ce requester a besoin de service
    SongService.requests_by_target[requester] = true
    
    -- Ajouter tous ses songs à la queue si pas déjà fait
    if not SongService.requests_by_target[requester .. "_queued"] then
        local songs = SongService.config.clients[requester]
        if songs then
            for _, song in ipairs(songs) do
                table.insert(SongService.song_queue, {
                    song = song,
                    target = requester
                })
            end
            SongService.requests_by_target[requester .. "_queued"] = true
            log("Queued " .. #songs .. " songs for " .. requester)
        end
    end
end

-- Fonction helper
local function get_remaining_for_target(target_name)
    local count = 0
    for _, song_data in ipairs(SongService.song_queue) do
        if song_data.target == target_name then count = count + 1 end
    end
    return count
end

function SongService.bard_update()
    local engaged = is_engaged()
    local now = os.clock()
    
    -- IDLE : hors combat
    if not engaged then
        SongService.requests_by_target = {}
        SongService.song_queue = {}
        SongService.current_target = nil
        SongService.cast_phase = nil
        SongService.state = "IDLE"
        follow_target(SongService.config.mainCharacter, SongService.config.followDistance)
        return
    end
    
    -- Si on a des songs à caster, les traiter
    if #SongService.song_queue > 0 then
        -- Prendre le prochain target si pas de target actuelle
        if not SongService.current_target then
            -- 🆕 PRIORITÉ : Traiter le healer en premier
            local healer_name = SongService.config.healerCharacter
            
            -- Vérifier si le healer a des requêtes en attente
            if healer_name and SongService.requests_by_target[healer_name] and not healer_name:find("_queued") then
                SongService.current_target = healer_name
                SongService.cast_phase = "MOVING_TO_TARGET"
                log("PRIORITY: Moving to healer " .. healer_name .. " first")
            else
                -- Sinon, prendre n'importe quel autre target
                for target, _ in pairs(SongService.requests_by_target) do
                    if target ~= SongService.config.bardName and not target:find("_queued") then
                        SongService.current_target = target
                        SongService.cast_phase = "MOVING_TO_TARGET"
                        log("Moving to " .. target .. " to cast songs")
                        break
                    end
                end
            end
            if not SongService.current_target then return end
        end
        
        local target = SongService.current_target
        
        -- Phase MOVING_TO_TARGET
        if SongService.cast_phase == "MOVING_TO_TARGET" then
            if follow_target(target, SongService.config.followDistance) then
                log("Arrived at " .. target .. ", starting cast sequence")
                SongService.cast_phase = "CASTING"
                SongService.last_cast_time = now - 3  -- Commencer immédiatement
            end
            return
        end
        
        -- Phase CASTING : Caster tous les songs pour ce target
        if SongService.cast_phase == "CASTING" then
            -- Vérifier qu'on a encore des songs pour ce target
            local has_songs_for_target = false
            for _, song_data in ipairs(SongService.song_queue) do
                if song_data.target == target then
                    has_songs_for_target = true
                    break
                end
            end
            
            if not has_songs_for_target then
                -- Plus de songs pour ce target, passer au suivant
                log("Finished casting for " .. target)
                SongService.requests_by_target[target] = nil
                SongService.current_target = nil
                SongService.cast_phase = nil
                return
            end
            
            -- Attendre entre les casts (3s)
            if now - SongService.last_cast_time < 3 then return end
            
            local player = windower.ffxi.get_player()
            if player and player.status == 4 then return end  -- Déjà en train de caster
            
            -- Caster le prochain song pour ce target
            for i, song_data in ipairs(SongService.song_queue) do
                if song_data.target == target then
                    table.remove(SongService.song_queue, i)
                    windower.send_command('input /ma "' .. song_data.song .. '" <me>')
                    SongService.last_cast_time = now
                    log("Casting: " .. song_data.song .. " for " .. target .. " (remaining: " .. get_remaining_for_target(target) .. ")")
                    return
                end
            end
        end
    else
        -- Rien à caster, suivre healer
        if SongService.state ~= "STANDBY" then
            log("No songs to cast → STANDBY")
            SongService.state = "STANDBY"
        end
        follow_target(SongService.config.healerCharacter, SongService.config.followDistance)
    end
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
    log("========================================")
    log("STARTING SONG SERVICE")
    log("========================================")
    
    if not SongService.load_config() then
        log("ERROR: Cannot load config")
        return false
    end
    
    SongService.role = SongService.detect_role()
    if not SongService.role then
        log("ERROR: Not configured as Bard or Client")
        return false
    end
    
    SongService.active = true
    SongService.state = "IDLE"
    SongService.requests_by_target = {}
    SongService.song_queue = {}
    SongService.current_target = nil
    SongService.cast_phase = nil
    SongService.last_check = 0
    SongService.last_cast_time = 0
    
    log("Role: " .. SongService.role)
    
    -- 🔥 IMPORTANT : Désactiver DistanceFollow pour éviter les conflits
    if SongService.role == "BARD" then
        log("Disabling DistanceFollow (SongService handles movement)")
        windower.send_command('input //ac dfollow stop')
    else
        -- Clients : activer le follow sur le main
        log("Starting follow on: " .. SongService.config.mainCharacter)
        windower.send_command('input //ac follow ' .. SongService.config.mainCharacter)
    end
    
    log("SongService started!")
    return true
end

function SongService.stop()
    log("Stopping SongService...")
    SongService.active = false
    SongService.requests_by_target = {}
    SongService.song_queue = {}
    SongService.current_target = nil
    SongService.cast_phase = nil
    if SongService.moving then
        windower.ffxi.run(false)
        SongService.moving = false
    end
    log("SongService stopped")
end

function SongService.status()
    log("========================================")
    log("SONG SERVICE STATUS")
    log("========================================")
    log("Active: " .. tostring(SongService.active))
    log("Role: " .. tostring(SongService.role))
    if SongService.role == "BARD" then
        log("State: " .. SongService.state)
        log("Song queue: " .. #SongService.song_queue .. " songs")
        log("Current target: " .. tostring(SongService.current_target))
        log("Cast phase: " .. tostring(SongService.cast_phase))
        
        -- Afficher la queue par target
        local targets = {}
        for _, song_data in ipairs(SongService.song_queue) do
            if not targets[song_data.target] then
                targets[song_data.target] = 0
            end
            targets[song_data.target] = targets[song_data.target] + 1
        end
        for target, count in pairs(targets) do
            log("  " .. target .. ": " .. count .. " songs")
        end
    end
    log("========================================")
end

function SongService.init()
    log("SongService module loaded")
    return true
end

return SongService
