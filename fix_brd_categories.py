#!/usr/bin/env python3
"""
Script pour corriger les catégories des chansons BRD
Basé sur les règles FFXI officielles
"""

import json

# Charger jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs = json.load(f)

# TOUTES les chansons BRD se castent sur <me> (self)
# L'effet se propage en AoE autour du BRD

# Corriger les chansons BRD
if "BRD" in jobs:
    corrected = 0
    removed = 0
    
    # Liste des chansons qui n'existent pas (à supprimer)
    INVALID_SONGS = [
        "Mage's Ballad IV",
        "Mage's Ballad V"
    ]
    
    # Filtrer les chansons invalides
    valid_spells = []
    for spell in jobs["BRD"]["spells"]:
        spell_name = spell.get("name", "")
        
        if spell_name in INVALID_SONGS:
            print(f"❌ Supprimé: {spell_name} (n'existe pas dans FFXI)")
            removed += 1
            continue
        
        valid_spells.append(spell)
        
        # Toutes les chansons BRD = self
        old_category = spell.get("category")
        if old_category != "self":
            spell["category"] = "self"
            print(f"✅ {spell_name}: {old_category} → self")
            corrected += 1
    
    jobs["BRD"]["spells"] = valid_spells
    
    print(f"\n✅ {corrected} chansons BRD corrigées!")
else:
    print("❌ Job BRD non trouvé")

# Sauvegarder
with open('data_json/jobs.json', 'w', encoding='utf-8') as f:
    json.dump(jobs, f, indent=2, ensure_ascii=False)

print("\n✅ Fichier jobs.json sauvegardé!")
