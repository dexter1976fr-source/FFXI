--[[
    AltPetOverlay - Version propre avec pets séparés
    Chaque pet a son propre texte + barres
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0'
_addon.commands = {'petoverlay', 'po'}

local texts = require('texts')
local images = require('images')
local config = require('config')
local socket = require('socket')

-- Settings with config file
local defaults = {
    pos = {x = 100, y = 500},
    visible = true,
    port = 5009  -- Port d'écoute pour les données de pets
}
local settings = config.load(defaults)

-- Pet data with fixed slots
local pet_slots = {
    [1] = nil,  -- Slot 1
    [2] = nil,  -- Slot 2
    [3] = nil   -- Slot 3
}
local owner_to_slot = {}  -- Map owner -> slot number
local next_slot = 1
local pet_displays = {}
local drag_reference = nil

-- Asset path
local asset_path = windower.addon_path .. 'assets/xiv/'

-- Socket server
local server = nil
local clients = {}

-- Initialize socket server
function init_socket_server()
    server = socket.tcp()
    server:setoption('reuseaddr', true)
    server:bind('127.0.0.1', settings.port)
    server:listen(5)
    server:settimeout(0)
    windower.add_to_chat(122, string.format('[PetOverlay] Listening on port %d', settings.port))
end

-- Process incoming data
function process_pet_data(data)
    -- Format: owner|name|hpp|charges|bp_rage|bp_ward|breath_ready
    local owner, name, hpp, charges, bp_rage, bp_ward, breath_ready = data:match('([^|]+)|([^|]+)|([^|]+)|([^|]*)|([^|]*)|([^|]*)|([^|]*)')
    
    if owner and name then
        -- Assign slot if new owner
        if not owner_to_slot[owner] then
            owner_to_slot[owner] = next_slot
            windower.add_to_chat(122, string.format('[PetOverlay] New pet: %s (%s) -> Slot %d', owner, name, next_slot))
            next_slot = next_slot + 1
        end
        
        local slot = owner_to_slot[owner]
        
        pet_slots[slot] = {
            owner = owner,
            name = name,
            hpp = tonumber(hpp) or 100,
            charges = tonumber(charges),
            bp_rage = tonumber(bp_rage),
            bp_ward = tonumber(bp_ward),
            breath_ready = breath_ready == 'true',
            last_update = os.clock()
        }
        return true, slot
    end
    return false
end

-- Check for new connections and data
function check_socket()
    if not server then return end
    
    -- Accept new connections (errors are silenced)
    local ok, client = pcall(function() return server:accept() end)
    if ok and client then
        client:settimeout(0)
        table.insert(clients, client)
        windower.add_to_chat(122, '[PetOverlay] Client connected!')
    end
    
    -- Read from existing clients
    for i = #clients, 1, -1 do
        local client = clients[i]
        local data, err = client:receive('*l')
        
        if data then
            local success, slot = process_pet_data(data)
            if success and slot then
                update_slot(slot)
            end
        elseif err == 'closed' then
            pcall(function() client:close() end)
            table.remove(clients, i)
        end
    end
end

-- Create display for ONE pet (complètement indépendant)
function create_pet_display(owner, pet_data, index)
    local disp = {}
    
    -- Position de base pour ce pet (chaque pet = 60px de hauteur)
    local pet_y = settings.pos.y + (index * 60)
    local pet_x = settings.pos.x
    
    -- Background noir (draggable seulement pour le premier pet)
    disp.bg = images.new()
    disp.bg:path(asset_path .. 'BgMid.png')
    disp.bg:pos(pet_x, pet_y)
    disp.bg:size(400, 50)
    disp.bg:color(255, 255, 255, 220)
    disp.bg:draggable(index == 0)  -- Seulement le premier est draggable
    disp.bg:fit(false)
    disp.bg:show()
    
    -- Store reference for drag detection
    if index == 0 then
        drag_reference = disp.bg
    end
    
    -- Texte pour CE pet uniquement
    disp.text = texts.new('', {
        pos = {x = pet_x + 8, y = pet_y + 5},
        text = {
            font = 'Arial',
            size = 11,
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255
        },
        bg = {visible = false},
        stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0},
        flags = {bold = false, draggable = false}
    })
    
    -- Build text for this pet
    local lines = {}
    table.insert(lines, string.format('\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr', owner, pet_data.name))
    
    -- Job info
    if pet_data.bp_rage or pet_data.bp_ward then
        -- SMN Blood Pact timers (Rage et Ward)
        local rage_str = ''
        local ward_str = ''
        
        if pet_data.bp_rage then
            if pet_data.bp_rage <= 0 then
                rage_str = '\\cs(255,100,100)BPR: Ready\\cr'
            else
                rage_str = string.format('\\cs(255,150,150)BPR: %.1fs\\cr', pet_data.bp_rage)
            end
        end
        
        if pet_data.bp_ward then
            if pet_data.bp_ward <= 0 then
                ward_str = '\\cs(100,200,255)BPW: Ready\\cr'
            else
                ward_str = string.format('\\cs(150,200,255)BPW: %.1fs\\cr', pet_data.bp_ward)
            end
        end
        
        table.insert(lines, rage_str .. '  ' .. ward_str)
    elseif pet_data.charges and pet_data.charges > 0 then
        -- BST Ready charges (max 3)
        local str = '\\cs(120,255,120)Ready:\\cr '
        for i = 1, 3 do
            str = str .. (i <= pet_data.charges and '\\cs(120,255,120)●\\cr' or '\\cs(80,80,80)○\\cr')
            if i < 3 then str = str .. ' ' end
        end
        table.insert(lines, str .. string.format(' \\cs(150,150,150)(%d/3)\\cr', pet_data.charges))
    elseif pet_data.breath_ready ~= nil then
        -- DRG Breath
        table.insert(lines, pet_data.breath_ready and '\\cs(120,255,120)Breath Ready\\cr' or '\\cs(150,150,150)Breath: Not Ready\\cr')
    end
    
    disp.text:text(table.concat(lines, '\n'))
    disp.text:show()
    
    -- HP Bars (position fixe relative au pet)
    local bar_y = pet_y + 32  -- Position fixe pour la barre
    local bar_x = pet_x + 8
    
    -- HP Bar Background
    disp.hp_bg = images.new()
    disp.hp_bg:path(asset_path .. 'BarBG.png')
    disp.hp_bg:pos(bar_x, bar_y)
    disp.hp_bg:size(300, 12)
    disp.hp_bg:color(255, 255, 255, 255)
    disp.hp_bg:draggable(false)
    disp.hp_bg:fit(false)
    disp.hp_bg:show()
    
    -- HP Bar
    local hp_percent = (pet_data.hpp or 100) / 100
    local bar_width = 300 * hp_percent
    
    disp.hp_bar = images.new()
    disp.hp_bar:path(asset_path .. 'Bar.png')
    disp.hp_bar:pos(bar_x, bar_y)
    disp.hp_bar:size(bar_width, 12)
    
    -- Couleur selon HP%
    if hp_percent < 0.25 then
        disp.hp_bar:color(252, 129, 130, 255)
    elseif hp_percent < 0.50 then
        disp.hp_bar:color(248, 186, 128, 255)
    elseif hp_percent < 0.75 then
        disp.hp_bar:color(243, 243, 124, 255)
    else
        disp.hp_bar:color(160, 240, 128, 255)
    end
    
    disp.hp_bar:draggable(false)
    disp.hp_bar:fit(false)
    disp.hp_bar:show()
    
    -- HP Bar Foreground
    disp.hp_fg = images.new()
    disp.hp_fg:path(asset_path .. 'BarFG.png')
    disp.hp_fg:pos(bar_x, bar_y)
    disp.hp_fg:size(300, 12)
    disp.hp_fg:color(255, 255, 255, 200)
    disp.hp_fg:draggable(false)
    disp.hp_fg:fit(false)
    disp.hp_fg:show()
    
    return disp
end

-- Build text content for a pet
function build_pet_text(owner, pet_data)
    local lines = {}
    table.insert(lines, string.format('\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr', owner, pet_data.name))
    
    -- Job info
    if pet_data.bp_rage or pet_data.bp_ward then
        -- SMN Blood Pact timers (Rage et Ward)
        local rage_str = ''
        local ward_str = ''
        
        if pet_data.bp_rage then
            if pet_data.bp_rage <= 0 then
                rage_str = '\\cs(255,100,100)BPR: Ready\\cr'
            else
                rage_str = string.format('\\cs(255,150,150)BPR: %.1fs\\cr', pet_data.bp_rage)
            end
        end
        
        if pet_data.bp_ward then
            if pet_data.bp_ward <= 0 then
                ward_str = '\\cs(100,200,255)BPW: Ready\\cr'
            else
                ward_str = string.format('\\cs(150,200,255)BPW: %.1fs\\cr', pet_data.bp_ward)
            end
        end
        
        table.insert(lines, rage_str .. '  ' .. ward_str)
    elseif pet_data.charges and pet_data.charges > 0 then
        -- BST Ready charges (max 3)
        local str = '\\cs(120,255,120)Ready:\\cr '
        for i = 1, 3 do
            str = str .. (i <= pet_data.charges and '\\cs(120,255,120)●\\cr' or '\\cs(80,80,80)○\\cr')
            if i < 3 then str = str .. ' ' end
        end
        table.insert(lines, str .. string.format(' \\cs(150,150,150)(%d/3)\\cr', pet_data.charges))
    elseif pet_data.breath_ready ~= nil then
        -- DRG Breath
        table.insert(lines, pet_data.breath_ready and '\\cs(120,255,120)Breath Ready\\cr' or '\\cs(150,150,150)Breath: Not Ready\\cr')
    end
    
    return table.concat(lines, '\n')
end

-- Update pet display
function update_pet_display(disp, pet_data)
    if not disp then return end
    
    -- Update text
    if disp.text then
        disp.text:text(build_pet_text(pet_data.owner, pet_data))
    end
    
    -- Update HP bar
    local hp_percent = (pet_data.hpp or 100) / 100
    local bar_width = 300 * hp_percent
    
    disp.hp_bar:size(bar_width, 12)
    
    if hp_percent < 0.25 then
        disp.hp_bar:color(252, 129, 130, 255)
    elseif hp_percent < 0.50 then
        disp.hp_bar:color(248, 186, 128, 255)
    elseif hp_percent < 0.75 then
        disp.hp_bar:color(243, 243, 124, 255)
    else
        disp.hp_bar:color(160, 240, 128, 255)
    end
end

-- Delete pet display
function delete_pet_display(disp)
    if disp then
        if disp.bg then disp.bg:destroy() end
        if disp.text then disp.text:hide() end
        if disp.hp_bg then disp.hp_bg:destroy() end
        if disp.hp_bar then disp.hp_bar:destroy() end
        if disp.hp_fg then disp.hp_fg:destroy() end
    end
end

-- Update single slot
function update_slot(slot)
    if not settings.visible then return end
    
    local pet_data = pet_slots[slot]
    if not pet_data then
        -- Remove display if exists
        if pet_displays[slot] then
            delete_pet_display(pet_displays[slot])
            pet_displays[slot] = nil
        end
        return
    end
    
    -- Create display if doesn't exist
    if not pet_displays[slot] then
        pet_displays[slot] = create_pet_display(pet_data.owner, pet_data, slot - 1)
        if slot == 1 then
            drag_reference = pet_displays[slot].bg
        end
    else
        -- Update existing display
        update_pet_display(pet_displays[slot], pet_data)
    end
end

-- Update all displays
function update_all()
    if not settings.visible then
        for slot, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        return
    end
    
    -- Update each slot
    for slot = 1, 3 do
        update_slot(slot)
    end
end

-- Delete pet display
function delete_pet_display(disp)
    if disp then
        if disp.bg then disp.bg:destroy() end
        if disp.text then disp.text:hide() end
        if disp.hp_bg then disp.hp_bg:destroy() end
        if disp.hp_bar then disp.hp_bar:destroy() end
        if disp.hp_fg then disp.hp_fg:destroy() end
    end
end

-- Update all
function update_all()
    if not settings.visible then
        for owner, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        return
    end
    
    -- Clear old displays
    for owner, disp in pairs(pet_displays) do
        if not pets[owner] then
            delete_pet_display(disp)
            pet_displays[owner] = nil
        end
    end
    
    -- Create sorted list of owners for stable ordering
    local owners = {}
    for owner in pairs(pets) do
        table.insert(owners, owner)
    end
    table.sort(owners)
    
    -- Create or update each pet with stable index
    for index, owner in ipairs(owners) do
        local pet_data = pets[owner]
        
        -- Create if doesn't exist
        if not pet_displays[owner] then
            pet_displays[owner] = create_pet_display(owner, pet_data, index - 1)
        else
            -- Update existing display
            update_pet_display(pet_displays[owner], pet_data)
        end
    end
end

-- Debug flag
local overlay_debug = false

-- Drag detection, server polling, and cleanup
local last_cleanup = 0
local last_drag_pos = nil
local last_drag_save = 0
local is_dragging = false
local last_server_poll = 0

windower.register_event('prerender', function()
    if not settings.visible then return end
    
    local now = os.clock()
    
    -- Check for drag movement (with debounce)
    if drag_reference then
        local current_x = drag_reference:pos_x()
        local current_y = drag_reference:pos_y()
        
        if not last_drag_pos then
            last_drag_pos = {x = current_x, y = current_y}
        elseif current_x ~= last_drag_pos.x or current_y ~= last_drag_pos.y then
            -- Position is changing (dragging in progress)
            is_dragging = true
            last_drag_pos = {x = current_x, y = current_y}
            last_drag_save = now
        elseif is_dragging and (now - last_drag_save > 0.5) then
            -- Drag finished (position stable for 0.5s)
            is_dragging = false
            settings.pos.x = current_x
            settings.pos.y = current_y
            settings:save()
            
            -- Recreate all displays at new position
            for owner, disp in pairs(pet_displays) do
                delete_pet_display(disp)
            end
            pet_displays = {}
            drag_reference = nil
            update_all()
            
            windower.add_to_chat(122, string.format('[PetOverlay] Position saved: %d, %d', current_x, current_y))
        end
    end
    
    -- Check socket for new data (every frame for real-time)
    check_socket()
end)

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'pos' then
        settings.pos.x = tonumber(args[2]) or settings.pos.x
        settings.pos.y = tonumber(args[3]) or settings.pos.y
        settings:save()
        for owner, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        drag_reference = nil
        last_drag_pos = nil
        update_all()
        windower.add_to_chat(122, string.format('[PetOverlay] Position: %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'test' then
        pets['Dexterbrown'] = {
            owner = 'Dexterbrown',
            name = 'BlackbeardRandy',
            hp = 650,
            max_hp = 1000,
            charges = 3,
            last_update = os.clock() + 9999
        }
        pets['Summoner'] = {
            owner = 'Summoner',
            name = 'Ifrit',
            hp = 800,
            max_hp = 1000,
            bp_timer = 2.5,
            last_update = os.clock() + 9999
        }
        update_all()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        update_all()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    elseif cmd == 'debug' then
        overlay_debug = not overlay_debug
        windower.add_to_chat(122, '[PetOverlay] Debug: ' .. (overlay_debug and 'ON' or 'OFF'))
        
    elseif cmd == 'read' then
        -- Test manual de lecture du fichier
        windower.add_to_chat(122, '[PetOverlay] Reading file: ' .. pets_file)
        local new_pets = read_pets_from_file()
        if new_pets then
            local count = 0
            for owner, pet_data in pairs(new_pets) do
                count = count + 1
                windower.add_to_chat(122, string.format('[PetOverlay] Found: %s - %s (HP: %d/%d)', 
                    owner, pet_data.name, pet_data.hp, pet_data.max_hp))
            end
            windower.add_to_chat(122, string.format('[PetOverlay] Total pets: %d', count))
            pets = new_pets
            update_all()
        else
            windower.add_to_chat(122, '[PetOverlay] No pets found or file error')
        end
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands: //po test | //po clear | //po pos <x> <y> | //po debug | //po read')
    end
end)

-- Unload
windower.register_event('unload', function()
    -- Close all client connections
    for _, client in ipairs(clients) do
        client:close()
    end
    
    -- Close server
    if server then
        server:close()
    end
    
    -- Clean displays
    for owner, disp in pairs(pet_displays) do
        delete_pet_display(disp)
    end
    
    settings:save()
end)

-- Initialize socket server
init_socket_server()

windower.add_to_chat(122, '[AltPetOverlay] Loaded - Real-time socket mode')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test | Drag first pet to move')

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'pos' then
        settings.pos.x = tonumber(args[2]) or settings.pos.x
        settings.pos.y = tonumber(args[3]) or settings.pos.y
        settings:save()
        -- Recreate all
        for slot, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        drag_reference = nil
        update_all()
        windower.add_to_chat(122, string.format('[PetOverlay] Position: %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'clear' then
        for slot = 1, 3 do
            pet_slots[slot] = nil
        end
        owner_to_slot = {}
        next_slot = 1
        update_all()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands: //po clear | //po pos <x> <y>')
    end
end)

-- Unload
windower.register_event('unload', function()
    -- Close all client connections
    for _, client in ipairs(clients) do
        client:close()
    end
    
    -- Close server
    if server then
        server:close()
    end
    
    -- Clean displays
    for slot, disp in pairs(pet_displays) do
        delete_pet_display(disp)
    end
    
    settings:save()
end)

-- Initialize socket server
init_socket_server()

windower.add_to_chat(122, '[AltPetOverlay] Loaded - Real-time socket mode')
windower.add_to_chat(122, '[PetOverlay] Listening on port ' .. settings.port)
