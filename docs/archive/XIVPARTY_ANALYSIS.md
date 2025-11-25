# 🎨 XIVParty - Analyse pour Inspiration Overlay

## 🎯 Qu'est-ce que XIVParty ?

Un addon Windower qui affiche une **party list moderne** style FFXIV, avec HP/MP/TP bars, buffs, et job icons.

---

## 🏗️ Architecture XIVParty

```
┌─────────────────────────────────────────┐
│  xivparty.lua (Main)                    │
│  - Init & Events                        │
│  - Prerender loop                       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  model.lua (Data)                       │
│  - Players data                         │
│  - Party/Alliance tracking              │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  uiView.lua (Display)                   │
│  - Rendering                            │
│  - Layout management                    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  UI Components                          │
│  - uiBar.lua (HP/MP bars)              │
│  - uiText.lua (Names, values)          │
│  - uiBuffIcons.lua (Buff display)      │
│  - uiJobIcon.lua (Job icons)           │
└─────────────────────────────────────────┘
```

---

## 📊 Points Clés à Réutiliser

### 1. Prerender Loop (60 FPS)

```lua
-- xivparty.lua
windower.register_event('prerender', function()
    if isZoning or not isInitialized then return end

    local timeMsec = socket.gettime() * 1000
    
    -- Throttle updates (pas besoin de 60 FPS)
    if timeMsec - lastFrameTimeMsec < Settings.updateIntervalMsec then 
        return 
    end
    
    lastFrameTimeMsec = timeMsec

    -- Update data
    model:updatePlayers()
    
    -- Update display
    view:update()
end)
```

**Leçon :** Throttle les updates (ex: 10 FPS suffit)

### 2. Packet Parsing

```lua
-- Écoute packets pour données party
windower.register_event('incoming chunk', function(id, original)
    if id == 0xC8 then -- Alliance update
        local packet = packets.parse('incoming', original)
        -- Parse player data
    end
    
    if id == 0xDF then -- Char update
        local packet = packets.parse('incoming', original)
        -- Parse HP/MP/TP
    end
end)
```

**Leçon :** Utiliser packets pour données temps réel

### 3. Model Séparé

```lua
-- model.lua
local Model = {}

function Model:new()
    local obj = {
        players = {},
        party = {},
        alliance = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Model:updatePlayers()
    local party = windower.ffxi.get_party()
    
    for i = 0, 5 do
        local member = party['p' .. i]
        if member then
            self:updatePlayer(member)
        end
    end
end

function Model:updatePlayer(member)
    local player = self.players[member.mob.id]
    if not player then
        player = Player:new(member)
        self.players[member.mob.id] = player
    end
    
    player:update(member)
end
```

**Leçon :** Séparer données (model) et affichage (view)

### 4. UI Components Modulaires

```lua
-- uiBar.lua (HP/MP bar)
local UiBar = {}

function UiBar:new(x, y, width, height, color)
    local obj = {
        x = x,
        y = y,
        width = width,
        height = height,
        color = color,
        value = 100,
        maxValue = 100,
        primitive = nil
    }
    
    obj.primitive = windower.prim.create('bar_' .. tostring(obj))
    windower.prim.set_position(obj.primitive, x, y)
    windower.prim.set_size(obj.primitive, width, height)
    windower.prim.set_color(obj.primitive, color.a, color.r, color.g, color.b)
    
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function UiBar:setValue(value, maxValue)
    self.value = value
    self.maxValue = maxValue
    
    local percent = value / maxValue
    local barWidth = self.width * percent
    
    windower.prim.set_size(self.primitive, barWidth, self.height)
end

function UiBar:dispose()
    if self.primitive then
        windower.prim.delete(self.primitive)
        self.primitive = nil
    end
end
```

**Leçon :** Composants réutilisables

### 5. Settings Persistants

```lua
-- settings.lua
local Settings = {}

function Settings:load()
    local defaults = require('defaults')
    local saved = config.load(defaults)
    
    for key, value in pairs(saved) do
        self[key] = value
    end
end

function Settings:save()
    config.save(self)
end
```

**Leçon :** Sauvegarder configs utilisateur

---

## 🎨 Adaptation pour AltOverlay

### Structure Proposée

```
AltOverlay/
├── AltOverlay.lua          # Main
├── model.lua               # Data model
├── view.lua                # Display
├── settings.lua            # Config
└── ui/
    ├── uiCharacter.lua     # Character display
    ├── uiBar.lua           # HP/MP/TP bars
    ├── uiText.lua          # Text display
    ├── uiPet.lua           # Pet display
    └── uiModes.lua         # Auto-modes display
```

### AltOverlay.lua (Main)

