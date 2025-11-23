#!/usr/bin/env python3
"""
Script pour extraire tous les sorts uniques de jobs.json
"""
import json

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire tous les sorts uniques
all_spells = set()

for job_name, job_data in jobs_data.items():
    if 'spells' in job_data:
        for spell in job_data['spells']:
            spell_name = spell.get('name', '')
            if spell_name:
                all_spells.add(spell_name)

# Trier alphabétiquement
sorted_spells = sorted(all_spells)

print(f"Total de sorts uniques trouvés: {len(sorted_spells)}\n")
print("Liste des sorts:")
print("=" * 50)
for spell in sorted_spells:
    print(f"  - {spell}")
