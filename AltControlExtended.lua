----------------------------------------------------------
-- ALT CONTROL EXTENDED - Module avec toutes les fonctionnalités
-- Chargé dynamiquement par AltControl (Core)
----------------------------------------------------------

local Extended = {}

-- Socket et configuration (hérités du Core)
local socket = require('socket')
local host = "127.0.0.1"
local base_port = 5007

----------------------------------------------------------
-- 🔹 TOOLS MODULES (chargés à la demande)
----------------------------------------------------------

local autoengage = nil
local distancefollow = nil
local altpetoverlay = nil
local partybuffs = nil  -- Module de récupération des buffs de party
local songservice = nil  -- Module SongService (pull-based bard system)

-- Charger PartyBuffs automatiquement au démarrage (module de base)
local function init_partybuffs()
    if not partybuffs then
        local success, module = pcall(require, 'tools/PartyBuffs')
        if success then
            partybuffs = module
            -- IMPORTANT: Appeler init() pour enregistrer l'événement
            partybuffs.init()
            print('[AltControl] ✅ PartyBuffs module loaded and initialized')
            return true
        else
            print('[AltControl] ⚠️ PartyBuffs module not loaded:', module)
            return false
        end
    end
    return true
end

-- Charger PartyBuffs immédiatement
init_partybuffs()

function load_tool(tool_name)
    local success, module = pcall(require, 'tools/' .. tool_name)
    if success then
        print('[AltControl] ✅ Tool loaded: ' .. tool_name)
        return module
    else
        print('[AltControl] ❌ Failed to load tool ' .. tool_name .. ':', module)
        return nil
    end
end

