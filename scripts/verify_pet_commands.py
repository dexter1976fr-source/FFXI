#!/usr/bin/env python3
"""
Script pour vérifier que toutes les pet commands ont des catégories valides
"""

import json
import os

def verify_pet_commands():
    """
    Vérifie que toutes les pet commands ont des catégories
    """
    path = os.path.join("data_json", "jobs.json")
    
    print(f"📖 Lecture de {path}...")
    with open(path, 'r', encoding='utf-8') as f:
        jobs_data = json.load(f)
    
    issues = []
    stats = {
        "total_commands": 0,
        "with_category": 0,
        "without_category": 0,
        "by_category": {}
    }
    
    print("\n" + "="*60)
    print("🔍 VÉRIFICATION DES PET COMMANDS")
    print("="*60)
    
    for job_name, job_data in jobs_data.items():
        pet_commands = job_data.get("pet_command", [])
        
        if not pet_commands:
            continue
        
        print(f"\n📋 {job_name}:")
        
        for cmd in pet_commands:
            stats["total_commands"] += 1
            cmd_name = cmd.get("name", "Unknown")
            category = cmd.get("category")
            
            if category:
                stats["with_category"] += 1
                stats["by_category"][category] = stats["by_category"].get(category, 0) + 1
                print(f"  ✅ {cmd_name:30s} → {category}")
            else:
                stats["without_category"] += 1
                issues.append(f"{job_name}: {cmd_name}")
                print(f"  ❌ {cmd_name:30s} → MISSING CATEGORY")
    
    # Afficher les statistiques
    print("\n" + "="*60)
    print("📊 STATISTIQUES")
    print("="*60)
    print(f"Total pet commands: {stats['total_commands']}")
    print(f"Avec catégorie: {stats['with_category']}")
    print(f"Sans catégorie: {stats['without_category']}")
    
    if stats['by_category']:
        print("\nRépartition par catégorie:")
        for cat, count in sorted(stats['by_category'].items()):
            print(f"  {cat:15s}: {count:3d}")
    
    # Afficher les problèmes
    if issues:
        print("\n" + "="*60)
        print("⚠️  COMMANDES SANS CATÉGORIE")
        print("="*60)
        for issue in issues:
            print(f"  - {issue}")
        print("\n💡 Ces commandes devraient avoir une catégorie:")
        print("   - 'attack' pour les commandes d'attaque (<t>)")
        print("   - 'support' pour les buffs/soins (<me>)")
        print("   - 'utility' pour les commandes utilitaires (<me>)")
        print("   - 'pet' pour les commandes de contrôle (<me>)")
    else:
        print("\n✅ Toutes les pet commands ont des catégories!")
    
    print("="*60)
    
    return len(issues) == 0


if __name__ == "__main__":
    success = verify_pet_commands()
    exit(0 if success else 1)
