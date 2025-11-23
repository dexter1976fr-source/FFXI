#!/usr/bin/env python3
"""
Script pour corriger les sorts SCH dans jobs.json
Basé sur les informations fournies par l'utilisateur
"""

import json

# Charger jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs = json.load(f)

# Corrections pour les sorts SCH
sch_spell_corrections = {
    # Light Arts → Addendum: White (sorts de support/heal)
    "Reraise": {"type": "Enhancing", "category": "self"},
    "Reraise II": {"type": "Enhancing", "category": "self"},
    "Reraise III": {"type": "Enhancing", "category": "self"},
    "Raise II": {"type": "Healing", "category": "target"},
    "Raise III": {"type": "Healing", "category": "target"},
    "Erase": {"type": "Healing", "category": "target"},
    "Poisona": {"type": "Healing", "category": "target"},
    "Paralyna": {"type": "Healing", "category": "target"},
    "Blindna": {"type": "Healing", "category": "target"},
    "Silena": {"type": "Healing", "category": "target"},
    "Stona": {"type": "Healing", "category": "target"},
    "Viruna": {"type": "Healing", "category": "target"},
    "Cursna": {"type": "Healing", "category": "target"},
    
    # Light Arts → Accession (buffs party)
    "Cure": {"type": "Healing", "category": "target"},
    "Cure II": {"type": "Healing", "category": "target"},
    "Cure III": {"type": "Healing", "category": "target"},
    "Cure IV": {"type": "Healing", "category": "target"},
    "Protect": {"type": "Enhancing", "category": "party"},
    "Protect II": {"type": "Enhancing", "category": "party"},
    "Protect III": {"type": "Enhancing", "category": "party"},
    "Protect IV": {"type": "Enhancing", "category": "party"},
    "Protect V": {"type": "Enhancing", "category": "party"},
    "Shell": {"type": "Enhancing", "category": "party"},
    "Shell II": {"type": "Enhancing", "category": "party"},
    "Shell III": {"type": "Enhancing", "category": "party"},
    "Shell IV": {"type": "Enhancing", "category": "party"},
    "Shell V": {"type": "Enhancing", "category": "party"},
    "Blink": {"type": "Enhancing", "category": "party"},
    "Stoneskin": {"type": "Enhancing", "category": "party"},
    "Aquaveil": {"type": "Enhancing", "category": "party"},
    "Haste": {"type": "Enhancing", "category": "party"},
    "Phalanx": {"type": "Enhancing", "category": "party"},
    "Regen": {"type": "Healing", "category": "party"},
    "Regen II": {"type": "Healing", "category": "party"},
    "Regen III": {"type": "Healing", "category": "party"},
    "Refresh": {"type": "Enhancing", "category": "party"},
    
    # Dark Arts → Addendum: Black (nukes)
    "Fire IV": {"type": "Elemental", "category": "attack"},
    "Fire V": {"type": "Elemental", "category": "attack"},
    "Blizzard IV": {"type": "Elemental", "category": "attack"},
    "Blizzard V": {"type": "Elemental", "category": "attack"},
    "Aero IV": {"type": "Elemental", "category": "attack"},
    "Aero V": {"type": "Elemental", "category": "attack"},
    "Stone IV": {"type": "Elemental", "category": "attack"},
    "Stone V": {"type": "Elemental", "category": "attack"},
    "Water IV": {"type": "Elemental", "category": "attack"},
    "Water V": {"type": "Elemental", "category": "attack"},
    "Thunder IV": {"type": "Elemental", "category": "attack"},
    "Thunder V": {"type": "Elemental", "category": "attack"},
    "Break": {"type": "Enfeebling", "category": "attack"}
}

# Appliquer les corrections
if "SCH" in jobs:
    corrected_count = 0
    for spell in jobs["SCH"]["spells"]:
        spell_name = spell.get("name")
        if spell_name in sch_spell_corrections:
            corrections = sch_spell_corrections[spell_name]
            old_type = spell.get("type")
            old_category = spell.get("category")
            
            spell["type"] = corrections["type"]
            spell["category"] = corrections["category"]
            
            if old_type != corrections["type"] or old_category != corrections["category"]:
                print(f"✅ {spell_name}: {old_type}/{old_category} → {corrections['type']}/{corrections['category']}")
                corrected_count += 1
    
    print(f"\n✅ {corrected_count} sorts SCH corrigés!")
else:
    print("❌ Job SCH non trouvé dans jobs.json")

# Sauvegarder
with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
    json.dump(jobs, f, indent=2, ensure_ascii=False)

print("\n✅ Fichier jobs.json sauvegardé!")
