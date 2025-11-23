--[[
    AltPetOverlay Debug - Version ultra-simple pour debug
]]

_addon.name = 'AltPetOverlay'
_addon.version = '1.0.0-debug'
_addon.commands = {'petoverlay', 'po'}

local socket = require('socket')

-- Pet data
local pets = {}

-- Display text object
local display_text = nil

-- Initialize display
function init_display()
    if display_text then
        windower.text.delete('petoverlay_display')
    end
    
    display_text = windower.text.create('petoverlay_display')
    windower.text.set_location('petoverlay_display', 100, 400)
    windower.text.set_bg_color('petoverlay_display', 200, 0, 0, 0)
    windower.text.set_bg_visibility('petoverlay_display', true)
    windower.text.set_font('petoverlay_display', 'Arial', 12)
    windower.text.set_color('petoverlay_display', 255, 255, 255, 255)
    windower.text.set_text('petoverlay_display', '[AltPetOverlay] Ready\nWaiting for data...\nType //po test')
    windower.text.set_visibility('petoverlay_display', true)
    
    windower.add_to_chat(122, '[PetOverlay] Display created at 100, 400')
end

-- Update display
function update_display()
    if not display_text then return end
    
    local output = "[AltPetOverlay]\n"
    local count = 0
    
    for owner, pet_data in pairs(pets) do
        if count > 0 then
            output = output .. "\n"
        end
        
        -- Owner → Pet
        output = output .. owner .. " -> " .. pet_data.name .. "\n"
        
        -- HP Bar
        local hp_percent = pet_data.hp / pet_data.max_hp
        local bar_length = 30
        local filled = math.floor(bar_length * hp_percent)
        local empty = bar_length - filled
        
        output = output .. string.rep("=", filled) .. string.rep("-", empty)
        output = output .. " " .. pet_data.hp .. "/" .. pet_data.max_hp .. "\n"
        
        -- Charges
        if pet_data.charges then
            output = output .. "Ready: "
            for i = 1, 5 do
                if i <= pet_data.charges then
                    output = output .. "O"
                else
                    output = output .. "o"
                end
                if i < 5 then output = output .. " " end
            end
            output = output .. " (" .. pet_data.charges .. "/5)"
        end
        
        count = count + 1
    end
    
    if count == 0 then
        output = output .. "No pets to display\nType //po test for demo"
    end
    
    windower.text.set_text('petoverlay_display', output)
end

-- IPC Handler
windower.register_event('ipc message', function(msg)
    if not msg:find('^petoverlay_') then return end
    
    local parts = msg:split('_')
    local data = {}
    
    for i = 2, #parts do
        local kv = parts[i]:split(':')
        if #kv == 2 then
            data[kv[1]] = tonumber(kv[2]) or kv[2]
        end
    end
    
    if data.owner and data.pet then
        pets[data.owner] = {
            name = data.pet,
            hp = data.hp or 0,
            max_hp = data.maxhp or 1,
            charges = data.charges,
            last_update = socket.gettime()
        }
        update_display()
    end
end)

-- Cleanup
local last_cleanup = 0
windower.register_event('prerender', function()
    local now = socket.gettime()
    if now - last_cleanup > 5 then
        local changed = false
        for owner, pet_data in pairs(pets) do
            if now - pet_data.last_update > 10 then
                pets[owner] = nil
                changed = true
            end
        end
        if changed then update_display() end
        last_cleanup = now
    end
end)

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'pos' then
        local x = tonumber(args[2]) or 100
        local y = tonumber(args[3]) or 400
        windower.text.set_location('petoverlay_display', x, y)
        windower.add_to_chat(122, '[PetOverlay] Position: ' .. x .. ', ' .. y)
        
    elseif cmd == 'test' then
        pets['Dexterbrown'] = {
            name = 'BlackbeardRandy',
            hp = 650,
            max_hp = 1000,
            charges = 3,
            last_update = socket.gettime()
        }
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    elseif cmd == 'show' then
        windower.text.set_visibility('petoverlay_display', true)
        windower.add_to_chat(122, '[PetOverlay] Shown')
        
    elseif cmd == 'hide' then
        windower.text.set_visibility('petoverlay_display', false)
        windower.add_to_chat(122, '[PetOverlay] Hidden')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po test - Test data')
        windower.add_to_chat(122, '  //po pos <x> <y> - Position')
        windower.add_to_chat(122, '  //po show/hide')
    end
end)

-- Load
windower.register_event('load', function()
    init_display()
end)

-- Unload
windower.register_event('unload', function()
    if display_text then
        windower.text.delete('petoverlay_display')
    end
end)

-- Initialize
init_display()
windower.add_to_chat(122, '[AltPetOverlay] Loaded v' .. _addon.version)
