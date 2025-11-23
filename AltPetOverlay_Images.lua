--[[
    AltPetOverlay - Version avec images XIVParty
    Utilise les vrais assets graphiques
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0-images'
_addon.commands = {'petoverlay', 'po'}

local texts = require('texts')
local images = require('images')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    visible = true,
    item_height = 50,
    item_width = 400
}

-- Pet data
local pets = {}
local pet_ui = {}

-- Asset paths
local asset_path = windower.addon_path .. 'assets/xiv/'

-- Create UI for one pet
function create_pet_ui(owner, pet_data, index)
    local y = settings.pos.y + (index * settings.item_height)
    local x = settings.pos.x
    
    local ui = {}
    
    -- Background image
    ui.bg = images.new({
        texture = {
            path = asset_path .. 'BgMid.png',
            fit = false
        },
        pos = {x = x, y = y},
        size = {width = settings.item_width, height = 46},
        color = {alpha = 220, red = 255, green = 255, blue = 255},
        draggable = false,
        visible = true
    })
    
    -- HP Bar Background
    ui.hp_bg = images.new({
        texture = {
            path = asset_path .. 'BarBG.png',
            fit = true
        },
        pos = {x = x + 10, y = y + 22},
        size = {width = 300, height = 12},
        color = {alpha = 255, red = 255, green = 255, blue = 255},
        draggable = false,
        visible = true
    })
    
    -- HP Bar
    ui.hp_bar = images.new({
        texture = {
            path = asset_path .. 'Bar.png',
            fit = true
        },
        pos = {x = x + 10, y = y + 22},
        size = {width = 300, height = 12},
        draggable = false,
        visible = true
    })
    
    -- HP Bar Foreground (overlay)
    ui.hp_fg = images.new({
        texture = {
            path = asset_path .. 'BarFG.png',
            fit = true
        },
        pos = {x = x + 10, y = y + 22},
        size = {width = 300, height = 12},
        color = {alpha = 200, red = 255, green = 255, blue = 255},
        draggable = false,
        visible = true
    })
    
    -- Text overlay
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
        bg = {visible = false},
        stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0},
        flags = {bold = false, draggable = false}
    })
    ui.text:show()
    
    return ui
end

-- Update pet UI
function update_pet_ui(ui, owner, pet_data)
    if not ui then return end
    
    -- Update HP bar width
    local hp_percent = pet_data.hp / pet_data.max_hp
    local bar_width = 300 * hp_percent
    ui.hp_bar:size(bar_width, 12)
    
    -- Update HP bar color
    local color = {alpha = 255, red = 160, green = 240, blue = 128}  -- Vert
    if hp_percent < 0.25 then
        color = {alpha = 255, red = 252, green = 129, blue = 130}  -- Rouge
    elseif hp_percent < 0.50 then
        color = {alpha = 255, red = 248, green = 186, blue = 128}  -- Orange
    elseif hp_percent < 0.75 then
        color = {alpha = 255, red = 243, green = 243, blue = 124}  -- Jaune
    end
    ui.hp_bar:color(color.alpha, color.red, color.green, color.blue)
    
    -- Update text
    local text = string.format('\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr', owner, pet_data.name)
    text = text .. string.format('\n                                        %d/%d', pet_data.hp, pet_data.max_hp)
    
    -- Job-specific info
    if pet_data.charges then
        text = text .. '\n\\cs(120,255,120)Ready:\\cr '
        for i = 1, 5 do
            if i <= pet_data.charges then
                text = text .. '\\cs(120,255,120)●\\cr'
            else
                text = text .. '\\cs(80,80,80)○\\cr'
            end
            if i < 5 then text = text .. ' ' end
        end
        text = text .. string.format(' \\cs(150,150,150)(%d/5)\\cr', pet_data.charges)
    elseif pet_data.bp_timer then
        if pet_data.bp_timer <= 0 then
            text = text .. '\n\\cs(120,255,120)BP Ready\\cr'
        else
            text = text .. string.format('\n\\cs(255,200,100)BP: %.1fs\\cr', pet_data.bp_timer)
        end
    elseif pet_data.breath_ready ~= nil then
        if pet_data.breath_ready then
            text = text .. '\n\\cs(120,255,120)Breath Ready\\cr'
        else
            text = text .. '\n\\cs(150,150,150)Breath: Not Ready\\cr'
        end
    end
    
    ui.text:text(text)
end

-- Dispose pet UI
function dispose_pet_ui(ui)
    if not ui then return end
    
    if ui.bg then ui.bg:destroy() end
    if ui.hp_bg then ui.hp_bg:destroy() end
    if ui.hp_bar then ui.hp_bar:destroy() end
    if ui.hp_fg then ui.hp_fg:destroy() end
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
    for owner, ui in pairs(pet_ui) do
        dispose_pet_ui(ui)
    end
end)

windower.add_to_chat(122, '[AltPetOverlay] Images version loaded (XIVParty assets)')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
