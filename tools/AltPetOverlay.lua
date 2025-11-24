----------------------------------------------------------
-- ALT PET OVERLAY - Module intégré AltControl
-- Version: 2.0.0 (Tool Module - Socket)
-- Affiche les pets avec HP, charges BST, BP timers SMN, etc.
----------------------------------------------------------

local AltPetOverlay = {}

-- Libraries
local texts = require('texts')
local images = require('images')
local config = require('config')
local socket = require('socket')

-- Settings
local defaults = {
    pos = {x = 100, y = 500},
    visible = true,
    port = 5009
}
local settings = config.load(defaults)

-- Pet data with fixed slots
local pet_slots = {
    [1] = nil,
    [2] = nil,
    [3] = nil
}
local owner_to_slot = {}
local next_slot = 1
local pet_displays = {}
local drag_reference = nil

-- Asset path
local asset_path = windower.addon_path .. 'assets/xiv/'

-- Socket server
local server = nil
local clients = {}

-- Initialize socket server
local function init_socket_server()
    server = socket.tcp()
    server:setoption('reuseaddr', true)
    local ok, err = server:bind('127.0.0.1', settings.port)
    if not ok then
        print('[PetOverlay] ERROR: Could not bind to port ' .. settings.port .. ': ' .. (err or 'unknown'))
        return false
    end
    server:listen(5)
    server:settimeout(0)
    print('[PetOverlay] Listening on port ' .. settings.port)
    return true
end

