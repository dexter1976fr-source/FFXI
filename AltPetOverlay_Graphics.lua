--[[
    AltPetOverlay - Graphical version using primitives
    Style XIVParty mais code simplifié
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0-graphics'
_addon.commands = {'petoverlay', 'po'}

local texts = require('texts')
local socket = require('socket')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    item_height = 55,
    item_width = 400,
    visible = true
}

-- Pet data
local pets = {}
local pet_ui = {}

-- Create UI for one pet
function create_pet_ui(owner, pet_data, index)
    local y = settings.pos.y + (index * settings.item_height)
    local x = settings.pos.x
    
    local ui = {}
    
    -- Background (primitive rectangle)
    ui.bg = windower.prim.create('pet_bg_' .. owner)
    windower.prim.set_position(ui.bg, x, y)
    windower.prim.set_size(ui.bg, settings.item_width, settings.item_height - 5)
    windower.prim.set_color(ui.bg, 220, 20, 20, 30) -- Semi-transparent dark
    windower.prim.set_visibility(ui.bg, true)
    
    -- HP Bar Background
    ui.hp_bg = windower.prim.create('pet_hp_bg_' .. owner)
    windower.prim.set_position(ui.hp_bg, x + 10, y + 20)
    windower.prim.set_size(ui.hp_bg, 300, 12)
    windower.prim.set_color(ui.hp_bg, 255, 40, 40, 40) -- Dark gray
    windower.prim.set_visibility(ui.hp_bg, true)
    
    -- HP Bar
    ui.hp_bar = windower.prim.create('pet_hp_bar_' .. owner)
    windower.prim.set_position(ui.hp_bar, x + 10, y + 20)
    windower.prim.set_size(ui.hp_bar, 300, 12)
    windower.prim.set_visibility(ui.hp_bar, true)
    
    -- Text display
    ui.text = texts.new('', {
        pos = {x = x + 10, y = y + 5},
        text = {
            font = 'Arial',
            size = 11,
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255
        },
        stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0},
        flags = {bold = false}
    })
    ui.text:show()
    
    return ui
end

-- Update pet UI
function update_pet_ui(ui, owner, pet_data)
    if not ui then return end
    
    -- Update HP bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    local bar_width = 300 * hp_percent
    windower.prim.set_size(ui.hp_bar, bar_width, 12)
    
    -- Update HP bar color
    local color = {a = 255, r = 160, g = 240, b = 128} -- Green
    if hp_percent < 0.25 then
        color = {a = 255, r = 252, g = 129, b = 130} -- Red
    elseif hp_percent < 0.50 then
        color = {a = 255, r = 248, g = 186, b = 128} -- Orange
    elseif hp_percent < 0.75 then
        color = {a = 255, r = 243, g = 243, b = 124} -- Yellow
    end
    windower.prim.set_color(ui.hp_bar, color.a, color.r, color.g, color.b)
    
    -- Update text
    local text = string.format("\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr\n", owner, pet_data.name)
    text = text .. string.format("                                    %d/%d\n", pet_data.hp, pet_data.max_hp)
    
    -- Job-specific info
    if pet_data.charges then
        text = text .. "Ready: "
        for i = 1, 5 do
            if i <= pet_data.charges then
                text = text .. "\\cs(120,255,120)●\\cr"
            else
                text = text .. "\\cs(80,80,80)○\\cr"
            end
            if i < 5 then text = text .. " " end
        end
        text = text .. string.format(" (%d/5)", pet_data.charges)
    elseif pet_data.bp_timer then
        if pet_data.bp_timer <= 0 then
            text = text .. "\\cs(120,255,120)BP Ready\\cr"
        else
            text = text .. string.format("BP: %.1fs", pet_data.bp_timer)
        end
    elseif pet_data.breath_ready ~= nil then
        if pet_data.breath_ready then
            text = text .. "\\cs(120,255,120)Breath Ready\\cr"
        else
            text = text .. "Breath: Not Ready"
        end
    end
    
    ui.text:text(text)
end

-- Dispose pet UI
function dispose_pet_ui(ui)
    if not ui then return end
    
    if ui.bg then windower.prim.delete(ui.bg) end
    if ui.hp_bg then windower.prim.delete(ui.hp_bg) end
    if ui.hp_bar then windower.prim.delete(ui.hp_bar) end
    if ui.text then ui.text:hide() end
end

-- Rebuild all UI
function rebuild_all_ui()
    -- Dispose all
    for owner, ui in pairs(pet_ui) do
        dispose_pet_ui(ui)
    end
    pet_ui = {}
    
    -- Create new
    local index = 0
    for owner, pet_data in pairs(pets) do
        pet_ui[owner] = create_pet_ui(owner, pet_data, index)
        update_pet_ui(pet_ui[owner], owner, pet_data)
        index = index + 1
    end
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
            owner = data.owner,
            name = data.pet,
            hp = data.hp or 0,
            max_hp = data.maxhp or 1,
            charges = data.charges,
            bp_timer = data.bp_timer,
            breath_ready = data.breath_ready,
            last_update = socket.gettime()
        }
        
        rebuild_all_ui()
    end
end)

-- Cleanup
local last_cleanup = 0
windower.register_event('prerender', function()
    if not settings.visible then return end
    
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
            last_update = socket.gettime() + 9999
        }
        pets['Summoner'] = {
            owner = 'Summoner',
            name = 'Ifrit',
            hp = 800,
            max_hp = 1000,
            bp_timer = 2.5,
            last_update = socket.gettime() + 9999
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
    for owner, ui in pairs(pet_ui) do
        dispose_pet_ui(ui)
    end
end)

windower.add_to_chat(122, '[AltPetOverlay] Graphics version loaded')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