```lua
_addon.name = 'AltOverlay'
_addon.author = 'Dexter'
_addon.version = '1.0.0'
_addon.commands = {'altoverlay', 'ao'}

local packets = require('packets')
local socket = require('socket')

local model = require('model').new()
local view = require('view').new(model)
local settings = require('settings').new()

local isInitialized = false
local lastUpdateTime = 0
local updateInterval = 100 -- 10 FPS (100ms)

-- Init
windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        init()
    end
end)

windower.register_event('login', function()
    init()
end)

windower.register_event('logout', function()
    dispose()
end)

function init()
    if not isInitialized then
        settings:load()
        isInitialized = true
    end
end

function dispose()
    if isInitialized then
        view:dispose()
        isInitialized = false
    end
end

-- Update loop
windower.register_event('prerender', function()
    if not isInitialized then return end
    
    local now = socket.gettime() * 1000
    if now - lastUpdateTime < updateInterval then return end
    lastUpdateTime = now
    
    model:update()
    view:update()
end)

-- IPC Messages (depuis autres Lua)
windower.register_event('ipc message', function(msg)
    if msg:startswith('altoverlay_') then
        handle_ipc_message(msg)
    end
end)

function handle_ipc_message(msg)
    -- Parse: "altoverlay_update_BRD_hp:1250_mp:450_tp:1000"
    local parts = msg:split('_')
    local command = parts[2]
    
    if command == 'update' then
        local char_name = parts[3]
        local data = parse_data(parts, 4)
        model:updateCharacter(char_name, data)
    elseif command == 'pet' then
        local char_name = parts[3]
        local pet_data = parse_data(parts, 4)
        model:updatePet(char_name, pet_data)
    elseif command == 'modes' then
        local char_name = parts[3]
        local modes = parse_modes(parts, 4)
        model:updateModes(char_name, modes)
    end
end

function parse_data(parts, start_index)
    local data = {}
    for i = start_index, #parts do
        local kv = parts[i]:split(':')
        if #kv == 2 then
            data[kv[1]] = tonumber(kv[2]) or kv[2]
        end
    end
    return data
end
```

### model.lua (Data)

```lua
local Model = {}

function Model:new()
    local obj = {
        characters = {},
        main_character = nil
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Model:update()
    -- Update main character (local)
    local player = windower.ffxi.get_player()
    if player then
        self.main_character = {
            name = player.name,
            hp = player.hp,
            max_hp = player.max_hp,
            mp = player.mp,
            max_mp = player.max_mp,
            tp = player.tp,
            job = player.main_job
        }
    end
    
    -- Alt characters updated via IPC
end

function Model:updateCharacter(name, data)
    self.characters[name] = data
end

function Model:updatePet(char_name, pet_data)
    if self.characters[char_name] then
        self.characters[char_name].pet = pet_data
    end
end

function Model:updateModes(char_name, modes)
    if self.characters[char_name] then
        self.characters[char_name].modes = modes
    end
end

function Model:getCharacters()
    local chars = {}
    
    -- Main character
    if self.main_character then
        table.insert(chars, self.main_character)
    end
    
    -- Alt characters
    for name, data in pairs(self.characters) do
        table.insert(chars, data)
    end
    
    return chars
end

return Model
```

### view.lua (Display)

```lua
local View = {}

local UiCharacter = require('ui/uiCharacter')

function View:new(model)
    local obj = {
        model = model,
        characters = {},
        position = {x = 10, y = 10},
        spacing = 60
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function View:update()
    local chars = self.model:getCharacters()
    
    -- Update or create UI for each character
    for i, char_data in ipairs(chars) do
        local ui = self.characters[char_data.name]
        
        if not ui then
            -- Create new UI
            local y = self.position.y + (i - 1) * self.spacing
            ui = UiCharacter:new(self.position.x, y, char_data)
            self.characters[char_data.name] = ui
        end
        
        -- Update UI
        ui:update(char_data)
    end
    
    -- Remove UI for characters no longer present
    for name, ui in pairs(self.characters) do
        local found = false
        for _, char_data in ipairs(chars) do
            if char_data.name == name then
                found = true
                break
            end
        end
        
        if not found then
            ui:dispose()
            self.characters[name] = nil
        end
    end
end

function View:dispose()
    for name, ui in pairs(self.characters) do
        ui:dispose()
    end
    self.characters = {}
end

return View
```

### ui/uiCharacter.lua (Character Display)

