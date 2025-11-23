--[[
    AltPetOverlay Chat - Version qui affiche dans le chat pour tester l'IPC
]]

_addon.name = 'AltPetOverlay'
_addon.version = '1.0.0-chat'
_addon.commands = {'petoverlay', 'po'}

local socket = require('socket')
local pets = {}

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
            last_update = socket.gettime()
        }
        
        -- Afficher dans le chat
        local msg = string.format(
            "[Pet] %s -> %s | HP: %d/%d",
            data.owner, data.pet, data.hp, data.maxhp
        )
        
        if data.charges then
            msg = msg .. string.format(" | Charges: %d/5", data.charges)
        end
        
        windower.add_to_chat(122, msg)
    end
end)

-- Commands
windower.register_event('addon command', function(...)
    local args = {...}
    local cmd = args[1] and args[1]:lower()
    
    if cmd == 'test' then
        windower.send_ipc_message('petoverlay_owner:Dexterbrown_pet:BlackbeardRandy_hp:650_maxhp:1000_charges:3')
        windower.add_to_chat(122, '[PetOverlay] Test IPC sent')
        
    elseif cmd == 'list' then
        windower.add_to_chat(122, '[PetOverlay] Current pets:')
        for owner, pet_data in pairs(pets) do
            windower.add_to_chat(122, string.format(
                "  %s -> %s (HP: %d/%d)",
                owner, pet_data.name, pet_data.hp, pet_data.max_hp
            ))
        end
    else
        windower.add_to_chat(122, '[PetOverlay] Commands:')
        windower.add_to_chat(122, '  //po test - Send test IPC')
        windower.add_to_chat(122, '  //po list - List pets')
    end
end)

windower.add_to_chat(122, '[AltPetOverlay] Chat version loaded')
windower.add_to_chat(122, '[AltPetOverlay] Type //po test to test IPC')
