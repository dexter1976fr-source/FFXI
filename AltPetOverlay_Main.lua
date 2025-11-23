--[[
    AltPetOverlay - Pet monitoring using XIVParty display code
    Based on XIVParty by Tylas
    Adapted for pet display by Dexter
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter (based on XIVParty by Tylas)'
_addon.version = '1.0.0'
_addon.commands = {'petoverlay', 'po'}

-- Windower library imports
local texts = require('texts')
local socket = require('socket')

-- Simple text display for now
local display_settings = {
    pos = {x = 100, y = 500},
    bg = {alpha = 200, red = 0, green = 0, blue = 0},
    text = {
        font = 'Arial',
        size = 12,
        alpha = 255,
        red = 255,
        green = 255,
        blue = 255
    },
    flags = {bold = false},
    stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0}
}

local display = texts.new('[AltPetOverlay]\nLoading...', display_settings)
display:show()

-- Pet data
local pets = {}

-- Update display
function update_display()
    local output = "\\cs(100,255,100)[AltPetOverlay]\\cr\n"
    local count = 0
    
    for owner, pet_data in pairs(pets) do
        if count > 0 then
            output = output .. "\n"
        end
        
        -- Owner → Pet name
        output = output .. string.format("\\cs(200,200,255)%s\\cr → \\cs(255,200,100)%s\\cr\n", owner, pet_data.name)
        
        -- HP Bar
        local hp_percent = pet_data.hp / pet_data.max_hp
        local bar_length = 30
        local filled = math.floor(bar_length * hp_percent)
        local empty = bar_length - filled
        
        -- Color based on HP
        local color = "100,255,100" -- Green
        if hp_percent < 0.25 then
            color = "255,100,100" -- Red
        elseif hp_percent < 0.50 then
            color = "255,180,100" -- Orange
        elseif hp_percent < 0.75 then
            color = "255,255,100" -- Yellow
        end
        
        output = output .. string.format(
            "\\cs(%s)%s\\cr\\cs(80,80,80)%s\\cr %d/%d\n",
            color,
            string.rep("█", filled),
            string.rep("░", empty),
            pet_data.hp,
            pet_data.max_hp
        )
        
        -- Job-specific info
        if pet_data.charges then
            output = output .. "Ready: "
            for i = 1, 5 do
                if i <= pet_data.charges then
                    output = output .. "\\cs(100,255,100)●\\cr"
                else
                    output = output .. "\\cs(80,80,80)○\\cr"
                end
                if i < 5 then output = output .. " " end
            end
            output = output .. string.format(" (%d/5)", pet_data.charges)
        elseif pet_data.bp_timer then
            if pet_data.bp_timer <= 0 then
                output = output .. "\\cs(100,255,100)BP Ready\\cr"
            else
                output = output .. string.format("BP: %.1fs", pet_data.bp_timer)
            end
        elseif pet_data.breath_ready ~= nil then
            if pet_data.breath_ready then
                output = output .. "\\cs(100,255,100)Breath Ready\\cr"
            else
                output = output .. "Breath: Not Ready"
            end
        end
        
        count = count + 1
    end
    
    if count == 0 then
        output = output .. "\\cs(150,150,150)No pets to display\\cr\n"
        output = output .. "\\cs(150,150,150)Waiting for data from alts...\\cr"
    end
    
    display:text(output)
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
            bp_timer = data.bp_timer,
            breath_ready = data.breath_ready,
            last_update = socket.gettime()
        }
        
        update_display()
    end
end)

-- Cleanup old data
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
        if changed then
            update_display()
        end
        last_cleanup = now
    end
end)

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'pos' then
        display_settings.pos.x = tonumber(args[2]) or display_settings.pos.x
        display_settings.pos.y = tonumber(args[3]) or display_settings.pos.y
        display:pos(display_settings.pos.x, display_settings.pos.y)
        windower.add_to_chat(122, string.format('[PetOverlay] Position: %d, %d', display_settings.pos.x, display_settings.pos.y))
        
    elseif cmd == 'test' then
        pets['Dexterbrown'] = {
            name = 'BlackbeardRandy',
            hp = 650,
            max_hp = 1000,
            charges = 3,
            last_update = socket.gettime() + 9999 -- Ne pas expirer
        }
        pets['Summoner'] = {
            name = 'Ifrit',
            hp = 800,
            max_hp = 1000,
            bp_timer = 2.5,
            last_update = socket.gettime() + 9999 -- Ne pas expirer
        }
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Test data added (permanent)')
        
    elseif cmd == 'clear' then
        pets = {}
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    elseif cmd == 'hide' then
        display:hide()
        windower.add_to_chat(122, '[PetOverlay] Hidden')
        
    elseif cmd == 'show' then
        display:show()
        windower.add_to_chat(122, '[PetOverlay] Shown')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po pos <x> <y> - Set position')
        windower.add_to_chat(122, '  //po test - Test data')
        windower.add_to_chat(122, '  //po clear - Clear')
        windower.add_to_chat(122, '  //po hide/show')
    end
end)

-- Initialize
windower.add_to_chat(122, '[AltPetOverlay] Loaded v' .. _addon.version)
windower.add_to_chat(122, '[AltPetOverlay] Type //po test to see demo')
update_display()