```lua
local UiCharacter = {}

local UiBar = require('ui/uiBar')
local UiText = require('ui/uiText')

function UiCharacter:new(x, y, data)
    local obj = {
        x = x,
        y = y,
        data = data,
        
        -- UI elements
        nameText = nil,
        hpBar = nil,
        mpBar = nil,
        tpBar = nil,
        hpText = nil,
        mpText = nil,
        tpText = nil,
        petBar = nil,
        modesText = nil
    }
    
    -- Create UI elements
    obj.nameText = UiText:new(x, y, data.name, {r=255, g=255, b=255})
    
    obj.hpBar = UiBar:new(x, y + 15, 200, 10, {r=0, g=255, b=0})
    obj.hpText = UiText:new(x + 205, y + 15, '', {r=255, g=255, b=255})
    
    obj.mpBar = UiBar:new(x, y + 28, 200, 10, {r=0, g=100, b=255})
    obj.mpText = UiText:new(x + 205, y + 28, '', {r=255, g=255, b=255})
    
    obj.tpBar = UiBar:new(x, y + 41, 200, 10, {r=255, g=200, b=0})
    obj.tpText = UiText:new(x + 205, y + 41, '', {r=255, g=255, b=255})
    
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function UiCharacter:update(data)
    self.data = data
    
    -- Update bars
    self.hpBar:setValue(data.hp, data.max_hp)
    self.mpBar:setValue(data.mp, data.max_mp)
    self.tpBar:setValue(data.tp, 3000)
    
    -- Update text
    self.hpText:setText(string.format("%d/%d", data.hp, data.max_hp))
    self.mpText:setText(string.format("%d/%d", data.mp, data.max_mp))
    self.tpText:setText(string.format("%d", data.tp))
    
    -- Update pet if exists
    if data.pet then
        if not self.petBar then
            self.petBar = UiBar:new(self.x + 10, self.y + 54, 180, 8, {r=255, g=150, b=0})
        end
        self.petBar:setValue(data.pet.hp, data.pet.max_hp)
    elseif self.petBar then
        self.petBar:dispose()
        self.petBar = nil
    end
    
    -- Update modes
    if data.modes then
        local modes_str = ""
        for mode, active in pairs(data.modes) do
            if active then
                modes_str = modes_str .. mode .. " "
            end
        end
        
        if not self.modesText then
            self.modesText = UiText:new(self.x, self.y + 67, '', {r=100, g=255, b=100})
        end
        self.modesText:setText("Auto: " .. modes_str)
    end
end

function UiCharacter:dispose()
    if self.nameText then self.nameText:dispose() end
    if self.hpBar then self.hpBar:dispose() end
    if self.mpBar then self.mpBar:dispose() end
    if self.tpBar then self.tpBar:dispose() end
    if self.hpText then self.hpText:dispose() end
    if self.mpText then self.mpText:dispose() end
    if self.tpText then self.tpText:dispose() end
    if self.petBar then self.petBar:dispose() end
    if self.modesText then self.modesText:dispose() end
end

return UiCharacter
```

---

## 📡 Communication avec AltControl

### Depuis AltControl.lua (chaque perso)

```lua
-- Envoyer données vers overlay
function send_to_overlay()
    local player = windower.ffxi.get_player()
    
    local msg = string.format(
        "altoverlay_update_%s_hp:%d_maxhp:%d_mp:%d_maxmp:%d_tp:%d_job:%s",
        player.name,
        player.hp, player.max_hp,
        player.mp, player.max_mp,
        player.tp,
        player.main_job
    )
    
    windower.send_ipc_message(msg)
    
    -- Pet si existe
    if pet.isvalid then
        local pet_msg = string.format(
            "altoverlay_pet_%s_hp:%d_maxhp:%d",
            player.name,
            pet.hp, pet.max_hp
        )
        windower.send_ipc_message(pet_msg)
    end
    
    -- Auto-modes actifs
    local modes_msg = string.format(
        "altoverlay_modes_%s_songs:%s_engage:%s",
        player.name,
        tostring(state.AutoSongMode.value),
        tostring(state.AutoEngageMode.value)
    )
    windower.send_ipc_message(modes_msg)
end

-- Envoyer toutes les 100ms
windower.register_event('prerender', function()
    local now = os.clock()
    if now - last_overlay_update > 0.1 then
        send_to_overlay()
        last_overlay_update = now
    end
end)
```

---

## 🎯 Avantages de cette Approche

1. **Pas de latence réseau** : IPC local Windower
2. **Temps réel** : Update 10 FPS
3. **Léger** : Pas de HTTP/polling
4. **Visible in-game** : Toujours sous les yeux
5. **Modulaire** : Facile à étendre
6. **Inspiré XIVParty** : Code éprouvé

---

## 📝 Prochaines Étapes

1. [ ] Créer structure AltOverlay
2. [ ] Implémenter model.lua
3. [ ] Implémenter view.lua
4. [ ] Créer UI components basiques
5. [ ] Tester IPC communication
6. [ ] Ajouter customisation (position, couleurs)

---

**Date:** 23 novembre 2024  
**Source:** XIVParty analysis  
**Version:** 1.0 - Inspiration overlay
