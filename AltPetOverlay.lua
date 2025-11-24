--[[
    AltPetOverlay - Pet monitoring overlay for FFXI Alt Control
    Displays pet HP and job-specific info (BST charges, SMN BP timer, etc.)
    Designed to complement XIVParty
    
    Author: Dexter
    Version: 1.0.0
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0'
_addon.commands = {'petoverlay', 'po'}

-- Windower libraries
local images = require('images')
local texts = require('texts')
local socket = require('socket')

-- Settings (matching XIVParty style)
local settings = {
    pos = {x = 100, y = 400}, -- Position on screen
    scale = 1.0,
    visible = true,
    
    -- Colors (matching XIVParty)
    colors = {
        bg = {a = 220, r = 0, g = 0, b = 0},
        hp_green = {a = 255, r = 100, g = 255, b = 100},
        hp_yellow = {a = 255, r = 243, g = 243, b = 124},
        hp_orange = {a = 255, r = 248, g = 186, b = 128},
        hp_red = {a = 255, r = 252, g = 129, b = 130},
        text = {a = 240, r = 255, g = 255, b = 255},
        charge_ready = {a = 255, r = 100, g = 255, b = 100},
        charge_not_ready = {a = 100, r = 100, g = 100, b = 100}
    },
    
    -- Layout
    item_height = 50,
    item_width = 400,
    item_spacing = 5,
    
    -- Font
    font = 'Arial',
    font_size = 10
}

-- Pet data storage
local pets = {}

-- UI Elements
local ui_elements = {}

-- Initialize
function initialize()
    windower.add_to_chat(122, '[AltPetOverlay] Loaded v' .. _addon.version)
    windower.add_to_chat(122, '[AltPetOverlay] Use //po pos <x> <y> to set position')
end

-- Create UI for a pet
function create_pet_ui(owner, pet_data, index)
    local y_offset = (index - 1) * (settings.item_height + settings.item_spacing)
    local base_x = settings.pos.x
    local base_y = settings.pos.y + y_offset
    
    local ui = {
        owner = owner,
        index = index
    }
    
    -- Background
    ui.bg = images.new()
    ui.bg:path(windower.addon_path .. 'assets/bg.png')
    ui.bg:pos(base_x, base_y)
    ui.bg:size(settings.item_width, settings.item_height)
    ui.bg:color(settings.colors.bg.a, settings.colors.bg.r, settings.colors.bg.g, settings.colors.bg.b)
    ui.bg:show()
    
    -- Owner → Pet name text
    ui.name_text = texts.new({
        pos = {x = base_x + 10, y = base_y + 5},
        text = {
            font = settings.font,
            size = settings.font_size,
            alpha = settings.colors.text.a,
            red = settings.colors.text.r,
            green = settings.colors.text.g,
            blue = settings.colors.text.b
        },
        flags = {bold = true}
    })
    ui.name_text:text(string.format("%s → %s", owner, pet_data.name))
    ui.name_text:show()
    
    -- HP Bar background
    ui.hp_bg = images.new()
    ui.hp_bg:path(windower.addon_path .. 'assets/bar_bg.png')
    ui.hp_bg:pos(base_x + 10, base_y + 20)
    ui.hp_bg:size(300, 12)
    ui.hp_bg:color(100, 50, 50, 50)
    ui.hp_bg:show()
    
    -- HP Bar
    ui.hp_bar = images.new()
    ui.hp_bar:path(windower.addon_path .. 'assets/bar.png')
    ui.hp_bar:pos(base_x + 10, base_y + 20)
    ui.hp_bar:size(300, 12)
    ui.hp_bar:show()
    
    -- HP Text
    ui.hp_text = texts.new({
        pos = {x = base_x + 320, y = base_y + 18},
        text = {
            font = settings.font,
            size = settings.font_size - 1,
            alpha = settings.colors.text.a,
            red = settings.colors.text.r,
            green = settings.colors.text.g,
            blue = settings.colors.text.b
        }
    })
    ui.hp_text:show()
    
    -- Job-specific info text
    ui.info_text = texts.new({
        pos = {x = base_x + 10, y = base_y + 35},
        text = {
            font = settings.font,
            size = settings.font_size - 1,
            alpha = settings.colors.text.a,
            red = settings.colors.text.r,
            green = settings.colors.text.g,
            blue = settings.colors.text.b
        }
    })
    ui.info_text:show()
    
    return ui
end

-- Update pet UI
function update_pet_ui(ui, pet_data)
    if not ui then return end
    
    -- Update HP bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    local bar_width = 300 * hp_percent
    ui.hp_bar:size(bar_width, 12)
    
    -- Update HP bar color based on percentage
    local color = settings.colors.hp_green
    if hp_percent < 0.25 then
        color = settings.colors.hp_red
    elseif hp_percent < 0.50 then
        color = settings.colors.hp_orange
    elseif hp_percent < 0.75 then
        color = settings.colors.hp_yellow
    end
    ui.hp_bar:color(color.a, color.r, color.g, color.b)
    
    -- Update HP text
    ui.hp_text:text(string.format("%d/%d", pet_data.hp, pet_data.max_hp))
    
    -- Update job-specific info
    local info_str = ""
    
    if pet_data.charges then
        -- BST Ready charges
        info_str = "Ready: "
        for i = 1, 5 do
            if i <= pet_data.charges then
                info_str = info_str .. "●"
            else
                info_str = info_str .. "○"
            end
            if i < 5 then info_str = info_str .. " " end
        end
        info_str = info_str .. string.format(" (%d/5)", pet_data.charges)
        
    elseif pet_data.bp_timer then
        -- SMN Blood Pact timer
        if pet_data.bp_timer <= 0 then
            info_str = "Blood Pact: Ready"
        else
            info_str = string.format("Blood Pact: %.1fs", pet_data.bp_timer)
        end
        
    elseif pet_data.breath_ready ~= nil then
        -- DRG Healing Breath
        if pet_data.breath_ready then
            info_str = "Healing Breath: Ready"
        else
            info_str = "Healing Breath: Not Ready"
        end
    end
    
    ui.info_text:text(info_str)
end

-- Dispose pet UI
function dispose_pet_ui(ui)
    if not ui then return end
    
    if ui.bg then ui.bg:hide() end
    if ui.name_text then ui.name_text:hide() end
    if ui.hp_bg then ui.hp_bg:hide() end
    if ui.hp_bar then ui.hp_bar:hide() end
    if ui.hp_text then ui.hp_text:hide() end
    if ui.info_text then ui.info_text:hide() end
end

-- Rebuild all UI
function rebuild_ui()
    -- Dispose all existing UI
    for owner, ui in pairs(ui_elements) do
        dispose_pet_ui(ui)
    end
    ui_elements = {}
    
    -- Create UI for each pet
    local index = 1
    for owner, pet_data in pairs(pets) do
        ui_elements[owner] = create_pet_ui(owner, pet_data, index)
        update_pet_ui(ui_elements[owner], pet_data)
        index = index + 1
    end
end

-- Handle IPC messages from AltControl
windower.register_event('ipc message', function(msg)
    if not msg:startswith('petoverlay_') then return end
    
    -- Parse message: "petoverlay_owner:Name_pet:PetName_hp:650_maxhp:1000_charges:3"
    local parts = msg:split('_')
    
    local data = {}
    for i = 2, #parts do
        local kv = parts[i]:split(':')
        if #kv == 2 then
            local key = kv[1]
            local value = kv[2]
            
            -- Try to convert to number
            local num_value = tonumber(value)
            data[key] = num_value or value
        end
    end
    
    if data.owner and data.pet then
        -- 🆕 Si pet = "NOPET", retirer le pet de l'affichage
        if data.pet == 'NOPET' then
            if pets[data.owner] then
                pets[data.owner] = nil
                rebuild_ui()
            end
            return
        end
        
        -- Update or create pet data
        pets[data.owner] = {
            name = data.pet,
            hp = data.hp or 0,
            max_hp = data.maxhp or 1,
            charges = data.charges,
            bp_timer = data.bp_timer,
            breath_ready = data.breath_ready,
            last_update = socket.gettime()
        }
        
        -- Rebuild UI
        rebuild_ui()
    end
end)

-- Cleanup old pet data
local last_cleanup = 0
windower.register_event('prerender', function()
    if not settings.visible then return end
    
    local now = socket.gettime()
    
    -- Cleanup every 5 seconds
    if now - last_cleanup > 5 then
        local changed = false
        
        for owner, pet_data in pairs(pets) do
            -- Remove if not updated in 10 seconds
            if now - pet_data.last_update > 10 then
                pets[owner] = nil
                changed = true
            end
        end
        
        if changed then
            rebuild_ui()
        end
        
        last_cleanup = now
    end
end)

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'pos' then
        settings.pos.x = tonumber(args[2]) or settings.pos.x
        settings.pos.y = tonumber(args[3]) or settings.pos.y
        rebuild_ui()
        windower.add_to_chat(122, string.format('[AltPetOverlay] Position set to %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'hide' then
        settings.visible = false
        for owner, ui in pairs(ui_elements) do
            dispose_pet_ui(ui)
        end
        windower.add_to_chat(122, '[AltPetOverlay] Hidden')
        
    elseif cmd == 'show' then
        settings.visible = true
        rebuild_ui()
        windower.add_to_chat(122, '[AltPetOverlay] Shown')
        
    elseif cmd == 'reload' then
        rebuild_ui()
        windower.add_to_chat(122, '[AltPetOverlay] Reloaded')
        
    elseif cmd == 'test' then
        -- Test data
        pets['TestOwner'] = {
            name = 'TestPet',
            hp = 650,
            max_hp = 1000,
            charges = 3,
            last_update = socket.gettime()
        }
        rebuild_ui()
        windower.add_to_chat(122, '[AltPetOverlay] Test data added')
        
    else
        windower.add_to_chat(122, '[AltPetOverlay] Commands:')
        windower.add_to_chat(122, '  //po pos <x> <y> - Set position')
        windower.add_to_chat(122, '  //po hide - Hide overlay')
        windower.add_to_chat(122, '  //po show - Show overlay')
        windower.add_to_chat(122, '  //po reload - Reload UI')
        windower.add_to_chat(122, '  //po test - Add test data')
    end
end)

-- Initialize on load
initialize()
