#!/usr/bin/env python3
"""
Génère les IDs de sorts pour toutes les chansons BRD depuis Windower
"""

import re

# Lire spells.lua de Windower
windower_path = r"A:\Jeux\PlayOnline\Windower4\res\spells.lua"

with open(windower_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parser les chansons BRD
brd_spell_ids = {}
lines = content.split('\n')

for line in lines:
    if 'type="BardSong"' in line:
        # Extraire ID et nom
        id_match = re.search(r'\[(\d+)\] = \{id=(\d+),en="([^"]+)"', line)
        if id_match:
            spell_id = int(id_match.group(2))
            spell_name = id_match.group(3)
            brd_spell_ids[spell_id] = spell_name

# Trier par ID
sorted_ids = sorted(brd_spell_ids.items())

print(f"OK {len(brd_spell_ids)} chansons BRD trouvees\n")
print("// Ajouter ces lignes dans Web_App/src/data/spellIds.ts:\n")
print("  // BRD Songs")

for spell_id, spell_name in sorted_ids:
    print(f'  {spell_id}: "{spell_name}",')

print(f"\nOK Total: {len(brd_spell_ids)} chansons")
