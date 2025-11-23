#!/usr/bin/env python3
"""
Extraire les ability IDs depuis les ressources Windower
"""
import re
import json

# Lire le fichier Lua de Windower
with open('a:/Jeux/PlayOnline/Windower4/res/job_abilities.lua', 'r', encoding='utf-8') as f:
    lua_content = f.read()

# Pattern pour extraire: [id] = {id=X,en="Name",...,recast_id=Y,...}
pattern = r'\[(\d+)\]\s*=\s*\{[^}]*en="([^"]+)"[^}]*recast_id=(\d+)[^}]*\}'

abilities = {}
for match in re.finditer(pattern, lua_content):
    ability_id = int(match.group(1))
    ability_name = match.group(2)
    recast_id = int(match.group(3))
    
    # On utilise le recast_id comme clé
    abilities[ability_name] = recast_id

# Lire jobs.json pour voir quelles abilities on utilise
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire les abilities utilisées
used_abilities = set()
for job_name, job_data in jobs_data.items():
    if 'job_abilities' in job_data:
        for ability in job_data['job_abilities']:
            ability_name = ability.get('name', '')
            if ability_name:
                used_abilities.add(ability_name)

# Filtrer pour ne garder que celles qu'on utilise
filtered_abilities = {}
missing_abilities = []

for ability_name in sorted(used_abilities):
    if ability_name in abilities:
        filtered_abilities[ability_name] = abilities[ability_name]
    else:
        missing_abilities.append(ability_name)

print(f"[OK] Trouve {len(filtered_abilities)} abilities avec recast_id")
print(f"[WARN] {len(missing_abilities)} abilities sans recast_id")

if missing_abilities:
    print("\nAbilities manquantes:")
    for name in missing_abilities[:10]:
        print(f"  - {name}")

# Générer le code Python pour generate_ability_ids.py
print("\n" + "="*60)
print("Code à copier dans generate_ability_ids.py:")
print("="*60)

# Grouper par job (approximatif)
output_lines = []
for ability_name in sorted(filtered_abilities.keys()):
    recast_id = filtered_abilities[ability_name]
    output_lines.append(f'    "{ability_name}": {recast_id},')

print("\n".join(output_lines))
