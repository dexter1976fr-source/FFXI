#!/usr/bin/env python3
"""
Générer abilityIds.ts directement depuis Windower resources
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
    ability_name = match.group(2)
    recast_id = int(match.group(3))
    abilities[ability_name] = recast_id

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire les abilities utilisées
used_abilities = {}
for job_name, job_data in jobs_data.items():
    if 'job_abilities' in job_data:
        for ability in job_data['job_abilities']:
            ability_name = ability.get('name', '')
            if ability_name and ability_name in abilities:
                used_abilities[ability_name] = abilities[ability_name]

# Trier par ID
sorted_abilities = sorted(used_abilities.items(), key=lambda x: x[1])

# Générer le fichier TypeScript
output = """// Mapping des IDs d'abilities FFXI vers leurs noms
// Auto-généré depuis Windower resources (job_abilities.lua)

export const ABILITY_IDS: Record<number, string> = {
"""

for ability_name, ability_id in sorted_abilities:
    # Échapper les guillemets dans le nom
    safe_name = ability_name.replace('"', '\\"')
    output += f'  {ability_id}: "{safe_name}",\n'

output += """}

// Fonction helper pour obtenir le nom d'une ability par son ID
export function getAbilityName(id: number): string | undefined {
  return ABILITY_IDS[id];
}

// Fonction helper pour obtenir l'ID d'une ability par son nom
export function getAbilityId(name: string): number | undefined {
  const entry = Object.entries(ABILITY_IDS).find(([_, abilityName]) => 
    abilityName.toLowerCase() === name.toLowerCase()
  );
  return entry ? parseInt(entry[0]) : undefined;
}
"""

# Écrire le fichier
with open('Web_App/src/data/abilityIds.ts', 'w', encoding='utf-8') as f:
    f.write(output)

print(f"OK - Fichier abilityIds.ts genere avec {len(used_abilities)} abilities!")
