--[[
    AltPetOverlay - VERSION FINALE
    Copie EXACTE de la méthode XIVParty pour les barres
]]

_addon.name = 'AltPetOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0'
_addon.commands = {'petoverlay', 'po'}

local texts = require('texts')
local images = require('images')

-- Settings
local settings = {
    pos = {x = 100, y = 500},
    visible = true
}

-- Pet data
local pets = {}
local pet_displays = {}

-- Asset path
local asset_path = windower.addon_path .. 'assets/xiv/'

-- Text display (sans background pour voir les barres)
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
    bg = {visible = false},  -- Pas de background pour voir les barres PNG
    padding = 8,
    stroke = {width = 2, alpha = 200, red = 0, green = 0, blue = 0},
    flags = {bold = false, draggable = false}
})

-- Create pet display (MÉTHODE XIVPARTY EXACTE)
function create_pet_display(owner, pet_data, index)
    -- CHAQUE PET = 3 lignes compactes (nom, barre, info)
    -- Hauteur d'une ligne = 12px (plus compact)
    -- Hauteur totale d'un pet = 3 * 12 + 8 espace = 44px
    
    local line_height = 12
    local pet_block_height = (line_height * 3) + 8  -- 44px par pet
    
    -- Position de départ pour ce pet
    local pet_start_y = settings.pos.y + 8 + (index * pet_block_height)
    local x_offset = settings.pos.x + 8
    
    -- Position de la barre = ligne 3 (après nom et Ready)
    local bar_y = pet_start_y + (line_height * 2) + 6  -- Après 2 lignes + 6px de marge
    
    local disp = {}
    
    -- Background (BgMid.png) - un par pet (réduit de 5px)
    disp.bg = images.new()
    disp.bg:path(asset_path .. 'BgMid.png')
    disp.bg:pos(settings.pos.x, pet_start_y - 2)
    disp.bg:size(400, 45)  -- Réduit de 50 à 45px
    disp.bg:color(255, 255, 255, 220)
    disp.bg:draggable(false)
    disp.bg:fit(false)
    disp.bg:show()
    
    -- HP Bar Background (BarBG.png)
    disp.hp_bg = images.new()
    disp.hp_bg:path(asset_path .. 'BarBG.png')
    disp.hp_bg:pos(x_offset, bar_y)
    disp.hp_bg:size(300, 12)
    disp.hp_bg:color(255, 255, 255, 255)
    disp.hp_bg:draggable(false)
    disp.hp_bg:fit(false)
    disp.hp_bg:show()
    
    -- HP Bar (Bar.png) - celle qui change (taille initiale sera mise à jour)
    local hp_percent = pet_data.hp / pet_data.max_hp
    local bar_width = 300 * hp_percent
    
    disp.hp_bar = images.new()
    disp.hp_bar:path(asset_path .. 'Bar.png')
    disp.hp_bar:pos(x_offset, bar_y)
    disp.hp_bar:size(bar_width, 12)  -- Taille correcte dès le début
    
    -- Couleur selon HP%
    if hp_percent < 0.25 then
        disp.hp_bar:color(252, 129, 130, 255)  -- Rouge
    elseif hp_percent < 0.50 then
        disp.hp_bar:color(248, 186, 128, 255)  -- Orange
    elseif hp_percent < 0.75 then
        disp.hp_bar:color(243, 243, 124, 255)  -- Jaune
    else
        disp.hp_bar:color(160, 240, 128, 255)  -- Vert
    end
    
    disp.hp_bar:draggable(false)
    disp.hp_bar:fit(false)
    disp.hp_bar:show()
    
    -- HP Bar Foreground (BarFG.png)
    disp.hp_fg = images.new()
    disp.hp_fg:path(asset_path .. 'BarFG.png')
    disp.hp_fg:pos(x_offset, bar_y)
    disp.hp_fg:size(300, 12)
    disp.hp_fg:color(255, 255, 255, 200)
    disp.hp_fg:draggable(false)
    disp.hp_fg:fit(false)
    disp.hp_fg:show()
    
    return disp
end