-- Process incoming data
local function process_pet_data(data)
    local owner, name, hpp, charges, bp_rage, bp_ward, breath_ready, job = data:match('([^|]+)|([^|]+)|([^|]+)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)')
    
    if owner and name then
        if not owner_to_slot[owner] then
            owner_to_slot[owner] = next_slot
            next_slot = next_slot + 1
        end
        
        local slot = owner_to_slot[owner]
        
        pet_slots[slot] = {
            owner = owner,
            name = name,
            hpp = tonumber(hpp) or 100,
            job = job or 'UNKNOWN',
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
local function check_socket()
    if not server then return end
    
    local client = server:accept()
    if client then
        client:settimeout(0)
        table.insert(clients, client)
    end
    
    for i = #clients, 1, -1 do
        local client = clients[i]
        local data, err = client:receive('*l')
        
        if data then
            local success, slot = process_pet_data(data)
            if success and slot then
                AltPetOverlay.update_slot(slot)
            end
        elseif err == 'closed' then
            client:close()
            table.remove(clients, i)
        end
    end
end

-- Build text content for a pet
local function build_pet_text(owner, pet_data)
    local lines = {}
    table.insert(lines, string.format('\\cs(200,220,255)%s\\cr  \\cs(255,200,120)%s\\cr', owner, pet_data.name))
    
    local job = pet_data.job or 'UNKNOWN'
    
    if job == 'SMN' and (pet_data.bp_rage or pet_data.bp_ward) then
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
    elseif job == 'BST' and pet_data.charges then
        local str = '\\cs(120,255,120)Ready:\\cr '
        for i = 1, 3 do
            if i <= pet_data.charges then
                str = str .. '\\cs(255,220,100)●\\cr'
            else
                str = str .. '\\cs(80,80,80)○\\cr'
            end
            if i < 3 then str = str .. ' ' end
        end
        table.insert(lines, str .. string.format(' \\cs(150,150,150)(%d/3)\\cr', pet_data.charges))
    elseif job == 'DRG' and pet_data.breath_ready ~= nil then
        table.insert(lines, pet_data.breath_ready and '\\cs(120,255,120)Breath Ready\\cr' or '\\cs(150,150,150)Breath: Not Ready\\cr')
    end
    
    return table.concat(lines, '\n')
end

-- Create display for ONE pet
local function create_pet_display(owner, pet_data, index)
    local disp = {}
    
    local pet_y = settings.pos.y + (index * 60)
    local pet_x = settings.pos.x
    
    disp.bg = images.new()
    disp.bg:path(asset_path .. 'BgMid.png')
    disp.bg:pos(pet_x, pet_y)
    disp.bg:size(400, 50)
    disp.bg:color(255, 255, 255, 220)
    disp.bg:draggable(index == 0)
    disp.bg:fit(false)
    disp.bg:show()
    
    if index == 0 then
        drag_reference = disp.bg
    end
    
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
    
    disp.text:text(build_pet_text(owner, pet_data))
    disp.text:show()
    
    local bar_y = pet_y + 32
    local bar_x = pet_x + 8
    
    disp.hp_bg = images.new()
    disp.hp_bg:path(asset_path .. 'BarBG.png')
    disp.hp_bg:pos(bar_x, bar_y)
    disp.hp_bg:size(300, 12)
    disp.hp_bg:color(255, 255, 255, 255)
    disp.hp_bg:draggable(false)
    disp.hp_bg:fit(false)
    disp.hp_bg:show()
    
    local hp_percent = (pet_data.hpp or 100) / 100
    local bar_width = 300 * hp_percent
    
    disp.hp_bar = images.new()
    disp.hp_bar:path(asset_path .. 'Bar.png')
    disp.hp_bar:pos(bar_x, bar_y)
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
    
    disp.hp_bar:draggable(false)
    disp.hp_bar:fit(false)
    disp.hp_bar:show()
    
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

-- Update pet display
local function update_pet_display(disp, pet_data)
    if not disp then return end
    
    if disp.text then
        disp.text:text(build_pet_text(pet_data.owner, pet_data))
    end
    
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
local function delete_pet_display(disp)
    if disp then
        if disp.bg then disp.bg:destroy() end
        if disp.text then disp.text:hide() end
        if disp.hp_bg then disp.hp_bg:destroy() end
        if disp.hp_bar then disp.hp_bar:destroy() end
        if disp.hp_fg then disp.hp_fg:destroy() end
    end
end

-- Update single slot (PUBLIC)
function AltPetOverlay.update_slot(slot)
    if not settings.visible then return end
    
    local pet_data = pet_slots[slot]
    if not pet_data then
        if pet_displays[slot] then
            delete_pet_display(pet_displays[slot])
            pet_displays[slot] = nil
        end
        return
    end
    
    if not pet_displays[slot] then
        pet_displays[slot] = create_pet_display(pet_data.owner, pet_data, slot - 1)
        if slot == 1 then
            drag_reference = pet_displays[slot].bg
        end
    else
        update_pet_display(pet_displays[slot], pet_data)
    end
end

-- Update loop (called by AltControl prerender)
function AltPetOverlay.update()
    if not settings.visible then return end
    check_socket()
end

-- Initialize
function AltPetOverlay.init()
    if init_socket_server() then
        print('[AltPetOverlay] Tool loaded - Socket mode')
        return true
    else
        print('[AltPetOverlay] ERROR: Failed to initialize')
        return false
    end
end

-- Cleanup
function AltPetOverlay.unload()
    for _, client in ipairs(clients) do
        client:close()
    end
    if server then
        server:close()
    end
    for slot, disp in pairs(pet_displays) do
        delete_pet_display(disp)
    end
    settings:save()
    print('[AltPetOverlay] Unloaded')
end

-- Commands (called by AltControl)
function AltPetOverlay.command(cmd, ...)
    local args = {...}
    
    if cmd == 'pos' then
        settings.pos.x = tonumber(args[1]) or settings.pos.x
        settings.pos.y = tonumber(args[2]) or settings.pos.y
        settings:save()
        for slot, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        drag_reference = nil
        for slot = 1, 3 do
            if pet_slots[slot] then
                AltPetOverlay.update_slot(slot)
            end
        end
        print(string.format('[PetOverlay] Position: %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'clear' then
        for slot = 1, 3 do
            pet_slots[slot] = nil
        end
        owner_to_slot = {}
        next_slot = 1
        for slot, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        print('[PetOverlay] Cleared')
    end
end

return AltPetOverlay
