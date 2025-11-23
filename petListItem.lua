--[[
    Pet List Item - Display component for one pet
    Uses XIVParty UI components for consistent styling
]]

-- Imports
local classes = require('classes')
local uiElement = require('uiElement')
local uiImage = require('uiImage')
local uiBar = require('uiBar')
local uiText = require('uiText')
local uiContainer = require('uiContainer')

-- Create class
local PetListItem = classes.class(uiElement)

function PetListItem:init(pet_data, index, settings)
    if self.super:init() then
        self.pet_data = pet_data
        self.index = index
        self.settings = settings or {}
        
        -- Calculate position
        local base_y = (settings.base_y or 0) + (index * (settings.item_height or 50))
        local base_x = settings.base_x or 0
        
        -- Create container
        self.container = uiContainer:new({
            pos = {x = base_x, y = base_y}
        })
        
        -- Background
        self.bg = uiImage:new({
            path = windower.addon_path .. 'assets/xiv/BgMid.png',
            pos = {x = 0, y = 0},
            size = {width = 400, height = 46},
            color = {a = 220, r = 255, g = 255, b = 255}
        })
        
        -- Owner → Pet name text
        self.nameText = uiText:new({
            text = pet_data.owner .. ' → ' .. pet_data.name,
            pos = {x = 10, y = 5},
            font = 'Arial',
            size = 11,
            color = {a = 255, r = 255, g = 255, b = 255},
            stroke = {a = 200, r = 0, g = 0, b = 0, width = 2}
        })
        
        -- HP Bar
        self.hpBar = uiBar:new({
            pos = {x = 10, y = 20},
            size = {width = 300, height = 12},
            value = pet_data.hp / pet_data.max_hp,
            color = self:getHPColor(pet_data.hp / pet_data.max_hp),
            images = {
                bg = windower.addon_path .. 'assets/xiv/BarBG.png',
                bar = windower.addon_path .. 'assets/xiv/Bar.png',
                fg = windower.addon_path .. 'assets/xiv/BarFG.png'
            }
        })
        
        -- HP Value text
        self.hpText = uiText:new({
            text = pet_data.hp .. '/' .. pet_data.max_hp,
            pos = {x = 320, y = 20},
            font = 'Arial',
            size = 10,
            color = {a = 255, r = 255, g = 255, b = 255},
            stroke = {a = 200, r = 0, g = 0, b = 0, width = 2}
        })
        
        -- Job-specific info text
        self.infoText = uiText:new({
            text = self:getInfoText(pet_data),
            pos = {x = 10, y = 35},
            font = 'Arial',
            size = 10,
            color = {a = 255, r = 200, g = 255, b = 200},
            stroke = {a = 200, r = 0, g = 0, b = 0, width = 2}
        })
        
        return true
    end
    return false
end

function PetListItem:getHPColor(hp_percent)
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

function PetListItem:getInfoText(pet_data)
    if pet_data.charges then
        local text = "Ready: "
        for i = 1, 5 do
            if i <= pet_data.charges then
                text = text .. "●"
            else
                text = text .. "○"
            end
            if i < 5 then text = text .. " " end
        end
        return text .. string.format(" (%d/5)", pet_data.charges)
        
    elseif pet_data.bp_timer then
        if pet_data.bp_timer <= 0 then
            return "Blood Pact: Ready"
        else
            return string.format("Blood Pact: %.1fs", pet_data.bp_timer)
        end
        
    elseif pet_data.breath_ready ~= nil then
        if pet_data.breath_ready then
            return "Healing Breath: Ready"
        else
            return "Healing Breath: Not Ready"
        end
    end
    
    return ""
end

function PetListItem:update(pet_data)
    self.pet_data = pet_data
    
    -- Update HP bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    if self.hpBar then
        self.hpBar:setValue(hp_percent)
        self.hpBar:setColor(self:getHPColor(hp_percent))
    end
    
    -- Update texts
    if self.nameText then
        self.nameText:setText(pet_data.owner .. ' → ' .. pet_data.name)
    end
    
    if self.hpText then
        self.hpText:setText(pet_data.hp .. '/' .. pet_data.max_hp)
    end
    
    if self.infoText then
        self.infoText:setText(self:getInfoText(pet_data))
    end
end

function PetListItem:show()
    if self.bg then self.bg:show() end
    if self.nameText then self.nameText:show() end
    if self.hpBar then self.hpBar:show() end
    if self.hpText then self.hpText:show() end
    if self.infoText then self.infoText:show() end
end

function PetListItem:hide()
    if self.bg then self.bg:hide() end
    if self.nameText then self.nameText:hide() end
    if self.hpBar then self.hpBar:hide() end
    if self.hpText then self.hpText:hide() end
    if self.infoText then self.infoText:hide() end
end

function PetListItem:dispose()
    if self.bg then self.bg:dispose() end
    if self.nameText then self.nameText:dispose() end
    if self.hpBar then self.hpBar:dispose() end
    if self.hpText then self.hpText:dispose() end
    if self.infoText then self.infoText:dispose() end
end

return PetListItem
