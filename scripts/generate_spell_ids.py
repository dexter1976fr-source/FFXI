#!/usr/bin/env python3
"""
Script pour générer spellIds.ts complet à partir de jobs.json
Utilise une base de données FFXI pour les IDs corrects
"""
import json
import re

# Base de données des IDs de sorts FFXI (source: FFXIAH, BG Wiki, Windower resources)
SPELL_ID_DATABASE = {
    # White Magic - Cure
    "Cure": 1, "Cure II": 2, "Cure III": 3, "Cure IV": 4, "Cure V": 5, "Cure VI": 6,
    "Curaga": 7, "Curaga II": 8, "Curaga III": 9, "Curaga IV": 10, "Curaga V": 11,
    
    # White Magic - Raise
    "Raise": 12, "Raise II": 13, "Raise III": 14,
    "Reraise": 140, "Reraise II": 141, "Reraise III": 142,
    
    # White Magic - Status Recovery
    "Poisona": 15, "Paralyna": 16, "Blindna": 17, "Silena": 18, "Stona": 19,
    "Viruna": 20, "Cursna": 21, "Erase": 143,
    
    # White Magic - Protect/Shell
    "Protect": 43, "Protect II": 44, "Protect III": 45, "Protect IV": 46, "Protect V": 47,
    "Shell": 48, "Shell II": 49, "Shell III": 50, "Shell IV": 51, "Shell V": 52,
    "Protectra": 125, "Protectra II": 126, "Protectra III": 127, "Protectra IV": 128, "Protectra V": 129,
    "Shellra": 130, "Shellra II": 131, "Shellra III": 132, "Shellra IV": 133, "Shellra V": 134,
    
    # White Magic - Regen
    "Regen": 108, "Regen II": 110, "Regen III": 111, "Regen IV": 477, "Regen V": 848,
    
    # White Magic - Bar-spells
    "Barfire": 60, "Barblizzard": 61, "Baraero": 62, "Barstone": 63, "Barthunder": 64, "Barwater": 65,
    "Barsleep": 66, "Barpoison": 67, "Barparalyze": 68, "Barblind": 69, "Barsilence": 70, "Barpetrify": 71,
    "Barvirus": 72, "Baramnesia": 73,
    
    # White Magic - Enhancing
    "Haste": 57, "Haste II": 511, "Slow": 56, "Slow II": 79,
    "Blink": 53, "Stoneskin": 54, "Aquaveil": 113, "Phalanx": 106, "Phalanx II": 107,
    "Refresh": 109, "Refresh II": 473, "Refresh III": 894,
    "Sneak": 114, "Invisible": 115, "Deodorize": 116,
    "Teleport-Holla": 118, "Teleport-Dem": 119, "Teleport-Mea": 120,
    "Teleport-Altep": 262, "Teleport-Yhoat": 263, "Teleport-Vahzl": 264,
    "Escape": 135, "Warp": 117, "Warp II": 262,
    "Flash": 112, "Reprisal": 97,
    
    # White Magic - Divine
    "Banish": 28, "Banish II": 29, "Banish III": 30, "Banishga": 38, "Banishga II": 39,
    "Holy": 21, "Holy II": 499,
    
    # Black Magic - Fire
    "Fire": 144, "Fire II": 145, "Fire III": 147, "Fire IV": 204, "Fire V": 245, "Fire VI": 846,
    "Firaga": 174, "Firaga II": 175, "Firaga III": 176, "Firaga IV": 204,
    "Burn": 235, "Flare": 218, "Flare II": 844,
    
    # Black Magic - Ice
    "Blizzard": 149, "Blizzard II": 150, "Blizzard III": 152, "Blizzard IV": 206, "Blizzard V": 246, "Blizzard VI": 847,
    "Blizzaga": 179, "Blizzaga II": 180, "Blizzaga III": 181, "Blizzaga IV": 206,
    "Frost": 236, "Freeze": 219, "Freeze II": 845,
    
    # Black Magic - Wind
    "Aero": 154, "Aero II": 155, "Aero III": 157, "Aero IV": 208, "Aero V": 247, "Aero VI": 849,
    "Aeroga": 184, "Aeroga II": 185, "Aeroga III": 186, "Aeroga IV": 208,
    "Choke": 237, "Tornado": 220, "Tornado II": 850,
    
    # Black Magic - Earth
    "Stone": 159, "Stone II": 160, "Stone III": 162, "Stone IV": 213, "Stone V": 250, "Stone VI": 851,
    "Stonega": 189, "Stonega II": 190, "Stonega III": 191, "Stonega IV": 213,
    "Rasp": 238, "Quake": 221, "Quake II": 852,
    
    # Black Magic - Thunder
    "Thunder": 164, "Thunder II": 165, "Thunder III": 167, "Thunder IV": 210, "Thunder V": 248, "Thunder VI": 853,
    "Thundaga": 194, "Thundaga II": 195, "Thundaga III": 196, "Thundaga IV": 210,
    "Shock": 239, "Burst": 222, "Burst II": 854,
    
    # Black Magic - Water
    "Water": 169, "Water II": 170, "Water III": 172, "Water IV": 212, "Water V": 249, "Water VI": 855,
    "Waterga": 199, "Waterga II": 200, "Waterga III": 201, "Waterga IV": 212,
    "Drown": 240, "Flood": 223, "Flood II": 856,
    
    # Black Magic - Enfeebling
    "Dia": 23, "Dia II": 24, "Dia III": 25, "Diaga": 33,
    "Bio": 230, "Bio II": 231, "Bio III": 232,
    "Poison": 220, "Poison II": 221, "Poisonga": 225,
    "Blind": 254, "Blind II": 276,
    "Paralyze": 58, "Paralyze II": 80,
    "Silence": 59,
    "Sleep": 253, "Sleep II": 259, "Sleepga": 273, "Sleepga II": 274,
    "Bind": 258, "Gravity": 216, "Gravity II": 217,
    "Break": 255, "Breakga": 365,
    "Dispel": 260,
    
    # Black Magic - Dark
    "Drain": 245, "Drain II": 246, "Drain III": 247,
    "Aspir": 247, "Aspir II": 248, "Aspir III": 249,
    "Dread Spikes": 277, "Stun": 252,
    "Tractor": 261,
    
    # Summoning
    "Carbuncle": 296, "Fenrir": 297, "Ifrit": 298, "Titan": 299, "Leviathan": 300,
    "Garuda": 301, "Shiva": 302, "Ramuh": 303, "Diabolos": 304,
    "Alexander": 305, "Odin": 306, "Atomos": 307, "Cait Sith": 308, "Siren": 309,
    
    # Ninjutsu
    "Utsusemi: Ichi": 338, "Utsusemi: Ni": 339, "Utsusemi: San": 340,
    "Tonko: Ichi": 319, "Tonko: Ni": 320,
    "Hojo: Ichi": 344, "Hojo: Ni": 345,
    "Kurayami: Ichi": 347, "Kurayami: Ni": 348,
    "Dokumori: Ichi": 350, "Dokumori: Ni": 351,
    "Jubaku: Ichi": 341, "Jubaku: Ni": 342,
    "Katon: Ichi": 320, "Katon: Ni": 321, "Katon: San": 322,
    "Hyoton: Ichi": 323, "Hyoton: Ni": 324, "Hyoton: San": 325,
    "Huton: Ichi": 326, "Huton: Ni": 327, "Huton: San": 328,
    "Doton: Ichi": 329, "Doton: Ni": 330, "Doton: San": 331,
    "Raiton: Ichi": 332, "Raiton: Ni": 333, "Raiton: San": 334,
    "Suiton: Ichi": 335, "Suiton: Ni": 336, "Suiton: San": 337,
    
    # Bard Songs
    "Foe Requiem": 368, "Foe Requiem II": 369, "Foe Requiem III": 370, "Foe Requiem IX": 454,
    "Horde Lullaby": 376, "Horde Lullaby II": 377,
    "Foe Lullaby": 463,
    "Army's Paeon": 378, "Army's Paeon II": 379, "Army's Paeon III": 380, "Army's Paeon IV": 381,
    "Army's Paeon V": 382, "Army's Paeon VI": 383, "Army's Paeon VII": 384,
    "Mage's Ballad": 386, "Mage's Ballad II": 387, "Mage's Ballad III": 388,
    "Mage's Ballad IV": 389, "Mage's Ballad V": 390,
    "Knight's Minne": 391, "Knight's Minne II": 392, "Knight's Minne III": 393,
    "Knight's Minne IV": 394, "Knight's Minne V": 395, "Knight's Minne VI": 396,
    "Valor Minuet": 397, "Valor Minuet II": 398, "Valor Minuet III": 399,
    "Valor Minuet IV": 400, "Valor Minuet V": 401, "Valor Minuet VI": 402,
    "Sword Madrigal": 403, "Sword Madrigal II": 404,
    "Advancing March": 419, "Victory March": 420,
    "Sheepfoe Mambo": 421, "Sheepfoe Mambo II": 422,
    "Raptor Mazurka": 423,
    "Fowl Aubade": 424,
    "Scop's Operetta": 425,
    "Puppet's Operetta": 426,
    "Herb Pastoral": 427,
    "Shining Fantasia": 428,
    "Sentinel's Scherzo": 463,
    "Adventurer's Dirge": 464,
    "Foe Sirvente": 465,
    "Battlefield Elegy": 421,
    "Carnage Elegy": 422,
    "Magic Finale": 462,
    
    # Blue Magic (quelques exemples courants)
    "Cocoon": 547, "Refueling": 548, "Feather Barrier": 549,
    "Metallic Body": 550, "Plasma Charge": 551,
    "Pollen": 552, "Healing Breeze": 553, "Wild Oats": 554,
    "Magic Fruit": 555, "Regeneration": 556, "White Wind": 557,
    "Foot Kick": 512, "Power Attack": 513, "Sprout Smack": 514,
    "Head Butt": 515, "Cocoon": 516, "Sheep Song": 584,
    "Battle Dance": 585, "Chaotic Eye": 586, "Blank Gaze": 587,
    "Magic Hammer": 588, "Digest": 589,
}

