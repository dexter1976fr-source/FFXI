--[[
    AutoEngage Tool
    Automatically assists and attacks the main tank's target
]]

local AutoEngage = {}

-- État
AutoEngage.active = false
AutoEngage.target_name = nil
AutoEngage.last_check = 0
AutoEngage.check_interval = 1.0  -- Vérifier toutes les 1 seconde
AutoEngage.last_target_id = nil
AutoEngage.pending_commands = {}  -- File d'attente de commandes
AutoEngage.on_state_change = nil  -- Callback pour notifier les changements d'état

-- Démarrer l'auto-engage
function AutoEngage.start(target_name)
    AutoEngage.active = true
    AutoEngage.target_name = target_name  -- Optionnel, peut être nil
    AutoEngage.last_target_id = 0  -- Reset to 0, not nil
    AutoEngage.last_check = 0  -- Force immediate check
    
    if target_name and target_name ~= "" then
        print('[AutoEngage] ✅ Started - Assisting: ' .. target_name)
    else
        print('[AutoEngage] ✅ Started - Assisting <p1>')
    end
    
    -- Notifier le changement d'état
    if AutoEngage.on_state_change then
        AutoEngage.on_state_change(true)
    end
    
    return true
end

-- Arrêter l'auto-engage
function AutoEngage.stop()
    AutoEngage.active = false
    AutoEngage.target_name = nil
    AutoEngage.last_target_id = nil
    print('[AutoEngage] ⏹️ Stopped')
    
    -- Notifier le changement d'état
    if AutoEngage.on_state_change then
        AutoEngage.on_state_change(false)
    end
end

-- Vérifier si actif
function AutoEngage.is_active()
    return AutoEngage.active
end

-- Update (appelé depuis la boucle principale)
function AutoEngage.update()
    if not AutoEngage.active then return end
    
    local now = os.clock()
    
    -- Exécuter les commandes en attente d'abord
    for i = #AutoEngage.pending_commands, 1, -1 do
        local cmd_data = AutoEngage.pending_commands[i]
        if now >= cmd_data.time then
            windower.send_command(cmd_data.cmd)
            table.remove(AutoEngage.pending_commands, i)
        end
    end
    
    if now - AutoEngage.last_check < AutoEngage.check_interval then
        return
    end
    AutoEngage.last_check = now
    
    local player = windower.ffxi.get_player()
    if not player then return end
    
    -- Ne rien faire si déjà engagé
    if player.status == 1 then return end
    
    -- Ne rien faire si en cast
    if player.status == 4 then return end
    
    -- Vérifier si <p1> (le leader) est engagé
    local party = windower.ffxi.get_party()
    if not party or not party.p1 or not party.p1.mob then return end
    
    local leader = party.p1
    local leader_mob = windower.ffxi.get_mob_by_id(leader.mob.id)
    
    if not leader_mob or leader_mob.status ~= 1 then return end
    
    -- Récupérer la cible du leader
    local target_id = leader_mob.target_index
    if not target_id or target_id == 0 then return end
    
    -- Si c'est une nouvelle cible, engager
    if target_id ~= AutoEngage.last_target_id then
        AutoEngage.last_target_id = target_id
        
        print('[AutoEngage] ⚔️ Engaging')
        
        -- File d'attente de commandes avec délais
        if player.main_job == 'SMN' then
            -- SMN: Pet d'abord, puis le SMN engage
            AutoEngage.pending_commands = {
                {time = now + 0.0, cmd = 'input /assist <p1>'},
                {time = now + 1.0, cmd = 'input /assault <t>'},
                {time = now + 2.0, cmd = 'input /attack <bt>'}
            }
        else
            -- Autres jobs: assist puis attack
            AutoEngage.pending_commands = {
                {time = now + 0.0, cmd = 'input /assist <p1>'},
                {time = now + 1.0, cmd = 'input /attack <bt>'}
            }
        end
    end
end

-- Commandes
function AutoEngage.handle_command(cmd, ...)
    local args = {...}
    
    if cmd == 'start' then
        local target = args[1]  -- Optionnel
        AutoEngage.start(target)
        
    elseif cmd == 'stop' then
        AutoEngage.stop()
        
    elseif cmd == 'status' then
        if AutoEngage.active then
            print('[AutoEngage] Status: ACTIVE')
            print('[AutoEngage] Target: <p1>')
        else
            print('[AutoEngage] Status: INACTIVE')
        end
    end
end

return AutoEngage
