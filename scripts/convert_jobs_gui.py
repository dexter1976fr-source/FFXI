#!/usr/bin/env python3
# convert_jobs_optimized.py
# Convertisseur JSON FFXI - Garde TOUS les détails (level, mp, element, etc.)

import json
import os
import traceback
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Any, Dict, List, Union

JSON_EXTS = {'.json', '.js', '.txt'}

# Abréviations des jobs
JOB_ABBREV = {
    "Warrior": "WAR", "Paladin": "PLD", "Dark Knight": "DRK", "Beastmaster": "BST",
    "Monk": "MNK", "Bard": "BRD", "Ranger": "RNG", "Samurai": "SAM", "Ninja": "NIN",
    "Dragoon": "DRG", "Summoner": "SMN", "Blue Mage": "BLU", "Corsair": "COR",
    "Puppetmaster": "PUP", "Dancer": "DNC", "Scholar": "SCH", "Geomancer": "GEO",
    "Rune Fencer": "RUN", "White Mage": "WHM", "Black Mage": "BLM", "Red Mage": "RDM",
    "Thief": "THF"
}

DEFAULT_JOB_LIST = list(JOB_ABBREV.values())

# ============ UTILITAIRES ============

def safe_load_json(path: str):
    """Charge un fichier JSON avec gestion d'erreur"""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def ensure_list(v):
    """Garantit qu'on a une liste"""
    if v is None:
        return []
    return v if isinstance(v, list) else [v]

def normalize_to_object(item: Union[str, Dict]) -> Dict:
    """
    Convertit un string en objet {"name": "..."} 
    OU garde l'objet tel quel s'il en est déjà un
    """
    if isinstance(item, str):
        return {"name": item}
    elif isinstance(item, dict):
        return item
    else:
        return {"name": str(item)}

def deduplicate_by_name(items: List[Dict]) -> List[Dict]:
    """
    Déduplique une liste d'objets par leur champ 'name'
    Garde le premier objet rencontré
    """
    seen = {}
    result = []
    for item in items:
        name = item.get("name", "")
        if name and name not in seen:
            seen[name] = True
            result.append(item)
    return result

def merge_lists_as_objects(existing: List[Dict], new_items: List) -> List[Dict]:
    """
    Fusionne deux listes en objets détaillés, déduplique par name
    """
    combined = list(existing)
    for item in ensure_list(new_items):
        obj = normalize_to_object(item)
        combined.append(obj)
    return deduplicate_by_name(combined)

def sort_by_level_then_name(items: List[Dict]) -> List[Dict]:
    """Tri par level puis par name"""
    return sorted(items, key=lambda x: (x.get("level", 999), x.get("name", "")))

# ============ NORMALISATION D'UN JOB ============

