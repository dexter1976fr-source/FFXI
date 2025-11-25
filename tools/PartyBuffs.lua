----------------------------------------------------------
-- PARTY BUFFS - Récupération des buffs via serveur Python
-- Utilise dkjson pour parser les données du serveur
----------------------------------------------------------

local PartyBuffs = {}
local json = require('tools.dkjson')
local buffs_cache = {}
local last_update = 0
local update_interval = 2

function PartyBuffs.init()
    print('[PartyBuffs] Module initialized')
end

local function fetch_buffs_from_server()
    local http = require('socket.http')
    local ltn12 = require('ltn12')
    local response_body = {}
    
    local _, code = http.request{
        url = 'http://127.0.0.1:5000/all-alts',
        sink = ltn12.sink.table(response_body)
    }
    
    if code ~= 200 then
        return false, 'Server error: ' .. tostring(code)
    end
    
    local response = table.concat(response_body)
    local data, pos, err = json.decode(response, 1, nil)
    
    if not data or not data.alts then
        return false, 'Invalid JSON: ' .. tostring(err)
    end
    
    local new_cache = {}
    for _, alt in ipairs(data.alts) do
        local buff_data = {
            names = alt.active_buffs or {},
            ids = alt.active_buff_ids or {}
        }
        new_cache[alt.name] = buff_data
    end
    
    buffs_cache = new_cache
    last_update = os.clock()
    return true, 'OK'
end

function PartyBuffs.get_buffs(player_name)
    if os.clock() - last_update > update_interval then
        fetch_buffs_from_server()
    end
    local data = buffs_cache[player_name]
    if not data or not data.names then return {} end
    -- S'assurer que c'est une vraie table
    if type(data.names) ~= "table" then return {} end
    return data.names
end

function PartyBuffs.get_buff_ids(player_name)
    if os.clock() - last_update > update_interval then
        fetch_buffs_from_server()
    end
    local data = buffs_cache[player_name]
    if not data or not data.ids then return {} end
    -- S'assurer que c'est une vraie table
    if type(data.ids) ~= "table" then return {} end
    return data.ids
end

function PartyBuffs.has_buff(player_name, buff_name)
    local buffs = PartyBuffs.get_buffs(player_name)
    buff_name = buff_name:lower()
    for _, buff in ipairs(buffs) do
        if buff:lower():find(buff_name, 1, true) then
            return true
        end
    end
    return false
end

function PartyBuffs.refresh()
    local success, msg = fetch_buffs_from_server()
    if success then
        print('[PartyBuffs] Cache refreshed')
    else
        print('[PartyBuffs] Refresh failed: ' .. msg)
    end
    return success
end

function PartyBuffs.get_all_players()
    if os.clock() - last_update > update_interval then
        fetch_buffs_from_server()
    end
    local players = {}
    for name, _ in pairs(buffs_cache) do
        table.insert(players, name)
    end
    return players
end

-- 🔥 DEBUG AMÉLIORÉ : Affiche noms ET IDs
function PartyBuffs.debug()
    print('========================================')
    print('[PartyBuffs] DEBUG - Current Cache')
    print('========================================')
    
    if not buffs_cache or not next(buffs_cache) then
        print('[PartyBuffs] Cache is EMPTY!')
        return
    end
    
    for name, data in pairs(buffs_cache) do
        print('[PartyBuffs] Player: ' .. name)
        
        local buff_names = data.names or {}
        local buff_ids = data.ids or {}
        
        print('  Buff Names (' .. #buff_names .. '):')
        if #buff_names > 0 then
            print('    ' .. table.concat(buff_names, ', '))
        else
            print('    (none)')
        end
        
        print('  Buff IDs (' .. #buff_ids .. '):')
        if #buff_ids > 0 then
            print('    ' .. table.concat(buff_ids, ', '))
        else
            print('    (none)')
        end
        
        -- Afficher côte à côte si possible
        if #buff_names > 0 and #buff_ids > 0 then
            print('  Details:')
            for i = 1, math.max(#buff_names, #buff_ids) do
                local name_str = buff_names[i] or '???'
                local id_str = buff_ids[i] or '???'
                print('    [' .. i .. '] ' .. name_str .. ' (ID: ' .. tostring(id_str) .. ')')
            end
        end
        print('')
    end
    
    print('========================================')
    print('Last update: ' .. string.format('%.1f', os.clock() - last_update) .. 's ago')
    print('========================================')
end

-- 🔥 NOUVELLE FONCTION : Debug pour un seul joueur
function PartyBuffs.debug_player(player_name)
    local data = buffs_cache[player_name]
    if not data then
        print('[PartyBuffs] Player "' .. player_name .. '" not found in cache!')
        return
    end
    
    print('========================================')
    print('[PartyBuffs] DEBUG - ' .. player_name)
    print('========================================')
    
    local buff_names = data.names or {}
    local buff_ids = data.ids or {}
    
    print('Total buffs: ' .. #buff_names .. ' names, ' .. #buff_ids .. ' IDs')
    print('')
    
    if #buff_names == 0 and #buff_ids == 0 then
        print('  (No buffs)')
    else
        for i = 1, math.max(#buff_names, #buff_ids) do
            local name_str = buff_names[i] or 'Unknown'
            local id_str = buff_ids[i] or '?'
            print('  [' .. i .. '] ' .. name_str .. ' → ID ' .. tostring(id_str))
        end
    end
    
    print('========================================')
end

return PartyBuffs
