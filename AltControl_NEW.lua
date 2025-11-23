----------------------------------------------------------
-- ALT CONTROL (CORE) - Version légère
-- Charge uniquement les fonctions essentielles
-- Extended chargé à la demande via //ac load_extended
----------------------------------------------------------

-- Déclaration de l'addon
_addon = _addon or {}
_addon.name = 'AltControl'
_addon.author = 'FFXI ALT Control Team'
_addon.version = '2.0.0'  -- Version split
_addon.commands = {'altcontrol', 'ac'}

local socket = require('socket')
local host = "127.0.0.1"
local base_port = 5007

----------------------------------------------------------
-- 🔹 MODULE EXTENDED (chargé dynamiquement)
----------------------------------------------------------

local extended_module = nil
local extended_loaded = false

----------------------------------------------------------
-- 🔹 FONCTIONS ESSENTIELLES (Core)
----------------------------------------------------------

-- Génère un port unique pour chaque personnage
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

-- Écrit le port dans un fichier local
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

-- Écoute les commandes TCP du serveur Python
function listen_for_commands()
    local listen_port = get_auto_port()
    local server = assert(socket.bind("127.0.0.1", listen_port))
    server:settimeout(0)
    coroutine.schedule(function()
        while true do
            local client = server:accept()
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
    end, 0)
end

----------------------------------------------------------
-- 🔹 COMMANDES ADDON
----------------------------------------------------------

windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or nil
    
    if command == 'load_extended' then
        -- Charger le module Extended
        if not extended_loaded then
            print('[AltControl] Loading Extended features...')
            local success, module = pcall(require, 'AltControlExtended')
            if success then
                extended_module = module
                extended_module.initialize()
                extended_loaded = true
                print('[AltControl] ✅ Extended features loaded')
            else
                print('[AltControl] ❌ Failed to load Extended:', module)
            end
        else
            print('[AltControl] ⚠️ Extended already loaded')
        end
        
    elseif command == 'unload_extended' then
        -- Décharger le module Extended
        if extended_loaded and extended_module then
            print('[AltControl] Unloading Extended features...')
            extended_module.shutdown()
            extended_module = nil
            extended_loaded = false
            
            -- Forcer le garbage collector
            package.loaded['AltControlExtended'] = nil
            collectgarbage()
            
            print('[AltControl] ✅ Extended features unloaded')
        else
            print('[AltControl] ⚠️ Extended not loaded')
        end
        
    elseif command == 'status' then
        -- Afficher le status
        print('[AltControl] Core: ACTIVE')
        if extended_loaded then
            print('[AltControl] Extended: LOADED')
        else
            print('[AltControl] Extended: NOT LOADED')
        end
        
    else
        -- Toutes les autres commandes nécessitent Extended
        if not extended_loaded then
            print('[AltControl] ⚠️ Command requires Extended features')
            print('[AltControl] Load Extended with: //ac load_extended')
        else
            print('[AltControl] ⚠️ Unknown command: ' .. (command or 'nil'))
        end
    end
end)

----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS WINDOWER (Core)
----------------------------------------------------------

-- Fonction d'initialisation après login
local function initialize_after_login()
    local tries = 0
    local max_tries = 20
    while tries < max_tries do
        local player = windower.ffxi.get_player()
        if player and player.name then
            write_connection_file()
            listen_for_commands()
            print('[AltControl] ✅ Core initialized for ' .. player.name)
            print('[AltControl] Port: ' .. get_auto_port())
            print('[AltControl] Load Extended with: //ac load_extended')
            return
        end
        coroutine.sleep(0.5)
        tries = tries + 1
    end
end

-- Quand l'addon est chargé
windower.register_event('load', function()
    coroutine.schedule(initialize_after_login, 1)
end)

-- Quand on se connecte / relog
windower.register_event('login', function()
    coroutine.schedule(initialize_after_login, 2)
end)

-- Quand on quitte le jeu ou décharge l'addon
windower.register_event('unload', write_connection_file)

----------------------------------------------------------
-- 🟢 FIN DU CORE
----------------------------------------------------------

print('[AltControl] Core loaded - Lightweight mode')
