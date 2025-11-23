#!/usr/bin/env python3
"""
Corriger les Blood Pacts du SMN dans jobs.json avec les vraies données
"""
import json

# Lire les Blood Pacts corrects
with open('smn_blood_pacts_correct.json', 'r', encoding='utf-8') as f:
    correct_bp = json.load(f)

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

print("Correction des Blood Pacts du SMN...")
print("=" * 60)

if 'SMN' in jobs_data:
    # Reconstruire pet_attack avec les bonnes données
    new_pet_attack = {}
    
    for avatar_name, bp_data in correct_bp.items():
        attacks = []
        
        # Ajouter les Rage
        for bp in bp_data['rage']:
            attacks.append({
                "name": bp['name'],
                "level": bp['level'],
                "mp": "varies",
                "type": "Magic" if any(x in bp['name'] for x in ['Fire', 'Ice', 'Thunder', 'Water', 'Aero', 'Stone', 'Blizzard']) else "Physical",
                "category": "attack"
            })
        
        # Ajouter les Ward
        for bp in bp_data['ward']:
            attacks.append({
                "name": bp['name'],
                "level": bp['level'],
                "mp": "varies",
                "type": "Enhancing",
                "category": "support"
            })
        
        new_pet_attack[avatar_name] = attacks
        print(f"  {avatar_name}: {len(attacks)} Blood Pacts ({len(bp_data['rage'])} Rage + {len(bp_data['ward'])} Ward)")
    
    # Remplacer pet_attack
    jobs_data['SMN']['pet_attack'] = new_pet_attack
    
    # Sauvegarder
    with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
        json.dump(jobs_data, f, indent=2, ensure_ascii=False)
    
    print("\n[OK] Blood Pacts du SMN corriges!")
    print(f"[INFO] {len(new_pet_attack)} avatars mis a jour")
else:
    print("[ERREUR] SMN non trouve dans jobs.json!")

print("=" * 60)