def normalize_job_object(obj: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalise un objet job en structure unifiée
    GARDE TOUS LES DÉTAILS (level, mp, element, type, category, recast...)
    """
    out = {
        "job": None,
        "spells": [],
        "job_abilities": [],
        "pet_command": [],
        "pet_attack": {},
        "macro": []
    }

    # ===== JOB NAME (abréviation) =====
    job_name_full = (
        obj.get("job") or obj.get("name") or obj.get("Job") or 
        obj.get("job_name") or obj.get("id")
    )
    job_abbrev = JOB_ABBREV.get(job_name_full, job_name_full or "Unknown")
    out["job"] = job_abbrev

    # ===== SPELLS (garde tous les détails) =====
    spells_raw = obj.get("spells") or obj.get("skills") or obj.get("magic") or []
    out["spells"] = merge_lists_as_objects([], spells_raw)

    # ===== JOB ABILITIES (garde tous les détails) =====
    abilities_raw = (
        obj.get("job_abilities") or obj.get("abilities") or 
        obj.get("jobAbilities") or []
    )
    out["job_abilities"] = merge_lists_as_objects([], abilities_raw)

    # ===== PET COMMANDS (strings simples généralement) =====
    commands_raw = (
        obj.get("pet_command") or obj.get("pet_commands") or 
        obj.get("pet_command_list") or []
    )
    out["pet_command"] = merge_lists_as_objects([], commands_raw)

    # ===== MACROS (strings simples généralement) =====
    macros_raw = obj.get("macro") or obj.get("macros") or []
    out["macro"] = merge_lists_as_objects([], macros_raw)

    # ===== PET ATTACKS (structure complexe) =====
    pet_attack = {}

    # Format direct: {"Ifrit": [...], "Shiva": [...]}
    pa = obj.get("pet_attack") or obj.get("pet_attacks") or obj.get("petAttacks")
    if isinstance(pa, dict):
        for pet_name, attacks in pa.items():
            pet_attack[pet_name] = merge_lists_as_objects(
                pet_attack.get(pet_name, []), 
                attacks
            )
    elif isinstance(pa, list):
        for entry in pa:
            if isinstance(entry, dict):
                pet_name = entry.get("name") or entry.get("pet") or entry.get("id")
                attacks = entry.get("attacks") or entry.get("skills") or entry.get("abilities") or []
                if pet_name:
                    pet_attack[pet_name] = merge_lists_as_objects(
                        pet_attack.get(pet_name, []), 
                        attacks
                    )

    # Avatars/Summons (pour SMN)
    avatars = obj.get("avatars") or obj.get("summons") or obj.get("avatars_list") or []
    if isinstance(avatars, list):
        for av in avatars:
            if isinstance(av, dict):
                pet_name = av.get("name") or av.get("id")
                if pet_name:
                    attacks = []
                    attacks.extend(av.get("blood_pacts_rage") or av.get("rage") or av.get("attacks") or [])
                    attacks.extend(av.get("blood_pacts_ward") or av.get("ward") or [])
                    pet_attack[pet_name] = merge_lists_as_objects(
                        pet_attack.get(pet_name, []), 
                        attacks
                    )

    # Blood Pacts top-level
    for bp_key in ["blood_pacts_rage", "blood_pacts_ward", "bloodpacts_rage", "bloodpacts_ward", "blood_pacts"]:
        bp = obj.get(bp_key)
        if isinstance(bp, dict):
            for pet_name, attacks in bp.items():
                name = pet_name.strip() or "pet"
                pet_attack[name] = merge_lists_as_objects(
                    pet_attack.get(name, []), 
                    attacks
                )

    # Automaton/Pets (pour PUP/BST)
    for pet_key in ["automaton", "automata", "pets", "pet_list"]:
        pets = obj.get(pet_key)
        if isinstance(pets, dict):
            for pet_name, block in pets.items():
                if isinstance(block, dict):
                    attacks = block.get("attacks") or block.get("skills") or []
                    pet_attack[pet_name] = merge_lists_as_objects(
                        pet_attack.get(pet_name, []), 
                        attacks
                    )
        elif isinstance(pets, list):
            for entry in pets:
                if isinstance(entry, dict):
                    pet_name = entry.get("name") or entry.get("id")
                    attacks = entry.get("attacks") or entry.get("skills") or []
                    if pet_name:
                        pet_attack[pet_name] = merge_lists_as_objects(
                            pet_attack.get(pet_name, []), 
                            attacks
                        )

    # Tri final des pet_attack (par pet name, puis par level/name)
    pet_attack_sorted = {}
    for pet_name in sorted(pet_attack.keys()):
        pet_attack_sorted[pet_name] = sort_by_level_then_name(pet_attack[pet_name])

    out["pet_attack"] = pet_attack_sorted

    # Tri final des listes principales
    out["spells"] = sort_by_level_then_name(out["spells"])
    out["job_abilities"] = sort_by_level_then_name(out["job_abilities"])

    return out

# ============ COLLECTE & MERGE ============

def collect_jobs_from_folder(folder: str, log_callback=None) -> Dict[str, Dict]:
    """
    Parcourt un dossier et collecte tous les jobs
    log_callback: fonction pour afficher les logs dans la GUI
    """
    jobs: Dict[str, Dict] = {}
    
    if not os.path.isdir(folder):
        raise RuntimeError(f"Dossier invalide: {folder}")
    
    files = sorted([
        f for f in os.listdir(folder) 
        if os.path.splitext(f)[1].lower() in JSON_EXTS
    ])
    
    if log_callback:
        log_callback(f"📁 {len(files)} fichiers JSON trouvés\n")
    
    for fname in files:
        path = os.path.join(folder, fname)
        try:
            data = safe_load_json(path)
            processed = False
            
            # Format: liste d'objets job
            if isinstance(data, list):
                for entry in data:
                    if isinstance(entry, dict):
                        norm = normalize_job_object(entry)
                        job_name = norm["job"]
                        
                        # Merge si le job existe déjà
                        if job_name in jobs:
                            jobs[job_name]["spells"] = merge_lists_as_objects(
                                jobs[job_name]["spells"], 
                                norm["spells"]
                            )
                            jobs[job_name]["job_abilities"] = merge_lists_as_objects(
                                jobs[job_name]["job_abilities"], 
                                norm["job_abilities"]
                            )
                            jobs[job_name]["pet_command"] = merge_lists_as_objects(
                                jobs[job_name]["pet_command"], 
                                norm["pet_command"]
                            )
                            jobs[job_name]["macro"] = merge_lists_as_objects(
                                jobs[job_name]["macro"], 
                                norm["macro"]
                            )
                            # Merge pet_attack
                            for pet_name, attacks in norm["pet_attack"].items():
                                if pet_name not in jobs[job_name]["pet_attack"]:
                                    jobs[job_name]["pet_attack"][pet_name] = []
                                jobs[job_name]["pet_attack"][pet_name] = merge_lists_as_objects(
                                    jobs[job_name]["pet_attack"][pet_name],
                                    attacks
                                )
                        else:
                            jobs[job_name] = norm
                        
                        processed = True
                        if log_callback:
                            spell_count = len(norm["spells"])
                            ability_count = len(norm["job_abilities"])
                            log_callback(f"✅ {fname} → {job_name} ({spell_count} spells, {ability_count} abilities)\n")
            
            # Format: objet unique avec job
            elif isinstance(data, dict):
                if "job" in data or "name" in data:
                    norm = normalize_job_object(data)
                    job_name = norm["job"]
                    jobs[job_name] = norm
                    processed = True
                    if log_callback:
                        spell_count = len(norm["spells"])
                        ability_count = len(norm["job_abilities"])
                        log_callback(f"✅ {fname} → {job_name} ({spell_count} spells, {ability_count} abilities)\n")
                
                # Format: dict de jobs {"WAR": {...}, "WHM": {...}}
                else:
                    for key, val in data.items():
                        if isinstance(val, dict):
                            ent = val.copy()
                            if not ent.get("job"):
                                ent["job"] = key
                            norm = normalize_job_object(ent)
                            job_name = norm["job"]
                            jobs[job_name] = norm
                            processed = True
                            if log_callback:
                                spell_count = len(norm["spells"])
                                ability_count = len(norm["job_abilities"])
                                log_callback(f"✅ {fname} → {job_name} ({spell_count} spells, {ability_count} abilities)\n")
            
            if not processed and log_callback:
                log_callback(f"⚠️ {fname} → Format non reconnu, ignoré\n")
                
        except Exception as e:
            if log_callback:
                log_callback(f"❌ {fname} → ERREUR: {str(e)}\n")
            print(f"[ERROR] {fname}: {e}")
            traceback.print_exc()
    
    return jobs

def ensure_all_jobs_present(jobs: Dict[str, Dict], required: List[str]) -> Dict[str, Dict]:
    """S'assure que tous les jobs requis sont présents, même vides"""
    out = dict(jobs)
    for job_name in required:
        if job_name not in out:
            out[job_name] = {
                "job": job_name,
                "spells": [],
                "job_abilities": [],
                "pet_command": [],
                "pet_attack": {},
                "macro": []
            }
    return out

def dump_jobs_pretty(jobs: Dict[str, Dict], outpath: str):
    """Sauvegarde le fichier jobs.json avec indentation lisible"""
    jobs_sorted = {k: jobs[k] for k in sorted(jobs.keys())}
    with open(outpath, 'w', encoding='utf-8') as f:
        json.dump(jobs_sorted, f, ensure_ascii=False, indent=2)

# ============ GUI ============

class ConverterGUI:
    def __init__(self, root):
        self.root = root
        root.title("FFXI Jobs Converter - Optimisé (avec détails)")
        
        frame = ttk.Frame(root, padding=12)
        frame.grid(row=0, column=0, sticky="nsew")
        
        # Input folder
        ttk.Label(frame, text="📂 Dossier source (fichiers JSON):").grid(row=0, column=0, sticky="w")
        self.input_var = tk.StringVar()
        self.input_entry = ttk.Entry(frame, textvariable=self.input_var, width=60)
        self.input_entry.grid(row=1, column=0, sticky="w")
        ttk.Button(frame, text="Parcourir", command=self.browse_input).grid(row=1, column=1, padx=6)
        
        # Output file
        ttk.Label(frame, text="💾 Fichier de sortie (jobs.json):").grid(row=2, column=0, sticky="w", pady=(8, 0))
        self.output_var = tk.StringVar()
        self.output_entry = ttk.Entry(frame, textvariable=self.output_var, width=60)
        self.output_entry.grid(row=3, column=0, sticky="w")
        ttk.Button(frame, text="Parcourir", command=self.browse_output).grid(row=3, column=1, padx=6)
        
        # Buttons
        btn_frame = ttk.Frame(frame)
        btn_frame.grid(row=4, column=0, columnspan=2, pady=12, sticky="w")
        ttk.Button(btn_frame, text="🔍 Scanner", command=self.scan).pack(side="left", padx=4)
        ttk.Button(btn_frame, text="✨ Convertir", command=self.convert).pack(side="left", padx=4)
        ttk.Button(btn_frame, text="❌ Quitter", command=root.destroy).pack(side="left", padx=4)
        
        # Log console
        ttk.Label(frame, text="📋 Logs de traitement:").grid(row=5, column=0, sticky="w")
        log_frame = ttk.Frame(frame)
        log_frame.grid(row=6, column=0, columnspan=2, pady=6, sticky="nsew")
        
        self.log_text = tk.Text(log_frame, width=80, height=20, wrap="word")
        scrollbar = ttk.Scrollbar(log_frame, command=self.log_text.yview)
        self.log_text.configure(yscrollcommand=scrollbar.set)
        
        self.log_text.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # Status
        self.status = tk.StringVar(value="Prêt")
        ttk.Label(frame, textvariable=self.status).grid(row=7, column=0, sticky="w", pady=4)
        
        # Configure grid weights
        root.columnconfigure(0, weight=1)
        root.rowconfigure(0, weight=1)
        frame.columnconfigure(0, weight=1)
        frame.rowconfigure(6, weight=1)

    def log(self, message):
        """Ajoute un message au log"""
        self.log_text.insert(tk.END, message)
        self.log_text.see(tk.END)
        self.root.update_idletasks()

    def browse_input(self):
        d = filedialog.askdirectory(title="Sélectionner le dossier avec les JSON")
        if d:
            self.input_var.set(d)

    def browse_output(self):
        f = filedialog.asksaveasfilename(
            title="Choisir le fichier de sortie",
            defaultextension=".json",
            filetypes=[("JSON", "*.json"), ("All files", "*.*")]
        )
        if f:
            self.output_var.set(f)

    def scan(self):
        """Scanne le dossier sans convertir"""
        folder = self.input_var.get()
        if not folder or not os.path.isdir(folder):
            messagebox.showerror("Erreur", "Sélectionnez un dossier valide")
            return
        
        self.log_text.delete('1.0', tk.END)
        self.log("🔍 Scan du dossier...\n\n")
        
        try:
            jobs = collect_jobs_from_folder(folder, log_callback=self.log)
            
            self.log(f"\n📊 RÉSUMÉ:\n")
            self.log(f"   • {len(jobs)} jobs trouvés\n")
            
            total_spells = sum(len(j["spells"]) for j in jobs.values())
            total_abilities = sum(len(j["job_abilities"]) for j in jobs.values())
            
            self.log(f"   • {total_spells} sorts au total\n")
            self.log(f"   • {total_abilities} abilities au total\n")
            
            self.status.set(f"Scan terminé: {len(jobs)} jobs trouvés")
            
        except Exception as e:
            self.log(f"\n❌ ERREUR: {str(e)}\n")
            traceback.print_exc()
            messagebox.showerror("Erreur", str(e))

    def convert(self):
        """Convertit et sauvegarde jobs.json"""
        folder = self.input_var.get()
        outpath = self.output_var.get()
        
        if not folder or not os.path.isdir(folder):
            messagebox.showerror("Erreur", "Sélectionnez un dossier source valide")
            return
        
        if not outpath:
            messagebox.showerror("Erreur", "Sélectionnez un fichier de sortie")
            return
        
        self.log_text.delete('1.0', tk.END)
        self.log("✨ Conversion en cours...\n\n")
        
        try:
            # Collecte
            jobs = collect_jobs_from_folder(folder, log_callback=self.log)
            
            # Ajout des jobs manquants (structure vide)
            jobs = ensure_all_jobs_present(jobs, DEFAULT_JOB_LIST)
            
            # Sauvegarde
            dump_jobs_pretty(jobs, outpath)
            
            # Stats finales
            self.log(f"\n✅ CONVERSION RÉUSSIE!\n")
            self.log(f"   • Fichier: {outpath}\n")
            self.log(f"   • {len(jobs)} jobs exportés\n")
            
            total_spells = sum(len(j["spells"]) for j in jobs.values())
            total_abilities = sum(len(j["job_abilities"]) for j in jobs.values())
            
            self.log(f"   • {total_spells} sorts\n")
            self.log(f"   • {total_abilities} abilities\n")
            
            file_size = os.path.getsize(outpath) / 1024
            self.log(f"   • Taille: {file_size:.1f} KB\n")
            
            self.status.set(f"✅ Conversion réussie: {len(jobs)} jobs exportés")
            messagebox.showinfo("Succès", f"Fichier créé avec succès!\n{outpath}")
            
        except Exception as e:
            self.log(f"\n❌ ERREUR: {str(e)}\n")
            traceback.print_exc()
            messagebox.showerror("Erreur", str(e))

# ============ MAIN ============

def main():
    root = tk.Tk()
    ConverterGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()