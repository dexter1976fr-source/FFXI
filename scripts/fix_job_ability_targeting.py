#!/usr/bin/env python3
"""
Script pour corriger automatiquement le ciblage des job abilities dans jobs.json
Basé sur les règles connues de FFXI
"""

import json
import os

# Règles de ciblage pour les job abilities
# Format: "ability_name_pattern": "target_type"
# target_type peut être: "self", "target", "party", "area"

TARGETING_RULES = {
    # Abilities qui ciblent SOI-MÊME (<me>)
    "self": [
        # Buffs personnels
        "berserk", "defender", "warcry", "aggressor", "retaliation",
        "restraint", "blood rage", "mighty strikes",
        "perfect dodge", "hide", "flee", "steal", "mug", "collaborator",
        "accomplice", "despoil", "larceny",
        "third eye", "seigan", "hasso", "meditate", "warding circle",
        "sekkanoki", "sengikori", "hagakure", "issekigan", "konzen-ittai",
        "last resort", "weapon bash", "souleater", "arcane circle",
        "dark seal", "diabolic eye", "nether void", "soul enslavement",
        "consume mana", "dark arts", "light arts", "addendum", "sublimation",
        "convert", "manafont", "mana wall", "enmity douse",
        "chainspell", "spontaneity", "composure",
        "divine seal", "devotion", "martyr", "benediction",
        "asylum", "sacrosanct",
        "elemental seal", "manawell", "enmity douse",
        "spirit surge", "angon",
        "azure lore", "burst affinity", "chain affinity", "efflux",
        "diffusion", "unbridled learning", "convergence",
        "soul voice", "clarion call", "marcato", "tenuto",
        "nightingale", "troubadour",
        "trance", "no foot rise", "presto", "fan dance", "saber dance",
        "contradance", "grand pas", "building flourish", "striking flourish",
        "ternary flourish", "climactic flourish",
        "phantom roll", "double-up", "fold", "snake eye", "random deal",
        "quick draw", "triple shot", "crooked cards", "cutting cards",
        "bolter's roll", "caster's roll", "courser's roll", "blitzer's roll",
        "tactician's roll", "allies' roll", "miser's roll", "companion's roll",
        "avenger's roll", "corsair's roll", "puppet's roll", "dancer's roll",
        "scholar's roll", "naturalist's roll", "runeist's roll", "beast roll",
        "samurai roll", "hunter's roll", "chaos roll", "magus's roll",
        "healer's roll", "drachen roll", "choral roll", "monk's roll",
        "ninja roll", "rogue's roll", "warlock's roll", "fighter's roll",
        "wizard's roll", "evoker's roll", "gallant's roll",
        "activate", "repair", "deactivate", "maneuver", "overdrive",
        "tactical switch", "ventriloquy", "role reversal", "cooldown",
        "heady artifice", "optimization", "fine-tuning",
        "invincible", "sentinel", "rampart", "fealty", "chivalry",
        "divine emblem", "palisade", "intervene", "holy circle",
        "arcane crest", "mana cede", "saboteur", "stymie",
        "swordplay", "lunge", "swipe", "vallation", "valiance",
        "pflug", "battuta", "liement", "one for all", "gambit",
        "rayke", "odyllic subterfuge", "embolden",
        "bully", "run wild", "snarl", "familiar", "tame",
        "reward", "call beast", "bestial loyalty", "killer instinct",
        "feral howl",
        "astral flow", "astral conduit", "apogee",
        "elemental siphon", "mending halation", "radial arcana",
        "spirit bond", "spirit taker",
        "footwork", "formless strikes", "mantra", "dodge",
        "focus", "chakra", "boost", "counterstance", "hundred fists",
        "inner strength", "impetus",
        "provoke", "animated flourish", "shield bash", "flash",
        "sentinel", "cover", "rampart",
        # Stances
        "hasso", "seigan", "sengikori",
        # Conversions
        "convert", "sublimation",
        # Resets
        "tabula rasa", "enlightenment",
    ],
    
    # Abilities qui ciblent l'ENNEMI (<t>)
    "target": [
        "provoke", "animated flourish", "shield bash", "flash",
        "weapon bash", "stun", "violent flourish", "desperate flourish",
        "wild flourish",
        "steal", "mug", "trick attack", "sneak attack", "assassinate",
        "feint", "hide", "conspirator",
        "jump", "high jump", "super jump", "spirit jump", "soul jump",
        "angon", "call wyvern", "ancient circle",
        "chi blast", "chakra", "focus", "dodge",
        "provoke", "warcry",
        "quick draw", "triple shot",
        "lunge", "swipe", "gambit", "rayke",
        "sic", "ready", "spur",
        # Debuffs offensifs
        "box step", "quickstep", "stutter step", "feather step",
    ],
    
    # Abilities qui affectent la PARTY (<party>)
    "party": [
        "divine seal", "devotion",
        "soul voice", "pianissimo",
        "marcato", "tenuto",
    ],
    
    # Abilities spéciales (généralement <me> mais peuvent varier)
    "special": [
        "manafont", "chainspell", "soul voice", "azure lore",
        "mighty strikes", "hundred fists", "benediction", "astral flow",
        "meikyo shisui", "blood weapon", "familiar", "soul enslavement",
        "overdrive", "trance", "tabula rasa", "bolster", "elemental siphon",
        "astral conduit", "invincible", "perfect dodge", "spirit surge",
        "unbridled learning", "unbridled wisdom",
    ],
}

