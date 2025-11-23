--[[
    AltPetOverlay - Version qui marche (copie exacte de la méthode XIVParty)
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0'
_addon.commands = {'petoverlay', 'po'}

-- Imports XIVParty
local uiContainer = require('uiContainer')
local uiImage = require('uiImage')
local uiText = require('uiText')
local utils = require('utils')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    visible = true
}

-- Pet data
local pets = {}
local mainContainer = nil

-- Initialize
function init()
    if mainContainer then
        mainContainer:dispose()
    end
    
    mainContainer = uiContainer:new({
        layout = {
            pos = settings.pos,
            width = 400,
            height = 200
        }
    })
end

-- Create pet UI (méthode XIVParty)
function create_pet_ui(owner, pet_data, index)
    local y_offset = index * 55
    local bar_width = 300
    local bar_height = 12
    
    -- Container pour ce pet
    local container = uiContainer:new({
        layout = {
            pos = {x = 0, y = y_offset},
            width = 400,
            height = 50
        }
    })
    
    -- Background
    local bg = uiImage:new({
        layout = {
            pos = {x = 0, y = 0},
            size = {x = 400, y = 46},
            texture = {
                path = windower.addon_path .. 'assets/xiv/BgMid.png'
            },
            color = utils:colorFromHex('#DCFFFFFF')
        }
    })
    container:addChild(bg)
    
    -- HP Bar Background
    local hpBg = uiImage:new({
        layout = {
            pos = {x = 10, y = 22},
            size = {x = bar_width, y = bar_height},
            texture = {
                path = windower.addon_path .. 'assets/xiv/BarBG.png'
            }
        }
    })
    container:addChild(hpBg)
    
    -- HP Bar (celle qui change de taille)
    local hp_percent = pet_data.hp / pet_data.max_hp
    local hpBar = uiImage:new({
        layout = {
            pos = {x = 10, y = 22},
            size = {x = bar_width * hp_percent, y = bar_height},
            texture = {
                path = windower.addon_path .. 'assets/xiv/Bar.png'
            },
            color = get_hp_color(hp_percent)
        }
    })
    container:addChild(hpBar)
    
    -- HP Bar Foreground
    local hpFg = uiImage:new({
        layout = {
            pos = {x = 10, y = 22},
            size = {x = bar_width, y = bar_height},
            texture = {
                path = windower.addon_path .. 'assets/xiv/BarFG.png'
            },
            color = utils:colorFromHex('#C8FFFFFF')
        }
    })
    container:addChild(hpFg)
    
    -- Owner name
    local ownerText = uiText:new({
        layout = {
            pos = {x = 10, y = 5},
            size = {x = 150, y = 12},
            font = {
                family = 'Arial',
                size = 11
            },
            color = utils:colorFromHex('#C8DCFFFF')
        }
    })
    ownerText:update(owner)
    container:addChild(ownerText)
    
    -- Pet name
    local petText = uiText:new({
        layout = {
            pos = {x = 170, y = 5},
            size = {x = 150, y = 12},
            font = {
                family = 'Arial',
                size = 11
            },
            color = utils:colorFromHex('#FFC878FF')
        }
    })
    petText:update('→ ' .. pet_data.name)
    container:addChild(petText)
    
    -- HP Value
    local hpText = uiText:new({
        layout = {
            pos = {x = 320, y = 22},
            size = {x = 70, y = 12},
            font = {
                family = 'Arial',
                size = 10
            },
            color = utils:colorFromHex('#FFFFFFFF')
        }
    })
    hpText:update(string.format('%d/%d', pet_data.hp, pet_data.max_hp))
    container:addChild(hpText)
    
    -- Job info
    local infoText = uiText:new({
        layout = {
            pos = {x = 10, y = 37},
            size = {x = 380, y = 12},
            font = {
                family = 'Arial',
                size = 10
            },
            color = utils:colorFromHex('#78FF78FF')
        }
    })
    infoText:update(get_job_info(pet_data))
    container:addChild(infoText)
    
    mainContainer:addChild(container)
    
    return {
        container = container,
        hpBar = hpBar,
        hpText = hpText,
        petText = petText,
        infoText = infoText,
        bar_width = bar_width
    }
end

-- Get HP color
function get_hp_color(hp_percent)
    if hp_percent < 0.25 then
        return utils:colorFromHex('#FC8182FF')
    elseif hp_percent < 0.50 then
        return utils:colorFromHex('#F8BA80FF')
    elseif hp_percent < 0.75 then
        return utils:colorFromHex('#F3F37CFF')
    else
        return utils:colorFromHex('#A0F080FF')
    end
end

-- Get job info text
function get_job_info(pet_data)
    if pet_data.charges then
        local str = 'Ready: '
        for i = 1, 5 do
            str = str .. (i <= pet_data.charges and '●' or '○')
            if i < 5 then str = str .. ' ' end
        end
        return str .. string.format(' (%d/5)', pet_data.charges)
    elseif pet_data.bp_timer then
        if pet_data.bp_timer <= 0 then
            return 'BP Ready'
        else
            return string.format('BP: %.1fs', pet_data.bp_timer)
        end
    elseif pet_data.breath_ready ~= nil then
        return pet_data.breath_ready and 'Breath Ready' or 'Breath: Not Ready'
    end
    return ''
end

-- Update pet UI
function update_pet_ui(ui, pet_data)
    if not ui then return end
    
    -- Update HP bar size (méthode XIVParty)
    local hp_percent = pet_data.hp / pet_data.max_hp
    ui.hpBar:size(ui.bar_width * hp_percent, 12)
    ui.hpBar:color(get_hp_color(hp_percent))
    
    -- Update texts
    ui.hpText:update(string.format('%d/%d', pet_data.hp, pet_data.max_hp))
    ui.petText:update('→ ' .. pet_data.name)
    ui.infoText:update(get_job_info(pet_data))
end

-- Rebuild all
function rebuild_all()
    if mainContainer then
        mainContainer:dispose()
    end
    init()
    
    local index = 0
    local pet_uis = {}
    for owner, pet_data in pairs(pets) do
        pet_uis[owner] = create_pet_ui(owner, pet_data, index)
        index = index + 1
    end
    
    return pet_uis
end

local pet_uis = {}

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
        
        pet_uis = rebuild_all()
    end
end)

-- Cleanup
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
            pet_uis = rebuild_all()
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
        pet_uis = rebuild_all()
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
        pet_uis = rebuild_all()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        pet_uis = rebuild_all()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po test')
        windower.add_to_chat(122, '  //po clear')
        windower.add_to_chat(122, '  //po pos <x> <y>')
    end
end)

-- Unload
windower.register_event('unload', function()
    if mainContainer then
        mainContainer:dispose()
    end
end)

-- Init
windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        init()
    end
end)

windower.register_event('login', function()
    init()
end)

windower.add_to_chat(122, '[AltPetOverlay] Loaded (XIVParty method)')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