-- Update pet display
function update_pet_display(disp, pet_data)
    if not disp then return end
    
    local hp_percent = pet_data.hp / pet_data.max_hp
    local bar_width = 300 * hp_percent
    
    -- Update bar size (MÉTHODE XIVPARTY)
    disp.hp_bar:size(bar_width, 12)
    
    -- Update color
    if hp_percent < 0.25 then
        disp.hp_bar:color(252, 129, 130, 255)  -- Rouge
    elseif hp_percent < 0.50 then
        disp.hp_bar:color(248, 186, 128, 255)  -- Orange
    elseif hp_percent < 0.75 then
        disp.hp_bar:color(243, 243, 124, 255)  -- Jaune
    else
        disp.hp_bar:color(160, 240, 128, 255)  -- Vert
    end
end

-- Delete pet display
function delete_pet_display(disp)
    if disp then
        if disp.bg then disp.bg:destroy() end
        if disp.hp_bg then disp.hp_bg:destroy() end
        if disp.hp_bar then disp.hp_bar:destroy() end
        if disp.hp_fg then disp.hp_fg:destroy() end
    end
end

-- Update all
function update_all()
    if not settings.visible then
        display:hide()
        for owner, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        return
    end
    
    -- Clear old displays
    for owner, disp in pairs(pet_displays) do
        if not pets[owner] then
            delete_pet_display(disp)
            pet_displays[owner] = nil
        end
    end
    
    -- Build text - CHAQUE PET EST INDÉPENDANT
    local lines = {}
    
    local index = 0
    for owner, pet_data in pairs(pets) do
        -- Ligne 1: Owner → Pet
        table.insert(lines, string.format('\\cs(200,220,255)%s\\cr → \\cs(255,200,120)%s\\cr', owner, pet_data.name))
        
        -- Ligne 2: Job info (Ready juste sous le nom)
        if pet_data.charges then
            local str = '\\cs(120,255,120)Ready:\\cr '
            for i = 1, 5 do
                str = str .. (i <= pet_data.charges and '\\cs(120,255,120)●\\cr' or '\\cs(80,80,80)○\\cr')
                if i < 5 then str = str .. ' ' end
            end
            table.insert(lines, str .. string.format(' \\cs(150,150,150)(%d/5)\\cr', pet_data.charges))
        elseif pet_data.bp_timer then
            if pet_data.bp_timer <= 0 then
                table.insert(lines, '\\cs(120,255,120)BP Ready\\cr')
            else
                table.insert(lines, string.format('\\cs(255,200,100)BP: %.1fs\\cr', pet_data.bp_timer))
            end
        elseif pet_data.breath_ready ~= nil then
            table.insert(lines, pet_data.breath_ready and '\\cs(120,255,120)Breath Ready\\cr' or '\\cs(150,150,150)Breath: Not Ready\\cr')
        end
        
        -- Ligne 3: Espace pour la barre (ligne vide)
        table.insert(lines, '')
        
        -- Ligne 4: Espace entre pets
        table.insert(lines, '')
        
        -- Create or update display APRÈS avoir construit le texte
        if not pet_displays[owner] then
            pet_displays[owner] = create_pet_display(owner, pet_data, index)
        end
        update_pet_display(pet_displays[owner], pet_data)
        
        index = index + 1
    end
    
    if index == 0 then
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
        update_all()
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
        if changed then update_all() end
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
        for owner, disp in pairs(pet_displays) do
            delete_pet_display(disp)
        end
        pet_displays = {}
        update_all()
        windower.add_to_chat(122, string.format('[PetOverlay] Position: %d, %d', settings.pos.x, settings.pos.y))
        
    elseif cmd == 'test' then
        -- DEUX PETS pour vérifier que le 2ème est identique au 1er
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
        update_all()
        windower.add_to_chat(122, '[PetOverlay] Test data added (2 pets)')
        
    elseif cmd == 'clear' then
        pets = {}
        update_all()
        windower.add_to_chat(122, '[PetOverlay] Cleared')
        
    else
        windower.add_to_chat(122, '[PetOverlay] Commands: //po test | //po clear | //po pos <x> <y>')
    end
end)

-- Unload
windower.register_event('unload', function()
    display:hide()
    for owner, disp in pairs(pet_displays) do
        delete_pet_display(disp)
    end
end)

-- Init
update_all()
windower.add_to_chat(122, '[AltPetOverlay] FINAL version loaded (XIVParty PNG bars)')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test')
