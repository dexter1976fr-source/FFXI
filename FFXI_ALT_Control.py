import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import socket
import json
import os
from flask import Flask, send_from_directory, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO, emit as socketio_emit

# ============ CONFIGURATION ============
DIR_JSON = os.path.join(os.path.dirname(__file__), "data_json")
STATIC_DIR = os.path.join(os.path.dirname(__file__), "Web_App", "dist")
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "alt_data_path.txt")
PET_OVERLAY_FILE = "A:/Jeux/PlayOnline/Windower4/addons/AltPetOverlay/pet_data.txt"
HOST_LUA = "127.0.0.1"
PORT_LUA = 5007

# ============ DONNÉES GLOBALES ============
alts = {}           # altName: { name, ip, port, main_job, main_job_level, sub_job, sub_job_level, weapon_id, weapon_type, pet_name, party }
item_types = {}     # weapon_id: weapon_type (ex: "25600": "Great Sword")
jobs_data = {}      # job_abbrev: { spells, job_abilities, pet_command, pet_attack, macro }
ws_data = []        # Liste de tous les weapon skills par type
lua_thread = None
flask_thread = None
servers_running = False
socketio = None
last_logged_state = {}  # Pour éviter le spam des logs (altName: { job, weapon, engaged, pet })
player_buffs = {}   # playerName: [list of buff names] - Buffs de chaque personnage

# ============ CHARGEMENT DES JSON ============

def load_item_types():
    """Charge item_types.json (mapping weapon_id -> weapon_type)"""
    global item_types
    try:
        path = os.path.join(DIR_JSON, "item_types.json")
        with open(path, "r", encoding="utf-8") as f:
            item_types = json.load(f)
        print(f"[INFO] item_types.json loaded: {len(item_types)} weapons")
    except Exception as e:
        print(f"[WARN] item_types.json not loaded: {e}")
        item_types = {}

def load_jobs_data():
    """Charge jobs.json (le fichier unifié créé par le convertisseur)"""
    global jobs_data
    try:
        path = os.path.join(DIR_JSON, "jobs.json")
        with open(path, "r", encoding="utf-8") as f:
            jobs_data = json.load(f)
        print(f"[INFO] jobs.json loaded: {len(jobs_data)} jobs")
    except Exception as e:
        print(f"[ERROR] jobs.json not loaded: {e}")
        jobs_data = {}

def load_ws_data():
    """Charge ws.json (tous les weapon skills par type d'arme)"""
    global ws_data
    try:
        path = os.path.join(DIR_JSON, "ws.json")
        with open(path, "r", encoding="utf-8") as f:
            ws_data = json.load(f)
        print(f"[INFO] ws.json loaded: {len(ws_data)} weapon types")
    except Exception as e:
        print(f"[WARN] ws.json not loaded: {e}")
        ws_data = []

# Chargement au démarrage
load_item_types()
load_jobs_data()
load_ws_data()

# ============ UTILITAIRES ============

def get_weapon_type(item_id):
    """Retourne le type d'arme à partir de l'item_id"""
    s_item_id = str(item_id)
    wtype = item_types.get(s_item_id, "Unknown")
    return wtype

def filter_by_level(items, char_level):
    """
    Filtre une liste d'items (spells/abilities) par level requis
    items: liste de dict avec clé "level"
    char_level: level du personnage (int ou string)
    """
    try:
        char_level = int(char_level)
    except (ValueError, TypeError):
        return []
    
    result = []
    for item in items:
        if not isinstance(item, dict):
            continue
        
        # Récupérer le level requis
        req_level = item.get("level")
        
        # Si level est "all" ou absent, on l'inclut
        if req_level is None or req_level == "all":
            result.append(item)
            continue
        
        # Convertir en int et comparer
        try:
            req_level = int(req_level)
            if char_level >= req_level:
                result.append(item)
        except (ValueError, TypeError):
            # Si impossible à convertir, on l'inclut par sécurité
            result.append(item)
    
    return result

def get_weapon_skills_for_type(weapon_type):
    """
    Retourne la liste des WS disponibles pour un type d'arme
    ws_data format: [{"weapon_type": "Sword", "weapon_skills": ["Fast Blade", ...]}, ...]
    """
    if not weapon_type or weapon_type == "Unknown":
        return []
    
    for ws_group in ws_data:
        if ws_group.get("weapon_type", "").lower() == weapon_type.lower():
            return ws_group.get("weapon_skills", [])
    
    return []

def get_alt_abilities(alt_name):
    """
    Retourne toutes les capacités disponibles pour un ALT donné
    Croise les données du personnage avec jobs.json
    """
    alt = alts.get(alt_name)
    if not alt:
        return {
            "error": f"ALT '{alt_name}' not found",
            "available_alts": list(alts.keys())
        }
    
    main_job = alt.get("main_job", "?")
    main_level = alt.get("main_job_level", 1)
    sub_job = alt.get("sub_job", "")
    sub_level = alt.get("sub_job_level", 0)
    weapon_type = alt.get("weapon_type", "Unknown")
    pet_name = alt.get("pet_name")  # 🐾 Keep for Blood Pact menu filtering
    party = alt.get("party", [])
    
    result = {
        "alt_name": alt_name,
        "main_job": main_job,
        "main_job_level": main_level,
        "sub_job": sub_job,
        "sub_job_level": sub_level,
        "weapon_type": weapon_type,
        "pet_name": pet_name,  # 🐾 Keep for Blood Pact menu filtering
        # 🗑️ Other pet data removed - now handled by AltPetOverlay
        # "pet_hp": alt.get("pet_hp", 0),
        # "pet_hpp": alt.get("pet_hpp", 0),
        # "pet_tp": alt.get("pet_tp", 0),
        # "bst_ready_charges": alt.get("bst_ready_charges", 0),
        "is_engaged": alt.get("is_engaged", False),
        "active_buffs": alt.get("active_buffs", []),
        "party": party,
        "spells": [],
        "job_abilities": [],
        "pet_commands": [],
        "pet_attacks": {},
        "weapon_skills": [],
        "macros": [],
        "ability_recasts": alt.get("ability_recasts", {}),
        "spell_recasts": alt.get("spell_recasts", {})
    }
    
    # ===== MAIN JOB =====
    main_job_data = jobs_data.get(main_job, {})
    
    # Spells du main job (filtrés par level)
    main_spells = filter_by_level(main_job_data.get("spells", []), main_level)
    result["spells"].extend(main_spells)
    
    # Job Abilities du main job (filtrés par level)
    main_abilities = filter_by_level(main_job_data.get("job_abilities", []), main_level)
    result["job_abilities"].extend(main_abilities)
    
    # Pet commands
    result["pet_commands"] = main_job_data.get("pet_command", [])
    
    # Pet attacks (si pet actif)
    pet_attack_data = main_job_data.get("pet_attack", {})
    # print(f"[DEBUG] pet_name: {pet_name}")  # DÉSACTIVÉ
    # print(f"[DEBUG] pet_attack_data keys: {list(pet_attack_data.keys()) if pet_attack_data else 'None'}")  # DÉSACTIVÉ
    if pet_name and pet_name in pet_attack_data:
        result["pet_attacks"][pet_name] = pet_attack_data[pet_name]
        # print(f"[DEBUG] Found attacks for {pet_name}: {len(pet_attack_data[pet_name])} attacks")  # DÉSACTIVÉ
    elif pet_attack_data:
        # Si pas de pet spécifique, retourner tous les pets disponibles
        result["pet_attacks"] = pet_attack_data
        # print(f"[DEBUG] No specific pet, returning all {len(pet_attack_data)} pets")  # DÉSACTIVÉ
    
    # Macros
    result["macros"] = main_job_data.get("macro", [])
    
    # ===== SUB JOB =====
    if sub_job and sub_job != "?" and sub_level > 0:
        sub_job_data = jobs_data.get(sub_job, {})
        
        # Spells du sub job (filtrés par level)
        sub_spells = filter_by_level(sub_job_data.get("spells", []), sub_level)
        result["spells"].extend(sub_spells)
        
        # Job Abilities du sub job (filtrés par level)
        sub_abilities = filter_by_level(sub_job_data.get("job_abilities", []), sub_level)
        result["job_abilities"].extend(sub_abilities)
    
    # ===== WEAPON SKILLS =====
    result["weapon_skills"] = get_weapon_skills_for_type(weapon_type)
    
    # Dédoublonnage des sorts/abilities par name (garde le premier)
    seen_spells = set()
    unique_spells = []
    for spell in result["spells"]:
        name = spell.get("name", "")
        if name and name not in seen_spells:
            seen_spells.add(name)
            unique_spells.append(spell)
    result["spells"] = unique_spells
    
    seen_abilities = set()
    unique_abilities = []
    for ability in result["job_abilities"]:
        name = ability.get("name", "")
        if name and name not in seen_abilities:
            seen_abilities.add(name)
            unique_abilities.append(ability)
    result["job_abilities"] = unique_abilities
    
    return result

