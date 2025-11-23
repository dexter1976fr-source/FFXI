--[[
    AltPetOverlay - Version minimale (texte seulement)
    Pour debug si la version graphique ne marche pas
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0-minimal'
_addon.commands = {'petoverlay', 'po'}

local texts = require('texts')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    visible = true
}

-- Pet data
local pets = {}

-- Text display (style XIVParty)
local display = texts.new('', {
    pos = {x = settings.pos.x, y = settings.pos.y},
    text = {
        font = 'Arial',
        size = 11,
        alpha = 255,
        red = 255,
        green = 255,
        blue = 255
    },
    bg = {
        alpha = 220,
        red = 20,
        green = 20,
        blue = 30
    },
    padding = 8,
    stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0},
    flags = {bold = false, draggable = false}
})

-- Update display (style XIVParty avec couleurs)
function update_display()
    if not settings.visible then
        display:hide()
        return
    end
    
    local lines = {}
    table.insert(lines, '\\cs(150,200,255)═══ Pet Overlay ═══\\cr')
    
    local count = 0
    for owner, pet_data in pairs(pets) do
        count = count + 1
        
        -- Owner → Pet (avec couleurs)
        table.insert(lines, string.format('\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr', owner, pet_data.name))
        
        -- HP avec barre colorée
        local hp_percent = pet_data.hp / pet_data.max_hp * 100
        local hp_color = '160,240,128' -- Vert
        if hp_percent < 25 then
            hp_color = '252,129,130' -- Rouge
        elseif hp_percent < 50 then
            hp_color = '248,186,128' -- Orange
        elseif hp_percent < 75 then
            hp_color = '243,243,124' -- Jaune
        end
        
        -- Barre HP visuelle
        local bar_length = 20
        local filled = math.floor(bar_length * hp_percent / 100)
        local bar = string.rep('█', filled) .. string.rep('░', bar_length - filled)
        table.insert(lines, string.format('  \\cs(%s)%s\\cr %d/%d', hp_color, bar, pet_data.hp, pet_data.max_hp))
        
        -- Job-specific info
        if pet_data.charges then
            local ready_str = '  \\cs(120,255,120)Ready:\\cr '
            for i = 1, 5 do
                if i <= pet_data.charges then
                    ready_str = ready_str .. '\\cs(120,255,120)●\\cr'
                else
                    ready_str = ready_str .. '\\cs(80,80,80)○\\cr'
                end
                if i < 5 then ready_str = ready_str .. ' ' end
            end
            ready_str = ready_str .. string.format(' \\cs(150,150,150)(%d/5)\\cr', pet_data.charges)
            table.insert(lines, ready_str)
        elseif pet_data.bp_timer then
            if pet_data.bp_timer <= 0 then
                table.insert(lines, '  \\cs(120,255,120)BP Ready\\cr')
            else
                table.insert(lines, string.format('  \\cs(255,200,100)BP: %.1fs\\cr', pet_data.bp_timer))
            end
        elseif pet_data.breath_ready ~= nil then
            if pet_data.breath_ready then
                table.insert(lines, '  \\cs(120,255,120)Breath Ready\\cr')
            else
                table.insert(lines, '  \\cs(150,150,150)Breath: Not Ready\\cr')
            end
        end
        
        table.insert(lines, '')  -- Ligne vide
    end
    
    if count == 0 then
        table.insert(lines, '\\cs(150,150,150)No pets active\\cr')
        table.insert(lines, '\\cs(150,150,150)Type //po test\\cr')
    end
    
    display:text(table.concat(lines, '\n'))
    display:show()
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
        
        update_display()
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
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Test data added')
        
    elseif cmd == 'clear' then
        pets = {}
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    elseif cmd == 'show' then
        settings.visible = true
        update_display()
        windower.add_to_chat(122, '[PetOverlay] Shown')
        
    elseif cmd == 'hide' then
        settings.visible = false
        display:hide()
        windower.add_to_chat(122, '[PetOverlay] Hidden')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po test')
        windower.add_to_chat(122, '  //po clear')
        windower.add_to_chat(122, '  //po pos <x> <y>')
        windower.add_to_chat(122, '  //po show')
        windower.add_to_chat(122, '  //po hide')
    end
end)

-- Unload
windower.register_event('unload', function()
    display:hide()
end)

-- Initialize
update_display()
windower.add_to_chat(122, '[AltPetOverlay] Minimal version loaded')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
