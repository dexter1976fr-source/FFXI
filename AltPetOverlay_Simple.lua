--[[
    AltPetOverlay Simple - Version sans images pour test rapide
    Utilise uniquement texts avec caractères █░ pour les barres
    
    Author: Dexter
    Version: 1.0.0-simple
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0-simple'
_addon.commands = {'petoverlay', 'po'}

-- Windower libraries
local texts = require('texts')
local socket = require('socket')

-- Settings
local settings = {
    pos = {x = 100, y = 400},
    visible = true,
    bg = {alpha = 200, red = 0, green = 0, blue = 0},
    text = {
        font = 'Consolas',
        size = 10,
        alpha = 255,
        red = 255,
        green = 255,
        blue = 255,
        stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0}
    }
}

-- Pet data
local pets = {}

-- Main display
local display_settings = {
    pos = {x = settings.pos.x, y = settings.pos.y},
    bg = {alpha = settings.bg.alpha, red = settings.bg.red, green = settings.bg.green, blue = settings.bg.blue},
    text = {
        font = settings.text.font,
        size = settings.text.size,
        alpha = settings.text.alpha,
        red = settings.text.red,
        green = settings.text.green,
        blue = settings.text.blue
    },
    flags = {bold = false, italic = false},
    stroke = {
        width = settings.text.stroke.width,
        alpha = settings.text.stroke.alpha,
        red = settings.text.stroke.red,
        green = settings.text.stroke.green,
        blue = settings.text.stroke.blue
    }
}

local display = texts.new('AltPetOverlay Loading...', display_settings)
display:show()

-- Update display
function update_display()
    if not settings.visible then
        display:hide()
        return
    end
    
    local output = ""
    local count = 0
    
    for owner, pet_data in pairs(pets) do
        if count > 0 then
            output = output .. "\n"
        end
        
        -- Line 1: Owner → Pet
        output = output .. string.format("%s → %s\n", owner, pet_data.name)
        
        -- Line 2: HP Bar
        local hp_percent = pet_data.hp / pet_data.max_hp
        local bar_length = 30
        local filled = math.floor(bar_length * hp_percent)
        local empty = bar_length - filled
        
        -- Color based on HP
        local hp_bar = ""
        if hp_percent < 0.25 then
            hp_bar = "\\cs(255,100,100)" -- Red
        elseif hp_percent < 0.50 then
            hp_bar = "\\cs(255,180,100)" -- Orange
        elseif hp_percent < 0.75 then
            hp_bar = "\\cs(255,255,100)" -- Yellow
        else
            hp_bar = "\\cs(100,255,100)" -- Green
        end
        
        hp_bar = hp_bar .. string.rep("█", filled) .. "\\cs(100,100,100)" .. string.rep("░", empty)
        hp_bar = hp_bar .. "\\cr " .. string.format("%d/%d", pet_data.hp, pet_data.max_hp)
        
        output = output .. hp_bar .. "\n"
        
        -- Line 3: Job-specific info
        if pet_data.charges then
            -- BST Ready charges
            output = output .. "Ready: "
            for i = 1, 5 do
                if i <= pet_data.charges then
                    output = output .. "\\cs(100,255,100)●\\cr"
                else
                    output = output .. "\\cs(100,100,100)○\\cr"
                end
                if i < 5 then output = output .. " " end
            end
            output = output .. string.format(" (%d/5)", pet_data.charges)
            
        elseif pet_data.bp_timer then
            -- SMN Blood Pact timer
            if pet_data.bp_timer <= 0 then
                output = output .. "\\cs(100,255,100)Blood Pact: Ready\\cr"
            else
                output = output .. string.format("Blood Pact: %.1fs", pet_data.bp_timer)
            end
            
        elseif pet_data.breath_ready ~= nil then
            -- DRG Healing Breath
            if pet_data.breath_ready then
                output = output .. "\\cs(100,255,100)Healing Breath: Ready\\cr"
            else
                output = output .. "Healing Breath: Not Ready"
            end
        end
        
        count = count + 1
    end
    
    if count == 0 then
        output = "\\cs(150,150,150)No pets to display\\cr\n\\cs(150,150,150)Waiting for data...\\cr"
    end
    
    display:text(output)
    display:show()
end

-- Handle IPC messages
windower.register_event('ipc message', function(msg)
    if not msg:startswith('petoverlay_') then return end
    
    local parts = msg:split('_')
    local data = {}
    
    for i = 2, #parts do
        local kv = parts[i]:split(':')
        if #kv == 2 then
            local key = kv[1]
            local value = kv[2]
            local num_value = tonumber(value)
            data[key] = num_value or value
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
        settings.pos.x = tonumber(args[2]) or settings.pos.x
        settings.pos.y = tonumber(args[3]) or settings.pos.y
        display:pos(settings.pos.x, settings.pos.y)
        windower.add_to_chat(122, string.format('[PetOverlay] Position: %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'hide' then
        settings.visible = false
        display:hide()
        windower.add_to_chat(122, '[PetOverlay] Hidden')
        
    elseif cmd == 'show' then
        settings.visible = true
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Shown')
        
    elseif cmd == 'test' then
        pets['Dexterbrown'] = {
            name = 'BlackbeardRandy',
            hp = 650,
            max_hp = 1000,
            charges = 3,
            last_update = socket.gettime()
        }
        pets['Summoner'] = {
            name = 'Ifrit',
            hp = 800,
            max_hp = 1000,
            bp_timer = 2.5,
            last_update = socket.gettime()
        }
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Data cleared')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po pos <x> <y> - Set position')
        windower.add_to_chat(122, '  //po hide - Hide')
        windower.add_to_chat(122, '  //po show - Show')
        windower.add_to_chat(122, '  //po test - Test data')
        windower.add_to_chat(122, '  //po clear - Clear data')
    end
end)

windower.add_to_chat(122, '[AltPetOverlay] Loaded v' .. _addon.version)
windower.add_to_chat(122, '[AltPetOverlay] Type //po test to see demo')

-- Force initial display
coroutine.schedule(function()
    display:text('\\cs(100,255,100)[AltPetOverlay]\\cr\n\\cs(150,150,150)No pets to display\\cr\n\\cs(150,150,150)Type //po test for demo\\cr')
    display:show()
    windower.add_to_chat(122, '[AltPetOverlay] Display initialized at ' .. settings.pos.x .. ',' .. settings.pos.y)
end, 1)