# ============ PET OVERLAY SOCKET ============

# 🗑️ Pet Overlay socket removed - now uses IPC (Lua → Lua) instead of TCP
# Extended (Lua) sends pet data directly to AltPetOverlay via windower.send_ipc_message()
# No need for Python to relay pet data anymore

# ============ BROADCAST WEBSOCKET ============

def broadcast_alt_update(alt_name):
    """
    Envoie une mise à jour WebSocket à tous les clients connectés
    quand un ALT change de job/arme/party/pet
    """
    if not socketio:
        return
    
    try:
        abilities = get_alt_abilities(alt_name)
        # 🆕 SOLUTION FINALE: Utiliser socketio.emit() sans broadcast
        # Flask-SocketIO broadcast automatiquement sur namespace='/'
        socketio.emit('alt_update', abilities, namespace='/')
        # print(f"[WEBSOCKET] Broadcast update for {alt_name}")  # DÉSACTIVÉ
    except Exception as e:
        print(f"[ERROR] Failed to broadcast update: {e}")
        import traceback
        traceback.print_exc()

# ============ GESTION DES ALT DATA FOLDER ============

def select_data_folder_popup():
    popup = tk.Toplevel()
    popup.title("ALT Data Location")
    popup.grab_set()
    popup.resizable(False, False)
    info = "Please select your ALT data folder.\nThis is the folder containing the .txt files generated by the Windower Addon (AltControl).\nExample: C:\\Games\\Windower4\\addons\\AltControl\\data"
    label = ttk.Label(popup, text=info, wraplength=380, justify="left")
    label.pack(padx=18, pady=(18,8))
    
    def choose_folder():
        path = filedialog.askdirectory(title="Select ALT data folder")
        if path and os.path.isdir(path):
            with open(CONFIG_PATH, "w") as f:
                f.write(path)
            popup.destroy()
            messagebox.showinfo("Folder Saved!", f"ALT data folder:\n{path}\nsaved for future launches.")
        else:
            messagebox.showerror("Error", "Invalid folder selected.")
    
    button = ttk.Button(popup, text="Load data location", command=choose_folder)
    button.pack(pady=18)
    popup.wait_window()

