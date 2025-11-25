----------------------------------------------------------
-- AUTO CAST SYSTEM - Module Principal
-- Gère l'automatisation des sorts/abilities par job
-- Version: 1.0.0
----------------------------------------------------------

require('sets')
require('tables')

local autocast = {
    -- État du système
    active = false,
    current_job = nil,
    config = {},
    job_modules = {},
    
    -- État du cast
    is_casting = false,
    last_cast_time = 0,
    cast_queue = {},
    
    -- Cooldown entre actions (secondes)
    global_cooldown = 3.0,
}

----------------------------------------------------------
-- 🔹 CHARGEMENT DES MODULES PAR JOB
----------------------------------------------------------

function autocast.load_job_module(job)
    if not job then return false end
    
    local module_name = 'AutoCast_'..job
    local success, module = pcall(require, module_name)
    
    if success then
        autocast.job_modules[job] = module
        print('[AutoCast] ✅ Loaded module for '..job)
        
        -- Initialiser le module si fonction init existe
        if module.init then
            module.init()
        end
        
        -- 🆕 Charger la config depuis le fichier (pour BRD)
        if job == 'BRD' and module.load_config_from_file then
            print('[AutoCast] 📖 Loading BRD config from file...')
            module.load_config_from_file()
        end
        
        return true
    else
        print('[AutoCast] ⚠️ No module found for '..job)
        return false
    end
end

----------------------------------------------------------
-- 🔹 DÉMARRAGE / ARRÊT
----------------------------------------------------------

function autocast.start(config_json)
    print('[AutoCast] 🐛 start() called')
    
    local player = windower.ffxi.get_player()
    if not player then 
        print('[AutoCast] ❌ Player not found')
        return false 
    end
    
    print('[AutoCast] 🐛 Player found: '..player.name..' ('..player.main_job..')')
    autocast.current_job = player.main_job
    
    -- Parser la config JSON si fournie
    if config_json and type(config_json) == 'string' then
        local success, parsed = pcall(function() return json.decode(config_json) end)
        if success then
            autocast.config = parsed
        else
            autocast.config = {}
        end
    elseif type(config_json) == 'table' then
        autocast.config = config_json
    else
        autocast.config = {}
    end
    
    print('[AutoCast] 🐛 Loading job module for '..autocast.current_job)
    
    -- Charger le module du job
    local loaded = autocast.load_job_module(autocast.current_job)
    if not loaded then
        print('[AutoCast] ❌ Failed to load module for '..autocast.current_job)
        return false
    end
    
    print('[AutoCast] 🐛 Setting active = true')
    autocast.active = true
    autocast.last_cast_time = os.clock()
    
    print('[AutoCast] ✅ Started for '..autocast.current_job)
    print('[AutoCast] 🐛 DEBUG: autocast.active = '..tostring(autocast.active))
    return true
end

function autocast.stop()
    if not autocast.active then return end
    
    print('[AutoCast] ⚠️ STOP called! (check who called this)')
    autocast.active = false
    autocast.cast_queue = {}
    
    -- Arrêter le mouvement si actif
    windower.ffxi.run(false)
    
    -- Appeler la fonction cleanup du module si elle existe
    local job_module = autocast.job_modules[autocast.current_job]
    if job_module and job_module.cleanup then
        job_module.cleanup()
    end
    
    print('[AutoCast] 🛑 Stopped')
end

----------------------------------------------------------
-- 🔹 MISE À JOUR (appelée chaque frame)
----------------------------------------------------------

function autocast.update()
    if not autocast.active then 
        -- Ne pas spammer, juste retourner silencieusement
        return 
    end
    if autocast.is_casting then return end
    
    local player = windower.ffxi.get_player()
    if not player then return end
    
    -- Vérifier le cooldown global
    local time_since_last_cast = os.clock() - autocast.last_cast_time
    if time_since_last_cast < autocast.global_cooldown then
        return
    end
    
    -- Déléguer au module du job
    local job_module = autocast.job_modules[player.main_job]
    if job_module and job_module.update then
        job_module.update(autocast.config, player)
    end
end

----------------------------------------------------------
-- 🔹 ÉVÉNEMENTS
----------------------------------------------------------

