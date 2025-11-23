#!/usr/bin/env python3
"""
Script pour nettoyer les doublons dans jobs.json
"""
import json
from collections import OrderedDict

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

print("Verification et nettoyage de jobs.json...")
print("=" * 60)

corrections = []

for job_name, job_data in jobs_data.items():
    if 'pet_attack' in job_data and isinstance(job_data['pet_attack'], dict):
        for pet_name, attacks in job_data['pet_attack'].items():
            if isinstance(attacks, list):
                # Détecter les doublons
                seen_names = {}
                unique_attacks = []
                duplicates = []
                
                for attack in attacks:
                    attack_name = attack.get('name', '')
                    if attack_name:
                        if attack_name not in seen_names:
                            seen_names[attack_name] = attack
                            unique_attacks.append(attack)
                        else:
                            duplicates.append(attack_name)
                
                # Si des doublons ont été trouvés
                if duplicates:
                    corrections.append({
                        'job': job_name,
                        'pet': pet_name,
                        'before': len(attacks),
                        'after': len(unique_attacks),
                        'removed': duplicates
                    })
                    
                    # Remplacer par la liste nettoyée
                    job_data['pet_attack'][pet_name] = unique_attacks

# Afficher le rapport
if corrections:
    print(f"\n[CORRECTIONS] {len(corrections)} pets avec doublons trouves:\n")
    for corr in corrections:
        print(f"  {corr['job']} - {corr['pet']}:")
        print(f"    Avant: {corr['before']} attacks")
        print(f"    Apres: {corr['after']} attacks")
        print(f"    Doublons supprimes: {len(corr['removed'])}")
        if len(corr['removed']) <= 5:
            for dup in corr['removed']:
                print(f"      - {dup}")
        else:
            for dup in corr['removed'][:5]:
                print(f"      - {dup}")
            print(f"      ... et {len(corr['removed']) - 5} autres")
        print()
    
    # Sauvegarder le fichier corrigé
    with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
        json.dump(jobs_data, f, indent=2, ensure_ascii=False)
    
    print(f"[OK] Fichier jobs.json nettoye et sauvegarde!")
    print(f"[INFO] {sum(c['before'] - c['after'] for c in corrections)} doublons supprimes au total")
else:
    print("[OK] Aucun doublon trouve!")

print("\n" + "=" * 60)
