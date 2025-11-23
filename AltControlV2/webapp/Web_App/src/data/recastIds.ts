// Mapping des noms de commandes FFXI vers leurs Recast IDs
// Les Recast IDs sont utilisés pour tracker les cooldowns via l'API du serveur

export interface RecastInfo {
  id: number;        // L'ID de recast utilisé par le serveur
  type: 'spell' | 'ability' | 'item';  // Type de recast
}

// Mapping des sorts (Magic Recast IDs)
export const SPELL_RECAST_IDS: Record<string, number> = {
  // White Magic - Cure
  "Cure": 1,
  "Cure II": 2,
  "Cure III": 3,
  "Cure IV": 4,
  "Cure V": 5,
  "Cure VI": 6,
  
  // White Magic - Raise
  "Raise": 12,
  "Raise II": 13,
  "Raise III": 14,
  "Reraise": 140,
  
  // White Magic - Protect/Shell
  "Protect": 43,
  "Protect II": 44,
  "Protect III": 45,
  "Protect IV": 46,
  "Protect V": 47,
  "Shell": 48,
  "Shell II": 49,
  "Shell III": 50,
  "Shell IV": 51,
  "Shell V": 52,
  
  // White Magic - Regen
  "Regen": 108,
  "Regen II": 110,
  "Regen III": 111,
  "Regen IV": 477,
  
  // White Magic - Haste
  "Haste": 57,
  "Haste II": 511,
  
  // Black Magic - Fire
  "Fire": 144,
  "Fire II": 145,
  "Fire III": 147,
  "Fire IV": 204,
  "Fire V": 245,
  
  // Black Magic - Blizzard
  "Blizzard": 149,
  "Blizzard II": 150,
  "Blizzard III": 152,
  "Blizzard IV": 206,
  "Blizzard V": 246,
  
  // Black Magic - Thunder
  "Thunder": 164,
  "Thunder II": 165,
  "Thunder III": 167,
  "Thunder IV": 210,
  "Thunder V": 248,
  
  // Black Magic - Water
  "Water": 169,
  "Water II": 170,
  "Water III": 172,
  "Water IV": 212,
  "Water V": 249,
  
  // Black Magic - Aero
  "Aero": 154,
  "Aero II": 155,
  "Aero III": 157,
  "Aero IV": 208,
  "Aero V": 247,
  
  // Black Magic - Stone
  "Stone": 159,
  "Stone II": 160,
  "Stone III": 162,
  "Stone IV": 213,
  "Stone V": 250,
  
  // Black Magic - Sleep
  "Sleep": 253,
  "Sleep II": 259,
  "Sleepga": 273,
  "Sleepga II": 274,
  
  // Enfeebling
  "Dia": 23,
  "Dia II": 24,
  "Dia III": 25,
  "Diaga": 33,
  "Slow": 56,
  "Slow II": 79,
  "Paralyze": 58,
  "Paralyze II": 80,
  "Silence": 59,
  "Blind": 216,
  "Blind II": 254,
  
  // Enhancing
  "Refresh": 109,
  "Refresh II": 473,
  "Blink": 106,
  "Phalanx": 55,
  "Phalanx II": 107,
  "Stoneskin": 54,
  "Flash": 112,
  "Aquaveil": 113,
  "Sneak": 114,
  "Invisible": 115,
  "Deodorize": 116,
  
  // Ninjutsu
  "Utsusemi: Ichi": 319,
  "Utsusemi: Ni": 338,
};

// Mapping des Job Abilities (Ability Recast IDs)
// Note: Les abilities utilisent un système de recast différent des sorts
export const ABILITY_RECAST_IDS: Record<string, number> = {
  // BST Pet Commands
  "Fight": 0,
  "Heel": 1,
  "Stay": 2,
  "Sic": 3,
  "Release": 4,  // BST Release
  "Reward": 5,
  "Tame": 6,
  "Familiar": 7,
  "Snarl": 8,
  "Charm": 9,
  
  // SMN Pet Commands (Note: Release partage le même ID que BST)
  "Assault": 0,
  "Retreat": 1,
  
  // DRG Pet Commands
  "Call Wyvern": 163,
  "Spirit Link": 162,
  "Dismiss": 161,
  "Steady Wing": 70,
  "Smiting Breath": 238,
  "Restoring Breath": 239,
  
  // Common Job Abilities
  "Provoke": 5,
  "Berserk": 1,
  "Defender": 3,
  "Warcry": 2,
  "Aggressor": 4,
  
  // WHM
  "Divine Seal": 26,
  "Benediction": 0,
  
  // BLM
  "Manafont": 0,
  "Elemental Seal": 28,
  
  // RDM
  "Convert": 41,
  "Chainspell": 0,
  
  // THF
  "Steal": 5,
  "Mug": 15,
  "Hide": 16,
  "Flee": 17,
  "Sneak Attack": 18,
  "Trick Attack": 19,
  
  // PLD
  "Holy Circle": 22,
  "Shield Bash": 23,
  "Sentinel": 24,
  "Cover": 25,
  "Invincible": 0,
  
  // DRK
  "Arcane Circle": 20,
  "Last Resort": 21,
  "Weapon Bash": 27,
  "Souleater": 29,
  "Blood Weapon": 0,
  
  // DRG
  "Ancient Circle": 14,
  "Jump": 158,
  "High Jump": 159,
  "Super Jump": 160,
  "Spirit Surge": 0,
  
  // SAM
  "Meditate": 134,
  "Warding Circle": 135,
  "Third Eye": 136,
  "Hasso": 137,
  "Seigan": 138,
  "Meikyo Shisui": 0,
};

// Fonction helper pour obtenir le recast ID d'une commande
export function getRecastId(commandName: string): RecastInfo | undefined {
  // Normaliser le nom (enlever les espaces multiples, trim, etc.)
  const normalized = commandName.trim();
  
  // Chercher dans les sorts
  if (SPELL_RECAST_IDS[normalized] !== undefined) {
    return {
      id: SPELL_RECAST_IDS[normalized],
      type: 'spell'
    };
  }
  
  // Chercher dans les abilities
  if (ABILITY_RECAST_IDS[normalized] !== undefined) {
    return {
      id: ABILITY_RECAST_IDS[normalized],
      type: 'ability'
    };
  }
  
  return undefined;
}

// Fonction helper pour vérifier si une commande a un recast
export function hasRecast(commandName: string): boolean {
  return getRecastId(commandName) !== undefined;
}
