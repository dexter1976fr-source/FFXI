#!/usr/bin/env python3
"""
Reconstruit les chansons BRD depuis les ressources Windower
"""

import json
import re

# Lire spells.lua de Windower
windower_path = r"A:\Jeux\PlayOnline\Windower4\res\spells.lua"

with open(windower_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parser les chansons BRD
brd_songs = []
lines = content.split('\n')

for line in lines:
    if 'type="BardSong"' in line:
        # Extraire les infos
        name_match = re.search(r'en="([^"]+)"', line)
        levels_match = re.search(r'levels=\{([^}]+)\}', line)
        targets_match = re.search(r'targets=(\d+)', line)
        element_match = re.search(r'element=(\d+)', line)
        
        if name_match and levels_match:
            name = name_match.group(1)
            levels_str = levels_match.group(1)
            targets = int(targets_match.group(1)) if targets_match else 1
            element = int(element_match.group(1)) if element_match else 6
            
            # Extraire le level BRD (job 10)
            level_match = re.search(r'\[10\]=(\d+)', levels_str)
            if level_match:
                level = int(level_match.group(1))
                
                # Déterminer la catégorie selon targets
                if targets == 32:  # Ennemi
                    category = "attack"
                    spell_type = "Enfeebling"
                else:  # Self (targets=1)
                    category = "self"
                    spell_type = "Enhancing"
                
                # Mapping des éléments
                element_map = {
                    0: "None", 1: "Fire", 2: "Ice", 3: "Wind",
                    4: "Earth", 5: "Lightning", 6: "Light", 7: "Water", 8: "Dark"
                }
                
                brd_songs.append({
                    "name": name,
                    "level": level,
                    "mp": 0,
                    "element": element_map.get(element, "Light"),
                    "type": spell_type,
                    "category": category
                })

# Trier par level
brd_songs.sort(key=lambda x: x["level"])

print(f"✅ {len(brd_songs)} chansons BRD extraites de Windower")

# Charger jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs = json.load(f)

# Remplacer les chansons BRD
if "BRD" in jobs:
    old_count = len(jobs["BRD"]["spells"])
    jobs["BRD"]["spells"] = brd_songs
    print(f"✅ Chansons BRD remplacées: {old_count} → {len(brd_songs)}")
    
    # Afficher quelques exemples
    print("\n📋 Exemples:")
    for song in brd_songs[:10]:
        print(f"  - {song['name']} (Lv{song['level']}): {song['type']}/{song['category']}")

# Sauvegarder
with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
    json.dump(jobs, f, indent=2, ensure_ascii=False)

print("\n✅ Fichier jobs.json sauvegardé avec les données officielles Windower!")
