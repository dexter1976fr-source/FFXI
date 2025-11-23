#!/usr/bin/env python3
"""
Script pour mettre à jour les sorts SCH dans jobs.json
en utilisant les ressources officielles de Windower
"""

import json
import re

# Charger le fichier spells.lua de Windower
windower_spells_path = r"A:\Jeux\PlayOnline\Windower4\res\spells.lua"

print("📖 Lecture des ressources Windower...")

with open(windower_spells_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parser les sorts (format Lua) - ligne par ligne
lines = content.split('\n')
sch_spells = []
current_spell = {}

for line in lines:
    # Nouvelle entrée de sort
    if re.match(r'\s*\[\d+\] = \{', line):
        # Sauvegarder le sort précédent s'il était SCH
        if current_spell and current_spell.get('is_sch'):
            # Filtrer les Trusts et sorts non pertinents
            spell_type = current_spell.get('type_raw', '')
            if spell_type not in ['Trust', 'Ninjutsu', 'BardSong']:
                sch_spells.append({
                    "name": current_spell['name'],
                    "level": current_spell['level'],
                    "mp": current_spell.get('mp'),
                    "type": current_spell['type'],
                    "category": current_spell['category'],
                    "requirements": current_spell.get('requirements', 0)
                })
        
        # Réinitialiser
        current_spell = {}
        
        # Extraire les infos de la ligne
        name_match = re.search(r'en="([^"]+)"', line)
        type_match = re.search(r'type="([^"]+)"', line)
        mp_match = re.search(r'mp_cost=(\d+)', line)
        targets_match = re.search(r'targets=(\d+)', line)
        requirements_match = re.search(r'requirements=(\d+)', line)
        levels_match = re.search(r'levels=\{([^}]+)\}', line)
        
        if name_match:
            current_spell['name'] = name_match.group(1)
        if type_match:
            current_spell['type_raw'] = type_match.group(1)
        if mp_match:
            current_spell['mp'] = int(mp_match.group(1))
        if targets_match:
            current_spell['targets'] = int(targets_match.group(1))
        if requirements_match:
            current_spell['requirements'] = int(requirements_match.group(1))
        
        # Vérifier si c'est un sort SCH (job 20)
        if levels_match and '[20]=' in levels_match.group(1):
            level_match = re.search(r'\[20\]=(\d+)', levels_match.group(1))
            if level_match:
                current_spell['is_sch'] = True
                current_spell['level'] = int(level_match.group(1))
                # Déterminer la catégorie basée sur le type et les targets
                spell_name = current_spell['name']
                spell_type = current_spell['type_raw']
                targets = current_spell.get('targets', 0)
                
                # targets: 1=self, 2=party member, 4=party, 8=enemy, 16=area, 32=enemy, 63=self+party
                category = "target"
                
                if spell_type == "WhiteMagic":
                    if "Cure" in spell_name or "Raise" in spell_name or "Regen" in spell_name:
                        spell_type_clean = "Healing"
                        if targets in [1, 2, 29, 63]:  # 29 = party member, 63 = self or party
                            category = "target"
                        elif targets in [4, 5]:  # party
                            category = "party"
                    elif "na" in spell_name.lower() or "Erase" in spell_name:
                        spell_type_clean = "Healing"
                        category = "target"
                    elif "Protect" in spell_name or "Shell" in spell_name or "Haste" in spell_name or "Refresh" in spell_name:
                        spell_type_clean = "Enhancing"
                        category = "party"
                    elif "Blink" in spell_name or "Stoneskin" in spell_name or "Aquaveil" in spell_name or "Phalanx" in spell_name:
                        spell_type_clean = "Enhancing"
                        category = "party"
                    elif "Reraise" in spell_name:
                        spell_type_clean = "Enhancing"
                        category = "self"
                    else:
                        spell_type_clean = "Enhancing"
                        category = "target"
                elif spell_type == "BlackMagic":
                    spell_type_clean = "Elemental"
                    category = "attack"
                elif spell_type == "Geomancy":
                    spell_type_clean = "Elemental"
                    category = "attack"
                else:
                    spell_type_clean = spell_type
                    category = "target"
                
                current_spell['type'] = spell_type_clean
                current_spell['category'] = category

# Sauvegarder le dernier sort s'il était SCH
if current_spell and current_spell.get('is_sch'):
    spell_type = current_spell.get('type_raw', '')
    if spell_type not in ['Trust', 'Ninjutsu', 'BardSong']:
        sch_spells.append({
            "name": current_spell['name'],
            "level": current_spell['level'],
            "mp": current_spell.get('mp'),
            "type": current_spell['type'],
            "category": current_spell['category'],
            "requirements": current_spell.get('requirements', 0)
        })

# Trier par level
sch_spells.sort(key=lambda x: x["level"])

print(f"✅ {len(sch_spells)} sorts SCH trouvés dans Windower")

# Charger jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs = json.load(f)

# Remplacer les sorts SCH
if "SCH" in jobs:
    # Garder les job_abilities, pet_command, etc.
    old_spell_count = len(jobs["SCH"]["spells"])
    jobs["SCH"]["spells"] = sch_spells
    
    print(f"✅ Sorts SCH mis à jour: {old_spell_count} → {len(sch_spells)}")
    
    # Afficher quelques exemples
    print("\n📋 Exemples de sorts mis à jour:")
    for spell in sch_spells[:10]:
        req_str = ""
        if spell["requirements"] == 4:
            req_str = " (Addendum: White)"
        elif spell["requirements"] == 5:
            req_str = " (Addendum: Black)"
        print(f"  - {spell['name']} (Lv{spell['level']}): {spell['type']}/{spell['category']}{req_str}")
else:
    print("❌ Job SCH non trouvé dans jobs.json")

# Sauvegarder
with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
    json.dump(jobs, f, indent=2, ensure_ascii=False)

print("\n✅ Fichier jobs.json sauvegardé!")
print("\n📊 Statistiques:")
print(f"  - Sorts de base: {len([s for s in sch_spells if s['requirements'] == 0])}")
print(f"  - Addendum: White: {len([s for s in sch_spells if s['requirements'] == 4])}")
print(f"  - Addendum: Black: {len([s for s in sch_spells if s['requirements'] == 5])}")
