#!/usr/bin/env python3
"""
Générer spellIds.ts directement depuis Windower resources
"""
import re
import json

# Lire le fichier Lua de Windower
with open('a:/Jeux/PlayOnline/Windower4/res/spells.lua', 'r', encoding='utf-8') as f:
    lua_content = f.read()

# Pattern pour extraire: [id] = {id=X,en="Name",...}
pattern = r'\[(\d+)\]\s*=\s*\{[^}]*en="([^"]+)"[^}]*\}'

spells = {}
for match in re.finditer(pattern, lua_content):
    spell_id = int(match.group(1))
    spell_name = match.group(2)
    spells[spell_name] = spell_id

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire les spells utilisés
used_spells = {}
for job_name, job_data in jobs_data.items():
    if 'spells' in job_data:
        for spell in job_data['spells']:
            spell_name = spell.get('name', '')
            if spell_name and spell_name in spells:
                used_spells[spell_name] = spells[spell_name]
    
    # Ajouter aussi les pet attacks (Blood Pacts, etc.)
    if 'pet_attack' in job_data and isinstance(job_data['pet_attack'], dict):
        for pet_name, attacks in job_data['pet_attack'].items():
            if isinstance(attacks, list):
                for attack in attacks:
                    attack_name = attack.get('name', '')
                    if attack_name and attack_name in spells:
                        used_spells[attack_name] = spells[attack_name]

# Trier par ID
sorted_spells = sorted(used_spells.items(), key=lambda x: x[1])

# Générer le fichier TypeScript
output = """// Mapping des IDs de spells FFXI vers leurs noms
// Auto-généré depuis Windower resources (spells.lua)

export const SPELL_IDS: Record<number, string> = {
"""

for spell_name, spell_id in sorted_spells:
    # Échapper les guillemets dans le nom
    safe_name = spell_name.replace('"', '\\"')
    output += f'  {spell_id}: "{safe_name}",\n'

output += """}

// Fonction helper pour obtenir le nom d'un spell par son ID
export function getSpellName(id: number): string | undefined {
  return SPELL_IDS[id];
}

// Fonction helper pour obtenir l'ID d'un spell par son nom
export function getSpellId(name: string): number | undefined {
  const entry = Object.entries(SPELL_IDS).find(([_, spellName]) => 
    spellName.toLowerCase() === name.toLowerCase()
  );
  return entry ? parseInt(entry[0]) : undefined;
}
"""

# Écrire le fichier
with open('Web_App/src/data/spellIds.ts', 'w', encoding='utf-8') as f:
    f.write(output)

print(f"OK - Fichier spellIds.ts genere avec {len(used_spells)} spells!")