# Lire jobs.json
with open('data_json/jobs.json', 'r', encoding='utf-8') as f:
    jobs_data = json.load(f)

# Extraire tous les sorts uniques
all_spells = {}

for job_name, job_data in jobs_data.items():
    if 'spells' in job_data:
        for spell in job_data['spells']:
            spell_name = spell.get('name', '')
            if spell_name and spell_name not in all_spells:
                # Chercher l'ID dans la base de données
                spell_id = SPELL_ID_DATABASE.get(spell_name)
                if spell_id:
                    all_spells[spell_name] = spell_id

# Trier par ID
sorted_spells = sorted(all_spells.items(), key=lambda x: x[1])

# Générer le fichier TypeScript
output = """// Mapping des IDs de spells FFXI vers leurs noms
// Auto-généré depuis jobs.json
// Source IDs: FFXIAH, BG Wiki, Windower resources

export const SPELL_IDS: Record<number, string> = {
"""

current_category = None
for spell_name, spell_id in sorted_spells:
    # Ajouter des commentaires de catégorie
    if spell_id < 50 and current_category != "White Magic - Cure/Raise/Status":
        output += "\n  // White Magic - Cure/Raise/Status\n"
        current_category = "White Magic - Cure/Raise/Status"
    elif 50 <= spell_id < 100 and current_category != "White Magic - Protect/Shell/Bar":
        output += "\n  // White Magic - Protect/Shell/Bar\n"
        current_category = "White Magic - Protect/Shell/Bar"
    elif 100 <= spell_id < 144 and current_category != "White Magic - Enhancing":
        output += "\n  // White Magic - Enhancing\n"
        current_category = "White Magic - Enhancing"
    elif 144 <= spell_id < 230 and current_category != "Black Magic - Elemental":
        output += "\n  // Black Magic - Elemental\n"
        current_category = "Black Magic - Elemental"
    elif 230 <= spell_id < 280 and current_category != "Black Magic - Enfeebling/Dark":
        output += "\n  // Black Magic - Enfeebling/Dark\n"
        current_category = "Black Magic - Enfeebling/Dark"
    elif 296 <= spell_id < 320 and current_category != "Summoning":
        output += "\n  // Summoning\n"
        current_category = "Summoning"
    elif 320 <= spell_id < 360 and current_category != "Ninjutsu":
        output += "\n  // Ninjutsu\n"
        current_category = "Ninjutsu"
    elif 368 <= spell_id < 470 and current_category != "Bard Songs":
        output += "\n  // Bard Songs\n"
        current_category = "Bard Songs"
    elif 512 <= spell_id < 600 and current_category != "Blue Magic":
        output += "\n  // Blue Magic\n"
        current_category = "Blue Magic"
    
    output += f'  {spell_id}: "{spell_name}",\n'

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

print(f"✅ Fichier spellIds.ts généré avec {len(all_spells)} sorts!")
print(f"📊 Sorts trouvés dans jobs.json: {len(all_spells)}")
print(f"⚠️  Sorts sans ID connu: {427 - len(all_spells)}")
