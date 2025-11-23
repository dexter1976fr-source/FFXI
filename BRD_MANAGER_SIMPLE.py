# BRD Manager Simple - À intégrer dans FFXI_ALT_Control.py

def run_brd_manager_loop(stop_event):
    """Thread BRD Manager - SIMPLE"""
    import time
    print("[BRD Manager] 🎵 Started")
    
    last_check = 0
    waiting_inactive = False
    inactive_since = 0
    next_phase = None
    
    while not stop_event.is_set():
        try:
            current_time = time.time()
            
            # Trouver le BRD
            brd_name = None
            brd_data = None
            for name, data in alts.items():
                if data.get("main_job") == "BRD":
                    brd_name = name
                    brd_data = data
                    break
            
            if not brd_name:
                time.sleep(1)
                continue
            
            # Vérifier si quelqu'un est engagé
            someone_engaged = any(d.get("is_engaged") or d.get("party_engaged") for d in alts.values())
            
            if not someone_engaged:
                # Personne engagé → Retour au healer
                config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
                if os.path.exists(config_file):
                    with open(config_file, 'r') as f:
                        config = json.load(f).get("BRD", {})
                    healer = config.get("healerTarget")
                    if healer:
                        send_command_to_alt(brd_name, f'//ac follow {healer}')
                
                waiting_inactive = False
                next_phase = None
                time.sleep(5)
                continue
            
            # Si on attend l'inactivité
            if waiting_inactive:
                is_inactive = not brd_data.get("is_casting") and not brd_data.get("is_moving")
                
                if is_inactive:
                    if inactive_since == 0:
                        inactive_since = current_time
                    elif current_time - inactive_since >= 3:
                        # Inactif 3 sec → Phase suivante
                        print(f"[BRD Manager] ✅ Inactive 3 sec, next: {next_phase}")
                        waiting_inactive = False
                        inactive_since = 0
                        
                        if next_phase == "melee":
                            next_phase = None
                            last_check = 0
                        elif next_phase == "return_healer":
                            config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
                            if os.path.exists(config_file):
                                with open(config_file, 'r') as f:
                                    config = json.load(f).get("BRD", {})
                                healer = config.get("healerTarget")
                                if healer:
                                    send_command_to_alt(brd_name, f'//ac follow {healer}')
                            next_phase = None
                            last_check = 0
                else:
                    inactive_since = 0
                
                time.sleep(0.5)
                continue
            
            # Check toutes les 10 secondes
            if current_time - last_check < 10:
                time.sleep(1)
                continue
            
            last_check = current_time
            
            # Charger config
            config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
            if not os.path.exists(config_file):
                time.sleep(1)
                continue
            
            with open(config_file, 'r') as f:
                config = json.load(f).get("BRD", {})
            
            healer = config.get("healerTarget")
            melee = config.get("meleeTarget")
            mage_songs = config.get("mageSongs", [])
            melee_songs = config.get("meleeSongs", [])
            
            if not healer or not melee or len(mage_songs) < 2 or len(melee_songs) < 2:
                time.sleep(1)
                continue
            
            # Check mage buffs (si UN SEUL manque, on recast les 2)
            if healer in alts:
                healer_buffs = alts[healer].get("active_buffs", [])
                has_ballad = any("Ballad" in b for b in healer_buffs)
                has_march = any("March" in b for b in healer_buffs)
                has_paeon = any("Paeon" in b for b in healer_buffs)
                
                if not (has_ballad or has_march or has_paeon):
                    print(f"[BRD Manager] 🎵 Mage buffs missing")
                    # Cast song 1 direct + song 2 en queue
                    send_command_to_alt(brd_name, f'//ac cast "{mage_songs[0]}" <me>')
                    time.sleep(0.5)
                    send_command_to_alt(brd_name, f'//ac queue_song "{mage_songs[1]}" <me>')
                    
                    waiting_inactive = True
                    next_phase = "melee"
                    continue
            
            # Check melee buffs
            if melee in alts:
                melee_buffs = alts[melee].get("active_buffs", [])
                has_minuet = any("Minuet" in b for b in melee_buffs)
                has_madrigal = any("Madrigal" in b for b in melee_buffs)
                has_mambo = any("Mambo" in b for b in melee_buffs)
                
                if not (has_minuet or has_madrigal or has_mambo):
                    print(f"[BRD Manager] ⚔️ Melee buffs missing")
                    send_command_to_alt(brd_name, f'//ac follow {melee}')
                    time.sleep(1)
                    
                    # Cast song 1 direct + song 2 en queue
                    send_command_to_alt(brd_name, f'//ac cast "{melee_songs[0]}" <me>')
                    time.sleep(0.5)
                    send_command_to_alt(brd_name, f'//ac queue_song "{melee_songs[1]}" <me>')
                    
                    waiting_inactive = True
                    next_phase = "return_healer"
                    continue
            
            print("[BRD Manager] ✅ All buffs OK")
            
        except Exception as e:
            print(f"[BRD Manager] ❌ Error: {e}")
            import traceback
            traceback.print_exc()
        
        time.sleep(1)
    
    print("[BRD Manager] 🎵 Stopped")