----------------------------------------------------------
-- 🔹 COMMANDES ADDON
----------------------------------------------------------

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or nil
    
    if command == 'status' then
        -- Afficher le status
        if autoengage and autoengage.is_active() then
            print('[AltControl] AutoEngage is ACTIVE')
        else
            print('[AltControl] AutoEngage is INACTIVE')
        end
        
    elseif command == 'autoengage' then
        -- Commandes AutoEngage: //ac autoengage start/stop <target>
        if not autoengage then
            print('[AltControl] Loading AutoEngage tool...')
            autoengage = load_tool('AutoEngage')
            if autoengage then
                print('[AltControl] ✅ AutoEngage tool loaded successfully')
                
                -- 🆕 Connecter AutoEngage avec DistanceFollow
                autoengage.on_state_change = function(is_active)
                    if distancefollow and distancefollow.enabled then
                        distancefollow.auto_engage_active = is_active
                        print('[DistanceFollow] AutoEngage: ' .. (is_active and 'ON' or 'OFF'))
                        if is_active then
                            print('[DistanceFollow] Will stay close (0.5-1) even in combat')
                        else
                            print('[DistanceFollow] Will retreat (10-18) if target engages')
                        end
                    end
                end
            else
                print('[AltControl] ❌ Failed to load AutoEngage tool')
                return
            end
        end
        if autoengage then
            local args = {...}
            autoengage.handle_command(table.unpack(args))
        end
        
    elseif command == 'checkbuffs' then
        -- Commande de test: //ac checkbuffs [nom]
        if not partybuffs then
            print('[AltControl] ❌ PartyBuffs module not loaded')
            return
        end
        
        -- Forcer la mise à jour du cache
        partybuffs.refresh()
        
        local target_name = select(1, ...)
        
        if target_name then
            -- Afficher les buffs d'un joueur spécifique
            local buffs = partybuffs.get_buffs(target_name)
            print('[PartyBuffs] ========================================')
            print('[PartyBuffs] Buffs for: ' .. target_name)
            print('[PartyBuffs] Total: ' .. #buffs .. ' buffs')
            if #buffs > 0 then
                for i, buff in ipairs(buffs) do
                    print('[PartyBuffs]   ' .. i .. '. ' .. buff)
                end
            else
                print('[PartyBuffs]   (no buffs or player not found)')
            end
            print('[PartyBuffs] ========================================')
        else
            -- Afficher les buffs de tous les alts connectés
            local players = partybuffs.get_all_players()
            
            if #players == 0 then
                print('[PartyBuffs] ❌ No alts connected to server')
                return
            end
            
            print('[PartyBuffs] ========================================')
            print('[PartyBuffs] ALL ALTS BUFFS (' .. #players .. ' connected)')
            print('[PartyBuffs] ========================================')
            
            for _, player_name in ipairs(players) do
                local buffs = partybuffs.get_buffs(player_name)
                print('[PartyBuffs] ' .. player_name .. ' (' .. #buffs .. ' buffs):')
                if #buffs > 0 then
                    for _, buff in ipairs(buffs) do
                        print('[PartyBuffs]   - ' .. buff)
                    end
                else
                    print('[PartyBuffs]   (no buffs)')
                end
                print('[PartyBuffs] ---')
            end
            print('[PartyBuffs] ========================================')
        end
        
    elseif command == 'songservice' then
        -- Commandes SongService: //ac songservice start/stop/status
        local action = select(1, ...) and select(1, ...):lower()
        
        if not songservice then
            print('[AltControl] Loading SongService tool...')
            songservice = load_tool('SongService')
            if songservice then
                songservice.init()
                print('[AltControl] ✅ SongService tool loaded')
            else
                print('[AltControl] ❌ Failed to load SongService tool')
                return
            end
        end
        
        if action == 'start' then
            songservice.start()
        elseif action == 'stop' then
            songservice.stop()
        elseif action == 'status' then
            songservice.status()
        else
            print('[AltControl] Usage: //ac songservice start|stop|status')
        end
    
    elseif command == 'songrequest' then
        -- Requête de song (reçue par le Bard)
        local requester = select(1, ...)
        if songservice and requester then
            songservice.add_request(requester)
        end
        
    elseif command == 'dfollow' then
        -- Commandes DistanceFollow: //ac dfollow [target] [mode]
        if not distancefollow then
            print('[AltControl] Loading DistanceFollow tool...')
            distancefollow = load_tool('DistanceFollow')
            if distancefollow then
                print('[AltControl] ✅ DistanceFollow tool loaded successfully')
            else
                print('[AltControl] ❌ Failed to load DistanceFollow tool')
                return
            end
        end
        if distancefollow then
            local args = {...}
            distancefollow.handleCommand(table.unpack(args))
        end
        
    elseif command == 'follow' then
        -- Follow quelqu'un: //ac follow [nom] [distance]
        local args = {...}
        if #args > 0 then
            local distance = tonumber(args[#args])  -- Dernier arg = distance?
            local target_name
            
            if distance then
                -- Si le dernier arg est un nombre, c'est la distance
                table.remove(args, #args)
                target_name = table.concat(args, ' ')
            else
                -- Sinon, distance par défaut = 1
                distance = 1
                target_name = table.concat(args, ' ')
            end
            
            print('[AltControl] Following: '..target_name..' (distance='..distance..')')
        else
            print('[AltControl] Usage: //ac follow [name] [distance]')
        end
    
    elseif command == 'stopfollow' then
        -- Arrêter le follow
        print('[AltControl] 🛑 Stopping follow...')
        
        -- Arrêter tout mouvement immédiatement
        windower.ffxi.run(false)
        print('[AltControl] ✅ Movement stopped')
    
    elseif command == 'cast' then
        -- Caster un spell/song: //ac cast [spell_name] [target]
        local args = {...}
        if #args >= 1 then
            local spell = args[1]
            local target = args[2] or '<me>'
            print('[AltControl] 🎵 Casting: '..spell..' on '..target)
            windower.send_command('input /ma "'..spell..'" '..target)
        end
    
    elseif command == 'debug_pet' then
        -- Toggle pet debug
        pet_debug = not pet_debug
        print('[AltControl] Pet debug: ' .. (pet_debug and 'ON' or 'OFF'))
        if pet_debug then
            -- Force immediate broadcast with detailed info
            local player = windower.ffxi.get_player()
            if player then
                print('[AltControl] Player found: ' .. player.name)
                local pet = windower.ffxi.get_mob_by_target("pet")
                if pet then
                    print('[AltControl] Pet found: ' .. (pet.name or 'Unknown'))
                    print('[AltControl] Pet HP: ' .. (pet.hp or 0) .. ' / ' .. (pet.hpp or 0) .. '%')
                    broadcast_pet_to_overlay()
                else
                    print('[AltControl] ❌ No pet found!')
                end
            else
                print('[AltControl] ❌ No player found!')
            end
        end
        
    elseif command == 'test_pet_broadcast' then
        -- Test manuel du broadcast
        print('[AltControl] Testing pet broadcast...')
        local player = windower.ffxi.get_player()
        if player then
            print('[AltControl] Player: ' .. player.name)
            local pet = windower.ffxi.get_mob_by_target("pet")
            if pet then
                print('[AltControl] Pet: ' .. (pet.name or 'Unknown'))
                local msg = string.format('petoverlay_owner:%s_pet:%s_hp:%d_maxhp:%d',
                    player.name, pet.name or 'Unknown', pet.hp or 0, 1000)
                print('[AltControl] Sending: ' .. msg)
                windower.send_ipc_message(msg)
                print('[AltControl] ✅ Message sent!')
            else
                print('[AltControl] ❌ No pet!')
            end
        end
    end
end)


----------------------------------------------------------
-- 🔹 JSON ENCODE / CONVERSION TABLE → JSON
----------------------------------------------------------

function escape_str(s)
    s = s or ""
    s = s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
    return '"' .. s .. '"'
end

-- 🆕 Détecte si une table est un array (indices numériques consécutifs)
function is_array(tbl)
    if type(tbl) ~= "table" then return false end
    local count = 0
    for k, _ in pairs(tbl) do
        count = count + 1
        if type(k) ~= "number" or k < 1 or k > count then
            return false
        end
    end
    return count > 0
end

function table_to_json(tbl)
    -- 🆕 Si c'est un array, utiliser la syntaxe JSON array []
    if is_array(tbl) then
        local result = {}
        for i = 1, #tbl do
            local value
            if type(tbl[i]) == "table" then
                value = table_to_json(tbl[i])
            elseif type(tbl[i]) == "string" then
                value = escape_str(tbl[i])
            elseif type(tbl[i]) == "number" or type(tbl[i]) == "boolean" then
                value = tostring(tbl[i])
            else
                value = 'null'
            end
            table.insert(result, value)
        end
        return '[' .. table.concat(result, ',') .. ']'
    end
    
    -- Sinon, utiliser la syntaxe JSON object {}
    local result = {}
    for k, v in pairs(tbl) do
        local key = '"' .. k .. '"'
        local value
        if type(v) == "table" then
            value = table_to_json(v)
        elseif type(v) == "string" then
            value = escape_str(v)
        elseif type(v) == "number" or type(v) == "boolean" then
            value = tostring(v)
        else
            value = 'null'
        end
        table.insert(result, key .. ':' .. value)
    end
    return '{' .. table.concat(result, ',') .. '}'
end


----------------------------------------------------------
-- 🔹 EXTRACTION DES DONNÉES FFXI
----------------------------------------------------------

-- 🗡️ Récupère l'ID de l'arme principale
function get_weapon_id()
    local equip = windower.ffxi.get_items().equipment
    local main_bag = equip.main_bag
    local main_slot = equip.main
    if main_bag and main_slot and main_slot > 0 then
        local items = windower.ffxi.get_items(main_bag)
        if items then
            local item = items[main_slot]
            if item and item.id then
                return tostring(item.id)
            end
        end
    end
    return "0"
end

-- 👥 Récupère les membres du groupe (sans les trusts)
function get_party_info()
    local party = windower.ffxi.get_party()
    local result = {}
    if type(party) ~= "table" then
        return result
    end
    -- Slots p0-p5 = joueurs réels, trust1-trust5 = trusts
    for i = 0, 5 do
        local member = party['p' .. i]
        if type(member) == "table" and member.name and member.name ~= "" then
            table.insert(result, member.name)
        end
    end
    return result
end

-- 🔌 Génère un port unique pour chaque personnage
function get_auto_port()
    local player = windower.ffxi.get_player()
    local base = 5008
    if player and player.name then
        local hash = 0
        for i = 1, #player.name do
            hash = hash + player.name:byte(i)
        end
        return base + (hash % 250)
    end
    return base
end

-- 🐾 Récupère les infos sur le familier (avec HP/TP)
function get_pet_info()
    local pet = windower.ffxi.get_mob_by_target("pet")
    if pet then
        return {
            active = true,
            name = pet.name or "Unknown",
            type = pet.name or "Unknown",
            hp = pet.hp or 0,
            hpp = pet.hpp or 0,  -- HP en pourcentage
            tp = pet.tp or 0,
        }
    else
        return {
            active = false,
            name = "",
            type = "",
            hp = 0,
            hpp = 0,
            tp = 0,
        }
    end
end

-- 🛡️ Récupère les buffs actifs du joueur (TOUS les buffs via ressources Windower)
function get_active_buffs()
    local player = windower.ffxi.get_player()
    if not player then return {names = {}, ids = {}} end
    
    local buffs = player.buffs or {}
    local buff_names = {}
    local buff_ids = {}
    
    -- 🆕 Charger les ressources de buffs Windower
    local res_buffs = require('resources').buffs
    
    -- Convertir les IDs de buffs en noms via les ressources Windower
    for _, buff_id in ipairs(buffs) do
        if buff_id and buff_id > 0 and buff_id ~= 255 then
            table.insert(buff_ids, buff_id)
            
            local buff_data = res_buffs[buff_id]
            if buff_data and buff_data.en then
                table.insert(buff_names, buff_data.en)
            end
        end
    end
    
    -- Retourner les deux: noms ET IDs
    return {names = buff_names, ids = buff_ids}
end

-- 🎵 Récupère les buffs de tous les membres du party
function get_party_buffs()
    local party = windower.ffxi.get_party()
    if not party then return {} end
    
    local res_buffs = require('resources').buffs
    local party_buffs = {}
    
    -- Parcourir tous les membres du party (p0 à p5)
    for i = 0, 5 do
        local member = party['p'..i]
        if member and member.mob then
            local mob = windower.ffxi.get_mob_by_id(member.mob.id)
            if mob then
                local buff_names = {}
                local buffs = mob.buffs or {}
                
                -- Convertir les IDs en noms
                for _, buff_id in ipairs(buffs) do
                    local buff_data = res_buffs[buff_id]
                    if buff_data and buff_data.en then
                        table.insert(buff_names, buff_data.en)
                    end
                end
                
                party_buffs[member.name] = buff_names
            end
        end
    end
    
    return party_buffs
end

-- 🐾 Calcule les charges Ready disponibles pour BST
function get_bst_ready_charges()
    local player = windower.ffxi.get_player()
    if not player or player.main_job ~= 'BST' then
        return 0
    end
    
    local ability_recasts = windower.ffxi.get_ability_recasts()
    if not ability_recasts then
        return 0
    end
    
    local ready_recast = ability_recasts[102] or 0  -- ID 102 = Ready
    local max_charges = 3
    
    -- Temps de base: 30 secondes
    local base_charge_timer = 30
    
    -- Réduction Job Points (5 secondes si JP > 100)
    if player.job_points and player.job_points.bst and player.job_points.bst.jp_spent > 100 then
        base_charge_timer = base_charge_timer - 5
    end
    
    -- Réduction Merits (2 secondes par merit Sic Recast)
    if player.merits and player.merits.sic_recast then
        base_charge_timer = base_charge_timer - (2 * player.merits.sic_recast)
    end
    
    -- Temps total pour recharger 3 charges
    local full_recharge_time = 3 * base_charge_timer
    
    -- Calcul des charges actuelles
    local current_charges = math.floor(max_charges - max_charges * ready_recast / full_recharge_time)
    
    return current_charges
end

-- ⏱️ Récupère les temps de recast des abilities et spells (seulement ceux actifs)
function get_recasts()
    local ability_recasts = windower.ffxi.get_ability_recasts()
    local spell_recasts = windower.ffxi.get_spell_recasts()
    
    -- Ne garder que les recasts > 0 pour réduire la taille du JSON
    local active_abilities = {}
    local active_spells = {}
    
    if ability_recasts then
        for id, time in pairs(ability_recasts) do
            if time and time > 0 then
                active_abilities[tostring(id)] = time
            end
        end
    end
    
    if spell_recasts then
        for id, time in pairs(spell_recasts) do
            if time and time > 0 then
                active_spells[tostring(id)] = time
            end
        end
    end
    
    return {
        abilities = active_abilities,
        spells = active_spells
    }
end


----------------------------------------------------------
-- 🔹 GESTION DE L'ÉTAT ET ENVOI D'INFOS AU SERVEUR
----------------------------------------------------------

-- Sauvegarde du dernier état connu pour éviter les envois inutiles
local last_state = {
    main_job = nil,
    sub_job = nil,
    pet_name = nil,  -- 🐾 Keep for Blood Pact menu
    weapon_id = nil,
    party_members = {}
}

-- Compare deux listes (ex : membres du groupe)
local function table_diff(t1, t2)
    if #t1 ~= #t2 then return true end
    for i = 1, #t1 do
        if t1[i] ~= t2[i] then return true end
    end
    return false
end

-- 🛰️ Envoi des informations Alt vers le serveur local
function send_alt_info()
    local player = windower.ffxi.get_player()
    if not player or not player.name then return end

    -- 🐾 Get pet name only (for Blood Pact menu filtering)
    local pet = windower.ffxi.get_mob_by_target("pet")
    local pet_name = pet and pet.name or nil
    
    local party_info = get_party_info()
    local weapon_id = get_weapon_id()

    -- 🆕 MODIFICATION: Vérification désactivée pour envoyer les recasts en temps réel
    -- Cette section était commentée pour permettre l'envoi continu des recasts
    --[[
    if last_state.main_job == player.main_job
       and last_state.sub_job == player.sub_job
       and last_state.pet_name == pet_info.name
       and last_state.weapon_id == weapon_id
       and not table_diff(party_info, last_state.party_members) then
        return
    end
    ]]--

    -- 🔄 Mise à jour de l'état actuel
    last_state.main_job = player.main_job
    last_state.sub_job = player.sub_job
    last_state.pet_name = pet_name  -- 🐾 Keep for Blood Pact menu
    last_state.weapon_id = weapon_id
    last_state.party_members = party_info

    -- 🔧 Préparation des données à envoyer
    local port_alt = get_auto_port()
    local recasts = get_recasts()
    -- local bst_charges = get_bst_ready_charges()  -- 🗑️ Now in overlay only
    local active_buffs = get_active_buffs()
    
    -- Buffs envoyés (debug désactivé)
    
    -- 🆕 Détecter l'état du joueur
    local is_engaged = player.status == 1  -- 1 = Engaged
    local is_casting = player.status == 4  -- 4 = Casting
    
    -- 🆕 Détecter si quelqu'un dans la party est engagé (pour le BRD)
    local party_engaged = false
    local party = windower.ffxi.get_party()
    if party then
        for i = 0, 5 do
            local member = party['p'..i]
            if member and member.name then
                -- Utiliser get_mob_by_name au lieu de get_mob_by_id
                local mob = windower.ffxi.get_mob_by_name(member.name)
                if mob and mob.status == 1 then
                    party_engaged = true
                    break
                end
            end
        end
    end
    
    -- 🆕 Pour le mouvement, vérifier si SongService BRD est actif et utiliser son état
    local is_moving = false
    local queue_size = 0
    if songservice and songservice.active and player.main_job == 'BRD' then
        -- Utiliser l'état de mouvement de SongService
        is_moving = songservice.moving or false
        -- Utiliser la taille de la queue de songs de SongService
        queue_size = #(songservice.song_queue or {})
    end
    
    local data = {
        name = player.name,
        main_job = player.main_job,
        sub_job = player.sub_job,
        main_job_level = player.main_job_level,
        sub_job_level = player.sub_job_level,
        weapon_id = weapon_id,
        port = port_alt,
        party = party_info,
        pet_name = pet_name,  -- 🐾 Keep for Blood Pact menu filtering
        -- 🗑️ Other pet data removed - now handled by AltPetOverlay directly
        -- pet_active, pet_type, pet_hp, pet_hpp, pet_tp, bst_ready_charges
        is_engaged = is_engaged,
        party_engaged = party_engaged,  -- 🆕 Quelqu'un dans la party est en combat
        is_moving = is_moving,
        is_casting = is_casting,
        queue_size = queue_size,  -- 🆕 Taille de la queue SongService
        active_buffs = active_buffs.names,  -- Noms des buffs (pour compatibilité)
        active_buff_ids = active_buffs.ids,  -- 🆕 IDs des buffs
        ability_recasts = recasts.abilities,
        spell_recasts = recasts.spells
    }

    -- 📤 Envoi TCP vers le serveur principal AVEC PROTECTION ET DEBUG
    print('[Extended] 🔄 Preparing to send data for ' .. player.name)
    
    local success, err = pcall(function()
        local client = socket.tcp()
        if not client then 
            print('[Extended] ❌ Failed to create TCP client')
            return 
        end
        
        client:settimeout(2.0)  -- Timeout augmenté pour debug
        print('[Extended] 🔌 Connecting to ' .. host .. ':' .. base_port)
        local ok, conn_err = client:connect(host, base_port)
        
        if ok then
            print('[Extended] ✅ Connected to server')
            
            -- 🆕 PROTECTION contre les erreurs de sérialisation
            local success_json, msg = pcall(table_to_json, data)
            if success_json and msg then
                print('[Extended] 📤 Sending ' .. #msg .. ' bytes to server')
                client:send(msg)
                print('[Extended] ✅ Data sent successfully')
            else
                print('[Extended] ❌ JSON serialization failed: ' .. tostring(msg))
                -- Debug: afficher le contenu de data
                print('[Extended] 🔍 Data content:')
                for k, v in pairs(data) do
                    print('[Extended]   ' .. k .. ' = ' .. tostring(v))
                end
            end
            client:close()
        else
            print('[Extended] ❌ Server connection failed: ' .. tostring(conn_err))
        end
    end)
    
    if not success then
        print('[Extended] ❌ Send error: ' .. tostring(err))
    end
end

-- Tentative d'envoi avec attente du chargement du joueur
function send_alt_info_safe()
    local tries = 0
    local max_tries = 15
    while tries < max_tries do
        local player = windower.ffxi.get_player()
        if player and player.name then
            send_alt_info()
            return
        end
        coroutine.sleep(0.5)
        tries = tries + 1
    end
end


----------------------------------------------------------
-- 🔹 ÉCRITURE DU PORT ALT DANS UN FICHIER LOCAL
----------------------------------------------------------

function write_connection_file()
    local player = windower.ffxi.get_player()
    local port_alt = get_auto_port()
    if player and player.name then
        local dir = windower.addon_path:match("^(.-)[^\\/]*$") .. "data/"
        windower.create_dir(dir)
        local path = dir .. player.name .. ".txt"
        local f = io.open(path, "w")
        if f then
            f:write(tostring(port_alt))
            f:close()
        end
    end
end


----------------------------------------------------------
-- 🔹 RÉCEPTION DE COMMANDES TCP (depuis l'app externe)
----------------------------------------------------------

local tcp_server = nil
local tcp_running = false

function listen_for_commands()
    local listen_port = get_auto_port()
    tcp_server = assert(socket.bind("127.0.0.1", listen_port))
    tcp_server:settimeout(0)
    tcp_running = true
    
    coroutine.schedule(function()
        while tcp_running do
            local client = tcp_server:accept()
            if client then
                client:settimeout(1)
                local command = client:receive("*l")
                if command and command ~= "" then
                    windower.send_command('input ' .. command)
                end
                client:close()
            end
            coroutine.sleep(0.5)
        end
        
        -- Fermer le serveur proprement
        if tcp_server then
            tcp_server:close()
            tcp_server = nil
        end
    end, 0)
end

function stop_listening()
    tcp_running = false
    if tcp_server then
        tcp_server:close()
        tcp_server = nil
    end
end


----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS WINDOWER
----------------------------------------------------------

----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS WINDOWER (Extended)
----------------------------------------------------------

-- 🐾 Pet change / Pet status change
windower.register_event('pet_change', send_alt_info)
windower.register_event('pet_status_change', send_alt_info)

-- 🐾 Envoi des données pet vers AltPetOverlay via socket
local pet_debug = false
local last_pet_broadcast = 0
local pet_overlay_socket = nil

function connect_to_overlay()
    if not pet_overlay_socket then
        pet_overlay_socket = socket.tcp()
        pet_overlay_socket:settimeout(0.1)
        local ok, err = pet_overlay_socket:connect('127.0.0.1', 5009)
        if not ok then
            pet_overlay_socket = nil
            return false
        end
    end
    return true
end

-- Socket pour envoyer les données pet à l'overlay
local pet_overlay_socket = nil

function connect_to_pet_overlay()
    if not pet_overlay_socket then
        pet_overlay_socket = socket.tcp()
        pet_overlay_socket:settimeout(0.1)
        local ok, err = pet_overlay_socket:connect('127.0.0.1', 5009)
        if not ok then
            pet_overlay_socket = nil
            return false
        end
    end
    return true
end

function broadcast_pet_to_overlay()
    local player = windower.ffxi.get_player()
    if not player or not player.name then 
        return 
    end
    
    local pet = windower.ffxi.get_mob_by_target("pet")
    
    -- Si pas de pet, envoyer un message pour retirer l'affichage
    if not pet then 
        local msg = string.format('%s|NOPET|0||||||UNKNOWN\n', player.name)
        if connect_to_pet_overlay() then
            pet_overlay_socket:send(msg)
        end
        return 
    end
    
    -- Calculer HP%
    local hpp = pet.hpp or 100
    
    -- Infos spécifiques au job
    local charges = ''
    local bp_rage = ''
    local bp_ward = ''
    local breath_ready = ''
    local job = player.main_job or 'UNKNOWN'
    
    if player.main_job == 'BST' then
        charges = tostring(get_bst_ready_charges())
    elseif player.main_job == 'SMN' then
        local ability_recasts = windower.ffxi.get_ability_recasts()
        bp_rage = tostring(ability_recasts and ability_recasts[173] or 0)
        bp_ward = tostring(ability_recasts and ability_recasts[174] or 0)
    elseif player.main_job == 'DRG' then
        local ability_recasts = windower.ffxi.get_ability_recasts()
        local breath_timer = ability_recasts and ability_recasts[163] or 0
        breath_ready = (breath_timer <= 0) and 'true' or 'false'
    end
    
    -- Format socket: owner|name|hpp|charges|bp_rage|bp_ward|breath_ready|job
    local msg = string.format('%s|%s|%d|%s|%s|%s|%s|%s\n',
        player.name,
        pet.name or 'Unknown',
        hpp,
        charges,
        bp_rage,
        bp_ward,
        breath_ready,
        job
    )
    
    -- Envoyer via socket
    if connect_to_pet_overlay() then
        local ok, err = pet_overlay_socket:send(msg)
        if not ok then
            pet_overlay_socket:close()
            pet_overlay_socket = nil
        end
    end
end

windower.register_event('pet_change', broadcast_pet_to_overlay)
windower.register_event('pet_status_change', broadcast_pet_to_overlay)

-- 💼 Changement de job principal ou subjob
windower.register_event('job_change', send_alt_info)

-- 🗡️ Détection du changement d'équipement (arme principale, etc.)
windower.register_event('equip change', send_alt_info)



-- (Boucle principale déplacée dans Extended.initialize())

----------------------------------------------------------
-- 🔹 PRERENDER (appelé chaque frame pour DistanceFollow)
----------------------------------------------------------

windower.register_event('prerender', function()
    -- DistanceFollow a besoin d'être appelé chaque frame pour un mouvement fluide
    if distancefollow and distancefollow.enabled then
        distancefollow.update()
    end
    
    -- AltPetOverlay check socket chaque frame
    if altpetoverlay then
        altpetoverlay.update()
    end
    
    -- SongService update chaque frame
    if songservice and songservice.active then
        songservice.update()
    end
end)

----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS
----------------------------------------------------------

----------------------------------------------------------
-- 🔹 FONCTIONS DU MODULE EXTENDED
----------------------------------------------------------

function Extended.initialize()
    print('[Extended] 🚀 Initializing features...')
    
    -- 🆕 Démarrer l'écoute TCP
    listen_for_commands()
    print('[Extended] ✅ TCP listener started on port ' .. get_auto_port())
    
    -- Démarrer la boucle principale d'envoi de données
    coroutine.schedule(function()
        local debug_counter = 0
        local pet_update_counter = 0
        while true do
            send_alt_info()
            
            -- Mise à jour AutoEngage si actif
            if autoengage then
                if autoengage.is_active() then
                    autoengage.update()
                end
            end
            
            -- Broadcast pet data to overlay every 0.5 seconds
            pet_update_counter = pet_update_counter + 1
            if pet_update_counter >= 5 then
                broadcast_pet_to_overlay()
                pet_update_counter = 0
            end
            
            coroutine.sleep(0.1)
        end
    end, 0)
    
    -- Charger l'overlay si personnage principal
    local player = windower.ffxi.get_player()
    if player then
        -- Lire party_roles.json
        local addon_dir = windower.addon_path:match("^(.+[/\\])")
        local file_path = addon_dir .. "../data_json/party_roles.json"
        
        local file = io.open(file_path, "r")
        local main_character = nil
        
        if file then
            local content = file:read("*all")
            file:close()
            main_character = content:match('"main_character"%s*:%s*"([^"]+)"')
        end
        
        if main_character and player.name == main_character then
            print('[Extended] Loading AltPetOverlay tool...')
            altpetoverlay = load_tool('AltPetOverlay')
            if altpetoverlay then
                altpetoverlay.init()
                print('[Extended] ✅ Pet Overlay loaded (main: ' .. main_character .. ')')
            else
                print('[Extended] ❌ Failed to load Pet Overlay')
            end
        end
    end
    
    print('[Extended] ✅ All features initialized')
end

function Extended.shutdown()
    print('[Extended] 🛑 Shutting down features...')
    
    -- 🆕 Arrêter l'écoute TCP
    stop_listening()
    print('[Extended] ✅ TCP listener stopped')
    
    -- Arrêter tout mouvement
    windower.ffxi.run(false)
    
    -- Arrêter AutoEngage si actif
    if autoengage and autoengage.is_active then
        pcall(function() autoengage.stop() end)
    end
    
    -- Arrêter DistanceFollow si actif
    if distancefollow and distancefollow.enabled then
        pcall(function() distancefollow.stop() end)
    end
    
    print('[Extended] ✅ All features stopped')
end

----------------------------------------------------------
-- 🟢 RETOUR DU MODULE
----------------------------------------------------------

return Extended