def get_data_folder():
    # 1. Try to read from config file
    if os.path.isfile(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            path = f.read().strip()
            if os.path.isdir(path):
                return path
    # 2. Ask user to choose folder
    root = tk.Tk()
    root.withdraw()
    select_data_folder_popup()
    # Check again after popup
    if os.path.isfile(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            path = f.read().strip()
            if os.path.isdir(path):
                return path
    return ""

DATA_ALT_DIR = get_data_folder()

# ============ SERVEUR LUA (RÉCEPTION DES DONNÉES DU JEU) ============

def handle_client(conn, addr):
    """Traite les connexions des alts (données envoyées par le Lua addon)"""
    global sch_autocast_active
    try:
        # 🆕 Augmenter le buffer pour recevoir les recasts (beaucoup de données)
        data = conn.recv(65536)  # 64KB au lieu de 4KB
        info = json.loads(data.decode())
        alt_name = info.get('name', 'UnknownAlt')
        alt_port = info.get('port', '????')
        alt_ip = addr[0]
        
        # Parser les données de la party et buffs
        party_raw = info.get("party", [])
        buffs_raw = info.get("active_buffs", [])
        
        # 🆕 CORRECTION: Parser correctement les buffs (DICT ou LIST)
        active_buffs = []
        if isinstance(buffs_raw, dict):
            # Format: {'1': 'Light Arts', '2': 'Haste'}
            # Trier par clé numérique pour garder l'ordre
            sorted_keys = sorted(buffs_raw.keys(), key=lambda x: int(x) if x.isdigit() else 999)
            for key in sorted_keys:
                buff = buffs_raw[key]
                if isinstance(buff, str) and buff.strip():
                    active_buffs.append(buff.strip())
        elif isinstance(buffs_raw, list):
            # Format: ['Light Arts', 'Haste']
            for buff in buffs_raw:
                if isinstance(buff, str) and buff.strip():
                    active_buffs.append(buff.strip())
        
        # 🆕 CORRECTION: Parser correctement la party (DICT ou LIST)
        party_members = []
        
        if isinstance(party_raw, dict):
            # Format: {'1': 'Name1', '2': 'Name2', '3': 'Name3'}
            # Trier par clé numérique pour garder l'ordre
            sorted_keys = sorted(party_raw.keys(), key=lambda x: int(x) if x.isdigit() else 999)
            for key in sorted_keys:
                name = party_raw[key]
                if isinstance(name, str) and name.strip():
                    party_members.append(name.strip())
                elif isinstance(name, dict):
                    member_name = name.get("name", "")
                    if member_name:
                        party_members.append(member_name)
        elif isinstance(party_raw, list):
            # Format: ['Name1', 'Name2', 'Name3']
            for member in party_raw:
                if isinstance(member, str) and member:
                    party_members.append(member)
                elif isinstance(member, dict):
                    name = member.get("name", "")
                    if name:
                        party_members.append(name)
        
        # print(f"[DEBUG] Party parsed: {party_members}")  # DÉSACTIVÉ
        
        # 🆕 Vérifier si c'est un update valide (éviter les bugs de timing FFXI)
        # Désactivé temporairement car il bloque trop d'updates
        # old_alt = alts.get(alt_name)
        # if old_alt:
        #     # Si la party change drastiquement (3→1 ou 1→3) en gardant le même job = bug temporaire
        #     old_party_size = len(old_alt.get("party", []))
        #     new_party_size = len(party_members)
        #     same_job = old_alt.get("main_job") == info.get("main_job")
        #     
        #     if same_job and abs(old_party_size - new_party_size) >= 2:
        #         print(f"[SKIP] Ignoring buggy update for {alt_name} (party size changed from {old_party_size} to {new_party_size} without job change)")
        #         return
        
        # Enregistrez TOUTES les infos utiles dans la dict ALT
        alts[alt_name] = {
            "name": alt_name,
            "ip": alt_ip,
            "port": alt_port,
            "main_job": info.get("main_job", "?"),
            "main_job_level": info.get("main_job_level", 1),
            "sub_job": info.get("sub_job", ""),
            "sub_job_level": info.get("sub_job_level", 0),
            "weapon_id": info.get("weapon_id", "0"),
            "weapon_type": get_weapon_type(info.get("weapon_id", "0")),
            "pet_name": info.get("pet_name", None),  # 🐾 Keep for Blood Pact menu filtering
            # 🗑️ Other pet data removed - now handled by AltPetOverlay
            # "pet_hp": info.get("pet_hp", 0),
            # "pet_hpp": info.get("pet_hpp", 0),
            # "pet_tp": info.get("pet_tp", 0),
            # "bst_ready_charges": info.get("bst_ready_charges", 0),
            "is_engaged": info.get("is_engaged", False),
            "party_engaged": info.get("party_engaged", False),  # 🆕 Quelqu'un dans la party en combat
            "is_moving": info.get("is_moving", False),  # 🆕 État de mouvement
            "is_casting": info.get("is_casting", False),  # 🆕 État de cast
            "active_buffs": active_buffs,  # 🆕 CORRECTION: Liste de buffs parsée
            "active_buff_ids": info.get("active_buff_ids", []),  # 🆕 IDs des buffs
            "ability_recasts": info.get("ability_recasts", {}),
            "spell_recasts": info.get("spell_recasts", {}),
            "party": party_members,  # 🆕 CORRECTION: Liste de noms
            "sch_autocast_active": sch_autocast_active if info.get("main_job") == "SCH" else False
        }
        

        # 🔇 Détecter les changements importants pour éviter le spam
        current_state = {
            "job": f"{alts[alt_name]['main_job']}{alts[alt_name]['main_job_level']}",
            "weapon": alts[alt_name]['weapon_type'],
            "engaged": alts[alt_name]['is_engaged'],
            "pet": alts[alt_name]['pet_name'],  # 🐾 Keep for Blood Pact menu
            "party_size": len(party_members)
        }
        
        last_state = last_logged_state.get(alt_name, {})
        has_changes = (
            current_state.get("job") != last_state.get("job") or
            current_state.get("weapon") != last_state.get("weapon") or
            current_state.get("engaged") != last_state.get("engaged") or
            current_state.get("pet") != last_state.get("pet") or
            current_state.get("party_size") != last_state.get("party_size")
        )
        
        # Afficher uniquement si changement ou première connexion (DÉSACTIVÉ pour réduire spam)
        if has_changes or alt_name not in last_logged_state:
            # print(f"\n[ALT UPDATE] '{alt_name}' at {alt_ip}:{alt_port}")
            # print(f"  Job/Sub: {alts[alt_name]['main_job']} {alts[alt_name]['main_job_level']} / {alts[alt_name]['sub_job']} {alts[alt_name]['sub_job_level']}")
            # print(f"  Weapon: {alts[alt_name]['weapon_type']} (ID: {info.get('weapon_id', '0')})")
            # print(f"  Engaged: {alts[alt_name]['is_engaged']}")
            
            # pet_name = alts[alt_name]["pet_name"]
            # if pet_name:
            #     pet_hpp = alts[alt_name]["pet_hpp"]
            #     pet_tp = alts[alt_name]["pet_tp"]
            #     print(f"  Active Pet: {pet_name} (HP: {pet_hpp}%, TP: {pet_tp})")
            
            # if party_members:
            #     print(f"  Party: {', '.join(party_members)}")
            # else:
            #     print(f"  Party: Empty or not in party")
            
            # # Afficher les buffs actifs (utile pour SCH)
            # active_buffs_display = alts[alt_name].get("active_buffs", [])
            # if active_buffs_display:
            #     print(f"  Active buffs: {active_buffs_display}")
            
            # Sauvegarder l'état actuel
            last_logged_state[alt_name] = current_state
        
        # 🆕 CORRECTION: Broadcast WebSocket aux clients connectés
        broadcast_alt_update(alt_name)
        
        # 🗑️ Pet data now sent via IPC (Lua → Lua), not via Python
        
        # 🆕 Vérifier si des casts en attente peuvent être envoyés
        process_pending_casts()
        
    except Exception as e:
        print(f"[ERROR] Client error {addr}: {e}")
        import traceback
        traceback.print_exc()
    finally:
        conn.close()

def server_lua_thread(stop_event):
    """Thread du serveur Lua (écoute les connexions des alts)"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST_LUA, PORT_LUA))
            s.listen()
            print(f"[LUA SERVER] Listening on {HOST_LUA}:{PORT_LUA}")
            while not stop_event.is_set():
                s.settimeout(1.0)
                try:
                    conn, addr = s.accept()
                except socket.timeout:
                    continue
                threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()
    except Exception as e:
        print("[LUA SERVER] Error:", e)

# ============ SERVEUR FLASK + SOCKETIO (API POUR LA WEBAPP) ============

app = Flask(__name__, static_folder=STATIC_DIR)
app.config['SECRET_KEY'] = 'ffxi-alt-control-secret'
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# --- Routes pour servir la webapp React ---

@app.route('/')
def root():
    return send_from_directory(STATIC_DIR, 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    file_path = os.path.join(STATIC_DIR, path)
    if os.path.isfile(file_path):
        return send_from_directory(STATIC_DIR, path)
    return send_from_directory(STATIC_DIR, 'index.html')

# --- Routes API ---

@app.route('/all-alts')
def all_alts():
    """Retourne la liste de tous les alts connectés avec leurs infos de base"""
    return jsonify({"alts": list(alts.values())})

@app.route('/api/pets')
def get_pets():
    """Retourne les infos de tous les pets actifs"""
    pets_data = []
    for alt_name, alt_data in alts.items():
        pet_name = alt_data.get("pet_name")
        if pet_name:
            # Calculer le max HP depuis le pourcentage
            pet_hp = alt_data.get("pet_hp", 0)
            pet_hpp = alt_data.get("pet_hpp", 100)
            max_hp = int((pet_hp * 100) / pet_hpp) if pet_hpp > 0 else 1000
            
            pet_info = {
                "owner": alt_name,
                "name": pet_name,
                "hp": pet_hp,
                "max_hp": max_hp,
                "tp": alt_data.get("pet_tp", 0)
            }
            
            # Ajouter les infos spécifiques au job
            main_job = alt_data.get("main_job", "")
            if main_job == "BST":
                pet_info["charges"] = alt_data.get("bst_ready_charges", 0)
            elif main_job == "SMN":
                # Récupérer le recast du Blood Pact (ID 173)
                ability_recasts = alt_data.get("ability_recasts", {})
                bp_timer = ability_recasts.get("173", 0)
                pet_info["bp_timer"] = bp_timer
            elif main_job == "DRG":
                # Récupérer le recast du Healing Breath (ID 163)
                ability_recasts = alt_data.get("ability_recasts", {})
                breath_timer = ability_recasts.get("163", 0)
                pet_info["breath_ready"] = breath_timer <= 0
            
            pets_data.append(pet_info)
    
    return jsonify({"pets": pets_data})

@app.route('/alt-abilities/<alt_name>')
def alt_abilities(alt_name):
    """
    Retourne TOUTES les capacités disponibles pour un ALT spécifique
    (sorts, abilities, WS, pet attacks, PARTY filtrés par job/level/arme)
    """
    abilities = get_alt_abilities(alt_name)
    return jsonify(abilities)

@app.route('/jobs')
def all_jobs():
    """Retourne la liste de tous les jobs disponibles"""
    return jsonify({"jobs": list(jobs_data.keys())})

@app.route('/job-data/<job_abbrev>')
def job_data(job_abbrev):
    """Retourne les données complètes d'un job (sans filtrage)"""
    job = jobs_data.get(job_abbrev.upper(), {})
    return jsonify(job)

@app.route('/weapon-skills')
def all_weapon_skills():
    """Retourne tous les weapon skills"""
    return jsonify(ws_data)

@app.route('/weapon-skills/<weapon_type>')
def weapon_skills_by_type(weapon_type):
    """Retourne les weapon skills pour un type d'arme spécifique"""
    ws_list = get_weapon_skills_for_type(weapon_type)
    return jsonify({"weapon_type": weapon_type, "weapon_skills": ws_list})

@app.route('/command', methods=['POST'])
def receive_command():
    """Reçoit une commande de la webapp et l'envoie à un ALT"""
    try:
        data = request.json
        alt_name = data.get("altName") or data.get("altId")
        action = data.get("action") or data.get("command")
        
        if not alt_name or not action:
            return jsonify({
                "success": False, 
                "error": "Missing altName or action"
            }), 400
        
        ok = send_command_to_alt(alt_name, action)
        return jsonify({"success": ok})
    except Exception as e:
        print("[ERROR] receive_command:", e)
        return jsonify({"success": False, "error": str(e)}), 400

@app.route('/reload-data', methods=['POST'])
def reload_data():
    """Recharge tous les fichiers JSON (jobs.json, ws.json, item_types.json)"""
    try:
        load_item_types()
        load_jobs_data()
        load_ws_data()
        return jsonify({
            "success": True,
            "message": "JSON data reloaded successfully"
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/party/roles', methods=['GET'])
def get_party_roles():
    """Récupère les rôles de la party (main character, etc.)"""
    try:
        roles_file = os.path.join(DIR_JSON, "party_roles.json")
        
        if not os.path.exists(roles_file):
            return jsonify({"main_character": ""})
        
        with open(roles_file, 'r', encoding='utf-8') as f:
            roles = json.load(f)
        
        return jsonify(roles)
    except Exception as e:
        print(f"[ERROR] get_party_roles: {e}")
        return jsonify({"main_character": ""})

@app.route('/party/roles', methods=['POST'])
def save_party_roles():
    """Sauvegarde les rôles de la party (main character, etc.)"""
    try:
        roles = request.json
        
        if not roles or 'main_character' not in roles:
            return jsonify({
                "success": False,
                "error": "Invalid roles data"
            }), 400
        
        roles_file = os.path.join(DIR_JSON, "party_roles.json")
        
        with open(roles_file, 'w', encoding='utf-8') as f:
            json.dump(roles, f, indent=2, ensure_ascii=False)
        
        # Copier vers Windower pour que Lua puisse le lire
        windower_path = "A:/Jeux/PlayOnline/Windower4/addons/data_json/party_roles.json"
        try:
            os.makedirs(os.path.dirname(windower_path), exist_ok=True)
            with open(windower_path, 'w', encoding='utf-8') as f:
                json.dump(roles, f, indent=2, ensure_ascii=False)
            print(f"[PARTY ROLES] Saved to Windower: {roles}")
        except Exception as e:
            print(f"[WARNING] Could not copy to Windower: {e}")
        
        print(f"[PARTY ROLES] Saved: {roles}")
        
        return jsonify({
            "success": True,
            "message": "Party roles saved successfully"
        })
    except Exception as e:
        print(f"[ERROR] save_party_roles: {e}")
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/config/<alt_name>/<main_job>/<sub_job>', methods=['GET'])
def get_config(alt_name, main_job, sub_job):
    """Récupère la configuration d'un ALT depuis le serveur"""
    try:
        config_file = os.path.join(DIR_JSON, "alt_configs.json")
        config_key = f"{alt_name}_{main_job}_{sub_job}"
        
        print(f"[CONFIG] GET request for {config_key}")
        
        if not os.path.exists(config_file):
            print(f"[CONFIG] Config file not found")
            return jsonify(None)
        
        with open(config_file, 'r', encoding='utf-8') as f:
            all_configs = json.load(f)
        
        if config_key in all_configs:
            print(f"[CONFIG] Found config for {config_key}")
            return jsonify(all_configs[config_key])
        else:
            print(f"[CONFIG] No config found for {config_key}")
            print(f"[CONFIG] Available configs: {list(all_configs.keys())}")
            return jsonify(None)
    except Exception as e:
        print(f"[ERROR] get_config: {e}")
        import traceback
        traceback.print_exc()
        return jsonify(None)

@app.route('/config', methods=['POST'])
def save_config():
    """Sauvegarde la configuration d'un ALT sur le serveur"""
    try:
        config = request.json
        
        if not config or 'alt_name' not in config:
            return jsonify({
                "success": False,
                "error": "Invalid config data"
            }), 400
        
        config_file = os.path.join(DIR_JSON, "alt_configs.json")
        
        # Charger les configs existantes
        all_configs = {}
        if os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                all_configs = json.load(f)
        
        # Clé unique pour cet ALT
        config_key = f"{config['alt_name']}_{config['main_job']}_{config['sub_job']}"
        
        # Sauvegarder la config
        all_configs[config_key] = config
        
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(all_configs, f, indent=2, ensure_ascii=False)
        
        print(f"[CONFIG] Saved config for {config_key}")
        
        # Broadcaster la mise à jour à tous les clients connectés
        socketio.emit('config_updated', config, namespace='/')
        
        return jsonify({
            "success": True,
            "message": "Config saved successfully"
        })
    except Exception as e:
        print(f"[ERROR] save_config: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/party/members', methods=['GET'])
def party_members():
    """Retourne la liste de tous les membres de party connectés"""
    try:
        members = set()
        for alt_data in alts.values():
            members.add(alt_data.get("name"))
            party = alt_data.get("party", [])
            for member in party:
                if member:
                    members.add(member)
        return jsonify({"members": sorted(list(members))})
    except Exception as e:
        print(f"[ERROR] party_members: {e}")
        return jsonify({"members": []}), 500

@app.route('/sch/autocast', methods=['POST'])
def sch_autocast():
    """Start/Stop le SCH AutoCast"""
    global sch_autocast_active
    
    try:
        data = request.json
        action = data.get('action')
        
        if action == 'start':
            sch_autocast_active = True
            print("[SCH Manager] ✅ Activated")
            return jsonify({"success": True, "message": "SCH AutoCast started"})
        elif action == 'stop':
            sch_autocast_active = False
            print("[SCH Manager] 🛑 Deactivated")
            return jsonify({"success": True, "message": "SCH AutoCast stopped"})
        else:
            return jsonify({"success": False, "error": "Invalid action"}), 400
    except Exception as e:
        print(f"[ERROR] sch_autocast: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/brd/autocast', methods=['POST'])
def brd_autocast():
    """Start/Stop le BRD AutoCast"""
    global brd_autocast_active
    
    try:
        data = request.json
        action = data.get('action')
        
        if action == 'start':
            brd_autocast_active = True
            print("[BRD Manager] ✅ Activated")
            return jsonify({"success": True, "message": "BRD AutoCast started"})
        elif action == 'stop':
            brd_autocast_active = False
            print("[BRD Manager] 🛑 Deactivated")
            return jsonify({"success": True, "message": "BRD AutoCast stopped"})
        else:
            return jsonify({"success": False, "error": "Invalid action"}), 400
    except Exception as e:
        print(f"[ERROR] brd_autocast: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/autocast/config', methods=['POST', 'GET'])
def autocast_config():
    """Gère la configuration AutoCast (BRD, WHM, etc.)"""
    config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
    
    if request.method == 'POST':
        try:
            config = request.json
            with open(config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
            print(f"[AUTOCAST CONFIG] Saved to {config_file}")
            return jsonify({"success": True, "message": "AutoCast config saved successfully"})
        except Exception as e:
            print(f"[ERROR] autocast_config POST: {e}")
            return jsonify({"success": False, "error": str(e)}), 500
    else:
        try:
            if os.path.exists(config_file):
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                return jsonify(config)
            else:
                return jsonify({})
        except Exception as e:
            print(f"[ERROR] autocast_config GET: {e}")
            return jsonify({}), 500

@app.route('/buffs/update', methods=['POST'])
def update_buffs():
    """Reçoit les buffs d'un personnage et les stocke"""
    global player_buffs
    try:
        data = request.json
        player_name = data.get('player_name')
        buffs = data.get('buffs', [])
        
        if player_name:
            player_buffs[player_name] = buffs
            print(f"[BUFFS] Updated for {player_name}: {len(buffs)} buffs")
            return jsonify({"success": True})
        else:
            return jsonify({"success": False, "error": "Missing player_name"}), 400
    except Exception as e:
        print(f"[ERROR] update_buffs: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/buffs/<player_name>', methods=['GET'])
def get_buffs(player_name):
    """Récupère les buffs d'un personnage"""
    global player_buffs
    try:
        buffs = player_buffs.get(player_name, [])
        return jsonify({"player_name": player_name, "buffs": buffs})
    except Exception as e:
        print(f"[ERROR] get_buffs: {e}")
        return jsonify({"player_name": player_name, "buffs": []}), 500

# --- WebSocket Events ---

@socketio.on('connect')
def handle_connect():
    """Quand un client webapp se connecte au WebSocket"""
    print(f"[WEBSOCKET] Client connected")
    # Envoyer immédiatement la liste des alts au nouveau client
    socketio_emit('all_alts', {"alts": list(alts.values())}, namespace='/')

@socketio.on('disconnect')
def handle_disconnect():
    """Quand un client webapp se déconnecte"""
    print(f"[WEBSOCKET] Client disconnected")

@socketio.on('request_alt_data')
def handle_request_alt_data(data):
    """Quand la webapp demande les données d'un ALT spécifique"""
    alt_name = data.get('alt_name')
    if alt_name:
        abilities = get_alt_abilities(alt_name)
        socketio_emit('alt_data', abilities, namespace='/')

# ============ GESTION DES COMMANDES AUX ALTS ============

def load_alts_from_data_folder():
    """Charge les ports des alts depuis le dossier data"""
    if not DATA_ALT_DIR or not os.path.exists(DATA_ALT_DIR):
        print(f"[WARN] ALT folder '{DATA_ALT_DIR}' missing, check settings.")
        return
    
    for filename in os.listdir(DATA_ALT_DIR):
        if filename.endswith(".txt"):
            alt_name = filename.rsplit(".", 1)[0]
            try:
                with open(os.path.join(DATA_ALT_DIR, filename)) as f:
                    port = f.read().strip()
                    # On ne connait que le port et le nom au début
                    if alt_name not in alts:
                        alts[alt_name] = {
                            "name": alt_name,
                            "ip": "127.0.0.1",
                            "port": port,
                            "main_job": "?",
                            "main_job_level": 1,
                            "sub_job": "",
                            "sub_job_level": 0,
                            "weapon_id": "0",
                            "weapon_type": "Unknown",
                            "pet_name": None,
                            "party": []
                        }
            except Exception as e:
                print(f"[ERROR] Loading ALT port for {filename}: {e}")

def send_reload_command_to_all_alts_with_file_scan():
    """Recharge les alts et envoie la commande de reload à tous"""
    load_alts_from_data_folder()
    for alt in alts.values():
        try:
            ip = alt.get("ip", "127.0.0.1")
            port = int(alt.get("port", 0))
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.connect((ip, port))
                s.sendall(f"//lua r AltControl\n".encode())
                print(f"[RELOAD] Command sent to {alt['name']} ({ip}:{port})")
        except Exception as e:
            print(f"[ERROR] Failed to reload {alt['name']} ({ip}:{port}): {e}")
    
    # 🆕 Si le serveur est actif, recharger Extended après 2 secondes
    if servers_running:
        import time
        time.sleep(2)
        print("[RELOAD] 🚀 Reloading Extended features...")
        for alt_name in list(alts.keys()):
            send_command_to_alt(alt_name, '//ac load_extended')
            time.sleep(0.1)
        print("[RELOAD] ✅ Extended reloaded on all alts")

# 🆕 File d'attente des casts en attente (par alt)
pending_casts = {}

def process_pending_casts():
    """Vérifie si des casts en attente peuvent être envoyés"""
    for alt_name in list(pending_casts.keys()):
        alt = alts.get(alt_name)
        if not alt:
            # Alt n'existe plus, supprimer de la file
            del pending_casts[alt_name]
            continue
        
        is_moving = alt.get('is_moving', False)
        
        if not is_moving:
            # Le perso s'est arrêté, envoyer le cast en attente
            command = pending_casts[alt_name]
            del pending_casts[alt_name]
            
            ip = alt.get("ip", "127.0.0.1")
            port = int(alt.get("port", 0))
            
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.connect((ip, port))
                    s.sendall((command + "\n").encode())
                    print(f"[COMMAND] ✅ Sent queued cast: '{command}' → {alt_name}")
            except Exception as e:
                print(f"[ERROR] Failed to send queued cast to {alt_name}: {e}")

def send_command_to_alt(alt_name, command):
    """Envoie une commande à un ALT spécifique"""
    alt = alts.get(alt_name)
    if not alt:
        print(f"[ERROR] ALT '{alt_name}' not found.")
        return False
    
    # 🆕 Si c'est un cast ET que le perso est en mouvement → METTRE EN FILE D'ATTENTE
    is_cast = command.strip().startswith('/ma ') or command.strip().startswith('/ja ')
    is_moving = alt.get('is_moving', False)
    
    # 🐛 DEBUG: Afficher l'état pour comprendre
    if is_cast:
        print(f"[DEBUG] Cast command for {alt_name}: is_moving={is_moving}, command={command.strip()}")
    
    if is_cast and is_moving:
        # Mettre en file d'attente (remplacer si déjà un cast en attente)
        pending_casts[alt_name] = command.strip()
        print(f"[COMMAND] 📋 Queued cast for {alt_name} (will cast when stopped)")
        return True  # Retourner True pour indiquer que la commande est acceptée
    
    ip = alt.get("ip", "127.0.0.1")
    port = int(alt.get("port", 0))
    
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((ip, port))
            s.sendall((command.strip() + "\n").encode())
            print(f"[COMMAND] '{command}' → {alt_name} ({ip}:{port})")
            return True
    except Exception as e:
        print(f"[ERROR] Failed to send command to {alt_name}: {e}")
        return False

# ============ THREAD FLASK + SOCKETIO ============

def server_flask_thread(stop_event):
    """Thread du serveur Flask + SocketIO"""
    try:
        print("[FLASK+SOCKETIO] Starting on http://0.0.0.0:5000")
        socketio.run(app, debug=False, port=5000, host='0.0.0.0', use_reloader=False, allow_unsafe_werkzeug=True)
    except Exception as e:
        print("[FLASK SERVER] Error:", e)

# ============ GUI DE CONTRÔLE ============

class ServerControlGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("FFXI ALT Server Control")

        self.lua_status = tk.StringVar(value="OFF")
        self.flask_status = tk.StringVar(value="OFF")

        frame = ttk.Frame(self.root, padding=20)
        frame.pack()

        ttk.Label(frame, text="Lua Server:").grid(row=0, column=0, sticky="w", padx=12)
        self.label_lua = ttk.Label(frame, textvariable=self.lua_status, foreground="red", font=("Arial", 14, "bold"))
        self.label_lua.grid(row=0, column=1, padx=10)
        
        ttk.Label(frame, text="Flask+WebSocket:").grid(row=1, column=0, sticky="w", padx=12)
        self.label_flask = ttk.Label(frame, textvariable=self.flask_status, foreground="red", font=("Arial", 14, "bold"))
        self.label_flask.grid(row=1, column=1, padx=10)

        self.button_onoff = ttk.Button(frame, text="ON / OFF Servers", command=self.toggle_servers)
        self.button_onoff.grid(row=2, column=0, columnspan=2, pady=10)

        self.button_refresh = ttk.Button(frame, text="Refresh ALT", command=send_reload_command_to_all_alts_with_file_scan)
        self.button_refresh.grid(row=3, column=0, columnspan=2, pady=10)

        self.button_load_data = ttk.Button(frame, text="Change ALT data location", command=self.change_data_location)
        self.button_load_data.grid(row=4, column=0, columnspan=2, pady=4)

        self.button_reload_json = ttk.Button(frame, text="Reload JSON Data", command=self.reload_json_data)
        self.button_reload_json.grid(row=5, column=0, columnspan=2, pady=4)

        self.lua_status.set("OFF")
        self.label_lua.config(foreground="red")
        self.flask_status.set("OFF")
        self.label_flask.config(foreground="red")

        self.root.protocol("WM_DELETE_WINDOW", self.on_exit)
        self.stop_event_lua = threading.Event()
        self.stop_event_flask = threading.Event()

    def toggle_servers(self):
        global servers_running, lua_thread, flask_thread
        if not servers_running:
            self.lua_status.set("ON")
            self.label_lua.config(foreground="green")
            self.flask_status.set("ON")
            self.label_flask.config(foreground="green")
            
            self.stop_event_lua.clear()
            self.stop_event_flask.clear()
            
            lua_thread = threading.Thread(target=server_lua_thread, args=(self.stop_event_lua,), daemon=True)
            flask_thread = threading.Thread(target=server_flask_thread, args=(self.stop_event_flask,), daemon=True)
            brd_thread = threading.Thread(target=run_brd_manager_loop, args=(self.stop_event_lua,), daemon=True)
            sch_thread = threading.Thread(target=run_sch_manager_loop, args=(self.stop_event_lua,), daemon=True)
            
            lua_thread.start()
            flask_thread.start()
            brd_thread.start()
            sch_thread.start()
            
            servers_running = True
            
            # 🆕 Charger Extended après le reload
            def load_extended_after_reload():
                send_reload_command_to_all_alts_with_file_scan()
                # Attendre 2 secondes que le reload se termine
                self.root.after(2000, self.load_extended_on_all_alts)
            
            self.root.after(1500, load_extended_after_reload)
        else:
            print("[INFO] Stopping servers...")
            
            # 🆕 Décharger Extended avant d'arrêter
            self.unload_extended_on_all_alts()
            
            # Attendre 1 seconde que le unload se termine
            import time
            time.sleep(1)
            
            self.stop_event_lua.set()
            self.stop_event_flask.set()
            self.lua_status.set("OFF")
            self.label_lua.config(foreground="red")
            self.flask_status.set("OFF")
            self.label_flask.config(foreground="red")
            servers_running = False
    
    def load_extended_on_all_alts(self):
        """Charge Extended sur tous les alts connectés"""
        print("[INFO] 🚀 Loading Extended features on all alts...")
        for alt_name in list(alts.keys()):
            send_command_to_alt(alt_name, '//ac load_extended')
            import time
            time.sleep(0.1)  # Petit délai entre chaque alt
        print("[INFO] ✅ Extended loaded on all alts")
    
    def unload_extended_on_all_alts(self):
        """Décharge Extended sur tous les alts connectés"""
        print("[INFO] 🛑 Unloading Extended features on all alts...")
        for alt_name in list(alts.keys()):
            send_command_to_alt(alt_name, '//ac unload_extended')
            import time
            time.sleep(0.1)  # Petit délai entre chaque alt
        print("[INFO] ✅ Extended unloaded on all alts")

    def change_data_location(self):
        result = filedialog.askdirectory(title="Select ALT data folder")
        if result and os.path.isdir(result):
            with open(CONFIG_PATH, "w") as f:
                f.write(result)
            global DATA_ALT_DIR
            DATA_ALT_DIR = result
            messagebox.showinfo("ALT data location saved", f"ALT data folder set to:\n{DATA_ALT_DIR}")
        else:
            messagebox.showerror("Error", "Invalid folder selected.")

    def reload_json_data(self):
        """Bouton pour recharger les fichiers JSON manuellement"""
        try:
            load_item_types()
            load_jobs_data()
            load_ws_data()
            messagebox.showinfo("Success", "JSON data reloaded successfully!")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to reload JSON data:\n{e}")

    def on_exit(self):
        print("[EXIT] Shutting down...")
        self.stop_event_lua.set()
        self.stop_event_flask.set()
        self.root.destroy()
        os._exit(0)

    def run(self):
        self.root.mainloop()

# ============ SCH MANAGER - POSITIONNEMENT AUTO ============

sch_autocast_active = False
brd_autocast_active = False  # 🆕 Pour le BRD

def run_sch_manager_loop(stop_event):
    """Thread SCH Manager - Gère le positionnement avec DistanceFollow"""
    import time
    global sch_autocast_active
    
    print("[SCH Manager] 📚 Started")
    last_state = None
    was_active = False
    
    while not stop_event.is_set():
        try:
            if not sch_autocast_active:
                # Si on était actif, arrêter et unload
                if was_active:
                    sch_name = None
                    for name, data in alts.items():
                        if data.get("main_job") == "SCH":
                            sch_name = name
                            break
                    
                    if sch_name:
                        print("[SCH Manager] 🛑 Stopping and unloading DistanceFollow...")
                        send_command_to_alt(sch_name, '/console send @sch //dfollow stop')
                        time.sleep(0.3)
                        send_command_to_alt(sch_name, '/console send @sch //lua unload DistanceFollow')
                    
                    was_active = False
                    last_state = None
                
                time.sleep(1)
                continue
            
            # Si on vient d'activer, charger l'addon
            if not was_active:
                was_active = True
                sch_name = None
                for name, data in alts.items():
                    if data.get("main_job") == "SCH":
                        sch_name = name
                        break
                
                if sch_name:
                    print("[SCH Manager] 🚀 Loading DistanceFollow...")
                    send_command_to_alt(sch_name, '/console send @sch //lua load DistanceFollow')
                    time.sleep(0.5)
                
                continue
            
            # Trouver le SCH
            sch_name = None
            for name, data in alts.items():
                if data.get("main_job") == "SCH":
                    sch_name = name
                    break
            
            if not sch_name:
                time.sleep(1)
                continue
            
            # Vérifier si Dexterbrown est engagé
            dex_engaged = alts.get("Dexterbrown", {}).get("is_engaged", False)
            current_state = 'engaged' if dex_engaged else 'disengaged'
            
            # Si l'état a changé, ajuster la distance
            if current_state != last_state:
                if current_state == 'engaged':
                    print(f"[SCH Manager] ⚔️ Engaged! Moving to 15-20 yalms")
                    send_command_to_alt(sch_name, '/console send @sch //dfollow follow Dexterbrown 15 20')
                else:
                    print(f"[SCH Manager] 🏠 Disengaged! Moving to 0.5-1 yalm")
                    send_command_to_alt(sch_name, '/console send @sch //dfollow follow Dexterbrown 0.5 1')
                
                last_state = current_state
            
        except Exception as e:
            print(f"[SCH Manager] ❌ Error: {e}")
        
        time.sleep(0.5)
    
    print("[SCH Manager] 📚 Stopped")

# ============ BRD MANAGER - VERSION SIMPLE ============

def run_brd_manager_loop(stop_event):
    """Thread BRD Manager - BASÉ SUR LES BUFFS"""
    import time
    print("[BRD Manager] 🎵 Started")
    
    last_check = 0
    waiting_for_buffs = False
    waiting_since = 0
    songs_cast = 0  # Combien de songs ont été castés
    next_phase = None
    current_phase = "mage"  # mage ou melee
    engage_time = 0  # Quand l'engagement a commencé
    was_active = False  # 🆕 Pour détecter les changements d'état
    cycle_start_time = 0  # 🆕 Pour détecter les cycles bloqués
    
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
            
            # 🆕 Vérifier si l'AutoCast du BRD est actif
            if not brd_autocast_active:
                # AutoCast désactivé, reset l'état
                if was_active:
                    print("[BRD Manager] 🛑 Deactivated - Resetting state")
                    was_active = False
                time.sleep(1)
                continue
            
            # 🆕 Si on vient d'activer, reset toutes les variables
            if not was_active:
                print("[BRD Manager] ✅ Activated - Resetting cycle")
                last_check = 0
                waiting_for_buffs = False
                waiting_since = 0
                songs_cast = 0
                next_phase = None
                current_phase = "mage"
                engage_time = 0
                was_active = True
            
            # Vérifier si quelqu'un est engagé
            someone_engaged = any(d.get("is_engaged") or d.get("party_engaged") for d in alts.values())
            
            if not someone_engaged:
                # Personne engagé → RESET COMPLET du cycle
                # RESET toutes les variables pour repartir propre
                waiting_for_buffs = False
                waiting_inactive = False
                next_phase = None
                current_phase = "mage"  # Retour à la phase mage
                songs_cast = 0
                last_check = 0
                engage_time = 0  # Reset engage time
                
                # 🆕 IMPORTANT: Relancer le follow vers le healer si on a désengagé
                config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
                if os.path.exists(config_file):
                    with open(config_file, 'r', encoding='utf-8') as f:
                        config = json.load(f).get("BRD", {})
                    healer = config.get("healerTarget")
                    if healer:
                        send_command_to_alt(brd_name, f'//ac follow {healer}')
                        print(f"[BRD Manager] 🔄 Cycle reset (desengage) - Following {healer}")
                
                time.sleep(5)
                continue
            
            # Si on vient d'engager, attendre 2 sec avant de commencer
            if engage_time == 0:
                engage_time = current_time
                print("[BRD Manager] ⏳ Engaged! Waiting 2s before starting...")
                time.sleep(2)
                continue
            
            # Debug désactivé pour production
            # print(f"[BRD Manager] 🐛 State: waiting_for_buffs={waiting_for_buffs}, current_phase={current_phase}, songs_cast={songs_cast}")
            
            # 🆕 Sécurité: Si le cycle est bloqué depuis trop longtemps (30s), forcer un reset
            if waiting_for_buffs and cycle_start_time > 0:
                if current_time - cycle_start_time > 30:
                    print("[BRD Manager] ⚠️ Cycle bloqué depuis 30s, reset forcé!")
                    waiting_for_buffs = False
                    songs_cast = 0
                    cycle_start_time = 0
                    # Relancer le follow vers le healer
                    config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
                    if os.path.exists(config_file):
                        with open(config_file, 'r', encoding='utf-8') as f:
                            config = json.load(f).get("BRD", {})
                        healer = config.get("healerTarget")
                        if healer:
                            send_command_to_alt(brd_name, f'//ac follow {healer}')
                    time.sleep(2)
                    continue
            
            # Charger config (toujours nécessaire)
            config_file = "A:/Jeux/PlayOnline/Windower4/addons/AltControl/data/autocast_config.json"
            if not os.path.exists(config_file):
                time.sleep(1)
                continue
            
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f).get("BRD", {})
            
            healer = config.get("healerTarget")
            melee = config.get("meleeTarget")
            mage_songs = config.get("mageSongs", [])
            melee_songs = config.get("meleeSongs", [])
            
            # Si on attend les buffs
            if waiting_for_buffs:
                # Vérifier les buffs selon la phase
                if current_phase == "mage" and healer in alts:
                    healer_buffs = alts[healer].get("active_buffs", [])
                    # Compter TOUS les buffs BRD (pas juste les types)
                    buff_count = sum([
                        1 for b in healer_buffs if "Ballad" in b or "March" in b or "Paeon" in b
                    ])
                    
                    # Debug: print(f"[BRD Manager] 🐛 Mage: buff_count={buff_count}, songs_cast={songs_cast}")
                    
                    if buff_count >= 2:
                        # Les 2 buffs sont là, phase suivante
                        print(f"[BRD Manager] ✅ 2 mage buffs OK, next phase: melee")
                        waiting_for_buffs = False
                        songs_cast = 0
                        current_phase = "melee"
                        last_check = 0
                    elif buff_count >= songs_cast and songs_cast < 2:
                        # Le buff du song précédent est apparu, caster le suivant
                        print(f"[BRD Manager] ✅ Buff {songs_cast} OK, casting song {songs_cast + 1}")
                        send_command_to_alt(brd_name, f'//ac cast "{mage_songs[songs_cast]}" <me>')
                        songs_cast += 1
                        waiting_since = current_time
                    elif current_time - waiting_since > 10:
                        # Timeout 10 sec, réessayer
                        print(f"[BRD Manager] ⚠️ Timeout, retrying song {songs_cast}")
                        send_command_to_alt(brd_name, f'//ac cast "{mage_songs[songs_cast - 1]}" <me>')
                        waiting_since = current_time
                
                elif current_phase == "melee" and melee in alts:
                    melee_buffs = alts[melee].get("active_buffs", [])
                    # Compter TOUS les buffs BRD (pas juste les types)
                    buff_count = sum([
                        1 for b in melee_buffs if "Minuet" in b or "Madrigal" in b or "Mambo" in b
                    ])
                    
                    # Debug: print(f"[BRD Manager] 🐛 Melee: buff_count={buff_count}, songs_cast={songs_cast}")
                    
                    if buff_count >= 2:
                        # Les 2 buffs sont là, retour healer
                        print(f"[BRD Manager] ✅ 2 melee buffs OK, returning to healer")
                        if healer:
                            send_command_to_alt(brd_name, f'//ac follow {healer}')
                            # 🆕 Petit déplacement latéral pour ne pas fusionner avec le healer
                            time.sleep(1.5)  # Attendre que le BRD arrive près du healer
                            send_command_to_alt(brd_name, '//setkey numpad4 down;wait 0.3;setkey numpad4 up')
                            print(f"[BRD Manager] ↔️ Positioning slightly left of healer")
                            # 🆕 Se retourner pour regarder vers le melee/combat
                            time.sleep(0.3)
                            send_command_to_alt(brd_name, '//setkey numpad2 down;wait 0.1;setkey numpad2 up')
                            print(f"[BRD Manager] 👀 Turning to face combat")
                        waiting_for_buffs = False
                        songs_cast = 0
                        current_phase = "mage"
                        last_check = 0
                    elif buff_count >= songs_cast and songs_cast < 2:
                        # Le buff du song précédent est apparu, caster le suivant
                        print(f"[BRD Manager] ✅ Buff {songs_cast} OK, casting song {songs_cast + 1}")
                        send_command_to_alt(brd_name, f'//ac cast "{melee_songs[songs_cast]}" <me>')
                        songs_cast += 1
                        waiting_since = current_time
                    elif current_time - waiting_since > 10:
                        # Timeout 10 sec, réessayer
                        print(f"[BRD Manager] ⚠️ Timeout, retrying song {songs_cast}")
                        send_command_to_alt(brd_name, f'//ac cast "{melee_songs[songs_cast - 1]}" <me>')
                        waiting_since = current_time
                
                time.sleep(1)
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
            
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f).get("BRD", {})
            
            healer = config.get("healerTarget")
            melee = config.get("meleeTarget")
            mage_songs = config.get("mageSongs", [])
            melee_songs = config.get("meleeSongs", [])
            
            if not healer or not melee or len(mage_songs) < 2 or len(melee_songs) < 2:
                time.sleep(1)
                continue
            
            # Check mage buffs
            if current_phase == "mage" and healer in alts:
                healer_buffs = alts[healer].get("active_buffs", [])
                # Compter TOUS les buffs BRD
                buff_count = sum([
                    1 for b in healer_buffs if "Ballad" in b or "March" in b or "Paeon" in b
                ])
                
                if buff_count < 2:
                    print(f"[BRD Manager] 🎵 Mage buffs missing ({buff_count}/2) - Starting from song 1")
                    # TOUJOURS commencer par le premier song
                    songs_cast = 0  # Reset pour recommencer
                    send_command_to_alt(brd_name, f'//ac cast "{mage_songs[0]}" <me>')
                    songs_cast = 1
                    waiting_for_buffs = True
                    waiting_since = current_time
                    cycle_start_time = current_time  # 🆕 Démarrer le timer du cycle
                    continue
            
            # Check melee buffs
            if current_phase == "melee" and melee in alts:
                melee_buffs = alts[melee].get("active_buffs", [])
                # Compter TOUS les buffs BRD
                buff_count = sum([
                    1 for b in melee_buffs if "Minuet" in b or "Madrigal" in b or "Mambo" in b
                ])
                
                if buff_count < 2:
                    print(f"[BRD Manager] ⚔️ Melee buffs missing ({buff_count}/2) - Starting from song 1")
                    # TOUJOURS commencer par le premier song
                    songs_cast = 0  # Reset pour recommencer
                    
                    # Follow le melee
                    send_command_to_alt(brd_name, f'//ac follow {melee} 2')
                    
                    # Attendre 4 secondes que le BRD se rapproche
                    print(f"[BRD Manager] ⏳ Waiting 4s for BRD to reach melee...")
                    time.sleep(4)
                    
                    # ARRÊTER le follow avec setkey (simule la touche)
                    send_command_to_alt(brd_name, '//setkey numpad7 down;wait 0.1;setkey numpad7 up')
                    print(f"[BRD Manager] 🛑 Follow stopped with setkey")
                    
                    # Attendre 0.3s que l'arrêt soit effectif
                    time.sleep(0.3)
                    
                    # Reculer un peu pour pas rester collé
                    send_command_to_alt(brd_name, '//setkey numpad2 down;wait 0.2;setkey numpad2 up')
                    print(f"[BRD Manager] ⬅️ Backing up slightly")
                    
                    # Attendre 0.5s que le recul soit fini
                    time.sleep(0.5)
                    
                    # Caster le premier song
                    send_command_to_alt(brd_name, f'//ac cast "{melee_songs[0]}" <me>')
                    songs_cast = 1
                    waiting_for_buffs = True
                    waiting_since = current_time
                    cycle_start_time = current_time  # 🆕 Démarrer le timer du cycle
                    continue
            
            print("[BRD Manager] ✅ All buffs OK")
            
        except Exception as e:
            print(f"[BRD Manager] ❌ Error: {e}")
            import traceback
            traceback.print_exc()
        
        time.sleep(1)
    
    print("[BRD Manager] 🎵 Stopped")

# ============ MAIN ============

if __name__ == "__main__":
    gui = ServerControlGUI()
    gui.run()