# Créer un dictionnaire inversé pour recherche rapide
ABILITY_TO_TARGET = {}
for target_type, abilities in TARGETING_RULES.items():
    for ability in abilities:
        ABILITY_TO_TARGET[ability.lower()] = target_type


def normalize_category(category):
    """
    Normalise les catégories vers un ensemble standard
    """
    if not category:
        return None
    
    cat_lower = category.lower()
    
    # Mapping vers catégories standardisées
    category_map = {
        # Target (ennemi)
        "attack": "target",
        "offense": "target",
        "offensive": "target",
        "debuff": "target",
        
        # Self (soi-même)
        "buff": "self",
        "enhancing": "self",
        "stance": "self",
        "defense": "self",
        "healing": "self",
        "support": "self",
        "utility": "self",
        "enmity": "self",
        "pet": "self",
        "roll": "self",
        "maneuver": "self",
        "merit": "self",
        "ability": "self",
        
        # Flourish (généralement target pour DNC)
        "flourish": "target",
        
        # Quick Draw (COR - target)
        "quick_draw": "target",
        
        # Special (généralement self)
        "special": "self",
        
        # Party reste party
        "party": "party",
        
        # Target reste target
        "target": "target",
        
        # Self reste self
        "self": "self",
    }
    
    return category_map.get(cat_lower, cat_lower)


def determine_target(ability_name, current_category=None):
    """
    Détermine le ciblage approprié pour une ability
    """
    name_lower = ability_name.lower()
    
    # Vérifier les patterns exacts
    if name_lower in ABILITY_TO_TARGET:
        return ABILITY_TO_TARGET[name_lower]
    
    # Vérifier les patterns partiels
    for pattern, target_type in ABILITY_TO_TARGET.items():
        if pattern in name_lower:
            return target_type
    
    # Règles par mots-clés
    if any(word in name_lower for word in ["roll", "shot", "maneuver", "step"]):
        if "step" in name_lower:
            return "target"  # Les steps sont des debuffs
        if "shot" in name_lower and "quick" not in name_lower:
            return "target"  # Quick Draw shots
        return "self"
    
    if any(word in name_lower for word in ["circle", "seal", "arts"]):
        return "self"
    
    if any(word in name_lower for word in ["jump", "bash", "stun"]):
        return "target"
    
    # Normaliser la catégorie existante
    if current_category:
        normalized = normalize_category(current_category)
        if normalized:
            return normalized
    
    # Par défaut, supposer self (plus sûr)
    return "self"


def fix_jobs_json(input_path, output_path=None):
    """
    Corrige le fichier jobs.json en ajoutant/corrigeant les catégories de ciblage
    """
    if output_path is None:
        output_path = input_path
    
    print(f"📖 Lecture de {input_path}...")
    with open(input_path, 'r', encoding='utf-8') as f:
        jobs_data = json.load(f)
    
    stats = {
        "total_abilities": 0,
        "updated": 0,
        "unchanged": 0,
        "by_target": {"self": 0, "target": 0, "party": 0, "special": 0, "area": 0}
    }
    
    # Parcourir tous les jobs
    for job_name, job_data in jobs_data.items():
        if "job_abilities" not in job_data:
            continue
        
        print(f"\n🔧 Traitement de {job_name}...")
        
        for ability in job_data["job_abilities"]:
            stats["total_abilities"] += 1
            ability_name = ability.get("name", "")
            current_category = ability.get("category")
            
            # Déterminer le bon ciblage
            new_category = determine_target(ability_name, current_category)
            
            # Mettre à jour si nécessaire
            if current_category != new_category:
                print(f"  ✏️  {ability_name}: {current_category or 'None'} → {new_category}")
                ability["category"] = new_category
                stats["updated"] += 1
            else:
                stats["unchanged"] += 1
            
            stats["by_target"][new_category] = stats["by_target"].get(new_category, 0) + 1
    
    # Sauvegarder
    print(f"\n💾 Sauvegarde dans {output_path}...")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(jobs_data, f, indent=2, ensure_ascii=False)
    
    # Afficher les statistiques
    print("\n" + "="*60)
    print("📊 STATISTIQUES")
    print("="*60)
    print(f"Total abilities traitées: {stats['total_abilities']}")
    print(f"Mises à jour: {stats['updated']}")
    print(f"Inchangées: {stats['unchanged']}")
    print("\nRépartition par type de ciblage:")
    for target_type, count in sorted(stats['by_target'].items()):
        print(f"  {target_type:10s}: {count:4d}")
    print("="*60)
    print("✅ Terminé!")


if __name__ == "__main__":
    import sys
    
    # Chemin par défaut
    default_path = os.path.join("data_json", "jobs.json")
    
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    else:
        input_file = default_path
    
    if not os.path.exists(input_file):
        print(f"❌ Erreur: Le fichier {input_file} n'existe pas!")
        sys.exit(1)
    
    # Créer une backup
    backup_path = input_file + ".backup"
    print(f"💾 Création d'une backup: {backup_path}")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Appliquer les corrections
    fix_jobs_json(input_file)
    
    print(f"\n💡 Une backup a été créée: {backup_path}")
    print(f"💡 Si vous voulez restaurer: copy {backup_path} {input_file}")