function autocast.on_action(action)
    local player = windower.ffxi.get_player()
    if not player or action.actor_id ~= player.id then return end
    
    -- Catégories d'actions Windower
    local SPELL_BEGIN = 8
    local SPELL_FINISH = 4
    local SPELL_INTERRUPT = 8
    local ITEM_BEGIN = 9
    local ITEM_FINISH = 5
    
    if action.category == SPELL_BEGIN or action.category == ITEM_BEGIN then
        -- Début de cast
        autocast.is_casting = true
        -- print('[AutoCast] 🎵 Casting started...') -- Désactivé pour réduire spam
        
    elseif action.category == SPELL_FINISH or action.category == ITEM_FINISH then
        -- Fin de cast
        autocast.is_casting = false
        autocast.last_cast_time = os.clock()
        -- print('[AutoCast] ✅ Cast finished') -- Désactivé pour réduire spam
        
    elseif action.category == SPELL_INTERRUPT then
        -- Cast interrompu
        autocast.is_casting = false
        -- print('[AutoCast] ⚠️ Cast interrupted') -- Désactivé pour réduire spam
    end
    
    -- 🆕 IMPORTANT: Déléguer au module du job APRÈS avoir mis à jour is_casting
    local job_module = autocast.job_modules[player.main_job]
    if job_module and job_module.on_action then
        job_module.on_action(action, player)
    end
end

----------------------------------------------------------
-- 🔹 UTILITAIRES
----------------------------------------------------------

function autocast.is_active()
    return autocast.active
end

function autocast.get_config()
    return autocast.config
end

function autocast.set_config(new_config)
    autocast.config = new_config or {}
end

function autocast.set_follow_target(target_name)
    -- Définir la cible à suivre
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local job_module = autocast.job_modules[player.main_job]
    if job_module and job_module.set_follow_target then
        job_module.set_follow_target(target_name)
        print('[AutoCast] Follow target set to: '..target_name)
    end
end

-- Force le cast des songs mages (BRD)
function autocast.force_cast_mages()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local job_module = autocast.job_modules[player.main_job]
    if job_module and job_module.force_cast_mages then
        job_module.force_cast_mages()
    end
end

-- Force le cast des songs melees (BRD)
function autocast.force_cast_melees()
    local player = windower.ffxi.get_player()
    if not player then return end
    
    local job_module = autocast.job_modules[player.main_job]
    if job_module and job_module.force_cast_melees then
        job_module.force_cast_melees()
    end
end

-- Configure le healer target pour BRD
function autocast.set_brd_healer(target)
    local job_module = autocast.job_modules['BRD']
    if job_module then
        job_module.config_healer_target = target
    end
end

-- Configure le melee target pour BRD
function autocast.set_brd_melee(target)
    local job_module = autocast.job_modules['BRD']
    if job_module then
        job_module.config_melee_target = target
    end
end

-- Configure un mage song pour BRD
function autocast.set_brd_mage_song(index, song)
    local job_module = autocast.job_modules['BRD']
    if job_module and job_module.default_config and job_module.default_config.mage_songs then
        job_module.default_config.mage_songs[index] = song
        print('[AutoCast] 🎵 Updated mage_songs['..index..'] = '..song)
        print('[AutoCast] 🎵 Current mage_songs: '..table.concat(job_module.default_config.mage_songs, ', '))
    else
        print('[AutoCast] ❌ Failed to update mage song - module not found')
    end
end

-- Configure un melee song pour BRD
function autocast.set_brd_melee_song(index, song)
    local job_module = autocast.job_modules['BRD']
    if job_module and job_module.default_config and job_module.default_config.melee_songs then
        job_module.default_config.melee_songs[index] = song
        print('[AutoCast] ⚔️ Updated melee_songs['..index..'] = '..song)
        print('[AutoCast] ⚔️ Current melee_songs: '..table.concat(job_module.default_config.melee_songs, ', '))
    else
        print('[AutoCast] ❌ Failed to update melee song - module not found')
    end
end

-- Recharge la config BRD depuis le fichier JSON
function autocast.reload_brd_config()
    local job_module = autocast.job_modules['BRD']
    if job_module and job_module.load_config_from_file then
        return job_module.load_config_from_file()
    end
    return false
end

----------------------------------------------------------
-- 🔹 EXPORT
----------------------------------------------------------

return autocast
