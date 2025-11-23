#!/usr/bin/env python3
"""
Script pour générer abilityIds.ts à partir de jobs.json
"""
import json

# Base de données des IDs d'abilities FFXI (extraits de Windower resources)
ABILITY_ID_DATABASE = {
    # WAR
    "Provoke": 5, "Berserk": 1, "Defender": 3, "Warcry": 2, "Aggressor": 4,
    "Mighty Strikes": 0, "Retaliation": 6, "Restraint": 7, "Blood Rage": 8,
    
    # MNK
    "Boost": 9, "Dodge": 10, "Focus": 11, "Chakra": 12, "Counterstance": 13,
    "Hundred Fists": 0, "Perfect Counter": 14, "Impetus": 15, "Inner Strength": 16,
    
    # WHM
    "Divine Seal": 26, "Benediction": 0, "Devotion": 27, "Asylum": 28,
    
    # BLM
    "Elemental Seal": 28, "Manafont": 0, "Manawell": 29, "Cascade": 30,
    
    # RDM
    "Convert": 41, "Chainspell": 0, "Composure": 42, "Saboteur": 43, "Spontaneity": 44,
    
    # THF
    "Steal": 5, "Mug": 15, "Hide": 16, "Flee": 17, "Sneak Attack": 18, "Trick Attack": 19,
    "Perfect Dodge": 0, "Despoil": 20, "Conspirator": 21, "Collaborator": 22,
    
    # PLD
    "Holy Circle": 22, "Shield Bash": 23, "Sentinel": 24, "Cover": 25, "Invincible": 0,
    "Rampart": 26, "Fealty": 27, "Chivalry": 28, "Divine Emblem": 29,
    
    # DRK
    "Arcane Circle": 20, "Last Resort": 21, "Weapon Bash": 27, "Souleater": 29, "Blood Weapon": 0,
    "Diabolic Eye": 30, "Nether Void": 31, "Dark Seal": 32, "Scarlet Delirium": 33,
    
    # BST
    "Charm": 9, "Reward": 5, "Tame": 6, "Familiar": 7, "Snarl": 8,
    "Call Beast": 10, "Leave": 11, "Feral Howl": 12, "Killer Instinct": 13,
    
    # BRD
    "Pianissimo": 48, "Nightingale": 0, "Troubadour": 49, "Tenuto": 50, "Marcato": 51,
    
    # RNG
    "Scavenge": 52, "Camouflage": 53, "Sharpshot": 54, "Unlimited Shot": 0,
    "Flashy Shot": 55, "Stealth Shot": 56, "Bounty Shot": 57, "Double Shot": 58,
    
    # SAM
    "Meditate": 134, "Warding Circle": 135, "Third Eye": 136, "Hasso": 137, "Seigan": 138,
    "Meikyo Shisui": 0, "Hagakure": 139, "Konzen-ittai": 140, "Yaegasumi": 141,
    
    # NIN
    "Mijin Gakure": 0, "Yonin": 142, "Innin": 143, "Sange": 144, "Futae": 145,
    
    # DRG
    "Ancient Circle": 14, "Jump": 158, "High Jump": 159, "Super Jump": 160,
    "Spirit Surge": 0, "Call Wyvern": 161, "Spirit Link": 162, "Soul Jump": 163,
    "Angon": 164, "Spirit Bond": 165,
    
    # SMN
    "Astral Flow": 0, "Elemental Siphon": 175, "Mana Cede": 176, "Avatar's Favor": 177,
    "Apogee": 178, "Astral Conduit": 179,
    
    # BLU
    "Azure Lore": 0, "Burst Affinity": 171, "Chain Affinity": 172, "Efflux": 173,
    "Diffusion": 174, "Unbridled Learning": 175, "Convergence": 176,
    
    # COR
    "Phantom Roll": 177, "Double-Up": 178, "Quick Draw": 179, "Wild Card": 0,
    "Random Deal": 180, "Snake Eye": 181, "Fold": 182, "Crooked Cards": 183,
    "Triple Shot": 184, "Cutting Cards": 185,
    
    # PUP
    "Activate": 186, "Deactivate": 187, "Repair": 188, "Maintenance": 189,
    "Deploy": 190, "Retrieve": 191, "Overdrive": 0, "Ventriloquy": 192,
    "Role Reversal": 193, "Tactical Switch": 194, "Cooldown": 195,
    
    # DNC
    "Sambas": 196, "Waltzes": 197, "Steps": 198, "Flourishes": 199,
    "Trance": 0, "Grand Pas": 200, "Contradance": 201, "Presto": 202,
    "Building Flourish": 203, "Striking Flourish": 204, "Ternary Flourish": 205,
    
    # SCH
    "Light Arts": 206, "Dark Arts": 207, "Addendum: White": 208, "Addendum: Black": 209,
    "Sublimation": 210, "Tabula Rasa": 0, "Enlightenment": 211, "Immanence": 212,
    "Perpetuance": 213, "Rapture": 214, "Ebullience": 215, "Accession": 216,
    "Manifestation": 217, "Alacrity": 218, "Parsimony": 219, "Penury": 220,
    "Celerity": 221, "Tranquility": 222, "Equanimity": 223, "Focalization": 224,
    
    # GEO
    "Full Circle": 225, "Bolster": 0, "Blaze of Glory": 226, "Dematerialize": 227,
    "Theurgic Focus": 228, "Concentric Pulse": 229, "Mending Halation": 230,
    "Radial Arcana": 231, "Entrust": 232, "Life Cycle": 233,
    
    # RUN
    "Ignis": 234, "Gelus": 235, "Flabra": 236, "Tellus": 237, "Sulpor": 238,
    "Unda": 239, "Lux": 240, "Tenebrae": 241, "Vallation": 242, "Valiance": 243,
    "Pflug": 244, "Swordplay": 245, "Embolden": 246, "Vivacious Pulse": 247,
    "One for All": 248, "Gambit": 249, "Rayke": 250, "Battuta": 251,
    "Liement": 252, "Elemental Sforzo": 253, "Odyllic Subterfuge": 254,
}

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire toutes les abilities uniques
all_abilities = {}

for job_name, job_data in jobs_data.items():
    if 'job_abilities' in job_data:
        for ability in job_data['job_abilities']:
            ability_name = ability.get('name', '')
            if ability_name and ability_name not in all_abilities:
                # Chercher l'ID dans la base de données
                ability_id = ABILITY_ID_DATABASE.get(ability_name)
                if ability_id is not None:  # 0 est valide pour les 2h abilities
                    all_abilities[ability_name] = ability_id

# Trier par ID
sorted_abilities = sorted(all_abilities.items(), key=lambda x: x[1])

# Générer le fichier TypeScript
output = """// Mapping des IDs d'abilities FFXI vers leurs noms
// Auto-généré depuis jobs.json
// Source IDs: FFXIAH, BG Wiki, Windower resources

export const ABILITY_IDS: Record<number, string> = {
"""

for ability_name, ability_id in sorted_abilities:
    output += f'  {ability_id}: "{ability_name}",\n'

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

print(f"✅ Fichier abilityIds.ts généré avec {len(all_abilities)} abilities!")
