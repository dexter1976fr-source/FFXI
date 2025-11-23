--[[
    AltPetOverlay - Version XIVParty Style (vraie)
    Utilise les vrais composants UI de XIVParty
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0-xiv'
_addon.commands = {'petoverlay', 'po'}

require('luau')

-- Load XIVParty UI components
local uiContainer = require('uiContainer')
local uiBackground = require('uiBackground')
local uiBar = require('uiBar')
local uiText = require('uiText')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    item_height = 50,
    item_width = 400,
    visible = true
}

-- Pet data
local pets = {}
local pet_uis = {}

-- Main container
local mainContainer = nil

-- Initialize
function init()
    mainContainer = uiContainer:new({
        layout = {
            pos = {x = settings.pos.x, y = settings.pos.y},
            width = settings.item_width,
            height = 200
        }
    })
end

-- Create UI for one pet
function create_pet_ui(owner, pet_data, index)
    local y_offset = index * settings.item_height
    
    local container = uiContainer:new({
        layout = {
            pos = {x = 0, y = y_offset},
            width = settings.item_width,
            height = settings.item_height - 5
        }
    })
    
    -- Background
    local bg = uiBackground:new({
        layout = {
            pos = {x = 0, y = 0},
            width = settings.item_width,
            height = settings.item_height - 5
        },
        color = {a = 220, r = 20, g = 20, b = 30}
    })
    container:add(bg)
    
    -- Owner name text
    local ownerText = uiText:new({
        layout = {
            pos = {x = 10, y = 5},
            width = 150,
            height = 12
        },
        text = owner,
        font = {
            family = 'Arial',
            size = 11,
            color = {a = 255, r = 200, g = 220, b = 255},
            stroke = {width = 2, alpha = 200, r = 0, g = 0, b = 0}
        }
    })
    container:add(ownerText)
    
    -- Pet name text
    local petText = uiText:new({
        layout = {
            pos = {x = 170, y = 5},
            width = 150,
            height = 12
        },
        text = '→ ' .. pet_data.name,
        font = {
            family = 'Arial',
            size = 11,
            color = {a = 255, r = 255, g = 200, b = 120},
            stroke = {width = 2, alpha = 200, r = 0, g = 0, b = 0}
        }
    })
    container:add(petText)
    
    -- HP Bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    local hpBar = uiBar:new({
        layout = {
            pos = {x = 10, y = 22},
            width = 300,
            height = 12
        },
        value = hp_percent,
        color = get_hp_color(hp_percent)
    })
    container:add(hpBar)
    
    -- HP Value text
    local hpText = uiText:new({
        layout = {
            pos = {x = 320, y = 22},
            width = 70,
            height = 12
        },
        text = string.format('%d/%d', pet_data.hp, pet_data.max_hp),
        font = {
            family = 'Arial',
            size = 10,
            color = {a = 255, r = 255, g = 255, b = 255},
            stroke = {width = 2, alpha = 200, r = 0, g = 0, b = 0}
        }
    })
    container:add(hpText)
    
    -- Job-specific info text
    local infoText = uiText:new({
        layout = {
            pos = {x = 10, y = 37},
            width = 380,
            height = 12
        },
        text = get_job_info_text(pet_data),
        font = {
            family = 'Arial',
            size = 10,
            color = {a = 255, r = 120, g = 255, b = 120},
            stroke = {width = 2, alpha = 200, r = 0, g = 0, b = 0}
        }
    })
    container:add(infoText)
    
    mainContainer:add(container)
    
    return {
        container = container,
        ownerText = ownerText,
        petText = petText,
        hpBar = hpBar,
        hpText = hpText,
        infoText = infoText
    }
end

-- Get HP bar color based on percentage
function get_hp_color(hp_percent)
    if hp_percent < 0.25 then
        return {a = 255, r = 252, g = 129, b = 130} -- Red
    elseif hp_percent < 0.50 then
        return {a = 255, r = 248, g = 186, b = 128} -- Orange
    elseif hp_percent < 0.75 then
        return {a = 255, r = 243, g = 243, b = 124} -- Yellow
    else
        return {a = 255, r = 160, g = 240, b = 128} -- Green
    end
end

-- Get job-specific info text
function get_job_info_text(pet_data)
    if pet_data.charges then
        local ready_str = 'Ready: '
        for i = 1, 5 do
            if i <= pet_data.charges then
                ready_str = ready_str .. '●'
            else
                ready_str = ready_str .. '○'
            end
            if i < 5 then ready_str = ready_str .. ' ' end
        end
        return ready_str .. string.format(' (%d/5)', pet_data.charges)
    elseif pet_data.bp_timer then
        if pet_data.bp_timer <= 0 then
            return 'BP Ready'
        else
            return string.format('BP: %.1fs', pet_data.bp_timer)
        end
    elseif pet_data.breath_ready ~= nil then
        if pet_data.breath_ready then
            return 'Breath Ready'
        else
            return 'Breath: Not Ready'
        end
    end
    return ''
end

-- Update pet UI
function update_pet_ui(ui, owner, pet_data)
    if not ui then return end
    
    -- Update pet name
    ui.petText:setText('→ ' .. pet_data.name)
    
    -- Update HP bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    ui.hpBar:setValue(hp_percent)
    ui.hpBar:setColor(get_hp_color(hp_percent))
    
    -- Update HP text
    ui.hpText:setText(string.format('%d/%d', pet_data.hp, pet_data.max_hp))
    
    -- Update job info
    ui.infoText:setText(get_job_info_text(pet_data))
end

-- Dispose pet UI
function dispose_pet_ui(ui)
    if not ui then return end
    
    if ui.container then
        mainContainer:remove(ui.container)
        ui.container:dispose()
    end
end

-- Rebuild all UI
function rebuild_all_ui()
    -- Dispose all
    for owner, ui in pairs(pet_uis) do
        dispose_pet_ui(ui)
    end
    pet_uis = {}
    
    -- Recreate main container
    if mainContainer then
        mainContainer:dispose()
    end
    init()
    
    -- Create new
    local index = 0
    for owner, pet_data in pairs(pets) do
        pet_uis[owner] = create_pet_ui(owner, pet_data, index)
        index = index + 1
    end
    
    -- Adjust container height
    if mainContainer then
        mainContainer:setHeight(index * settings.item_height)
    end
end

-- IPC Handler
windower.register_event('ipc message', function(msg)
    if not msg:find('^petoverlay_') then return end
    
    local data = {}
    for key, value in msg:gmatch('(%w+):([^_]+)') do
        data[key] = tonumber(value) or value
    end
    
    if data.owner and data.pet then
        pets[data.owner] = {
            owner = data.owner,
            name = data.pet,
            hp = tonumber(data.hp) or 0,
            max_hp = tonumber(data.maxhp) or 1,
            charges = tonumber(data.charges),
            bp_timer = tonumber(data.bp_timer),
            breath_ready = data.breath_ready == 'true',
            last_update = os.clock()
        }
        
        rebuild_all_ui()
    end
end)

-- Cleanup old pets
local last_cleanup = 0
windower.register_event('prerender', function()
    if not settings.visible then return end
    
    local now = os.clock()
    if now - last_cleanup > 5 then
        local changed = false
        for owner, pet_data in pairs(pets) do
            if now - pet_data.last_update > 10 then
                pets[owner] = nil
                changed = true
            end
        end
        if changed then
            rebuild_all_ui()
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
        rebuild_all_ui()
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
        rebuild_all_ui()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        rebuild_all_ui()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po pos <x> <y>')
        windower.add_to_chat(122, '  //po test')
        windower.add_to_chat(122, '  //po clear')
    end
end)

-- Unload
windower.register_event('unload', function()
    if mainContainer then
        mainContainer:dispose()
    end
end)

-- Initialize on load
init()
windower.add_to_chat(122, '[AltPetOverlay] XIVParty style loaded')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
