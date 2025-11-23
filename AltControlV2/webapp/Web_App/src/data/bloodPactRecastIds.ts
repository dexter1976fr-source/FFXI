// Mapping des Blood Pacts vers leurs recast IDs partagés
// Tous les Rage partagent le recast ID 173
// Tous les Ward partagent le recast ID 174

export const BLOOD_PACT_RAGE_ID = 173;
export const BLOOD_PACT_WARD_ID = 174;

// Blood Pacts: Rage (attaques physiques/magiques)
export const BLOOD_PACT_RAGE_NAMES = [
  // Carbuncle
  "Poison Nails", "Meteorite", "Holy Mist",
  // Autres avatars
  "Punch", "Rock Throw", "Barracuda Dive", "Claw",
  "Axe Kick", "Shock Strike", "Camisado", "Regal Scratch",
  "Poison Nails", "Moonlit Charge", "Crescent Fang", "Rock Buster",
  "Burning Strike", "Meteorite", "Conflag Strike", "Flaming Crush",
  "Double Punch", "Megalith Throw", "Double Slap", "Eclipse Bite",
  "Mountain Buster", "Spinning Dive", "Predator Claws", "Rush",
  "Chaotic Strike", "Volt Strike", "Hysteric Assault", "Crag Throw",
  "Tail Whip", "Roundhouse", "Lunar Bay", "Spring Water",
  "Grand Fall", "Meteor Strike", "Heavenly Strike", "Wind Blade",
  "Geocrush", "Thunderstorm", "Thunderspark", "Slowga",
  "Tidal Wave", "Diamond Storm", "Earthen Fury", "Aerial Blast",
  "Clarsach Call", "Zantetsuken", "Howling Moon", "Ruinous Omen",
  "Fire II", "Stone II", "Water II", "Aero II", "Blizzard II", "Thunder II",
  "Fire IV", "Stone IV", "Water IV", "Aero IV", "Blizzard IV", "Thunder IV",
  "Thunderstorm", "Nether Blast", "Night Terror", "Level ? Holy",
  "Sonic Buffet", "Lunar Roar", "Hysteric Barrage", "Impact",
  "Conflag Strike", "Flaming Crush", "Meteor Strike", "Heavenly Strike",
  "Geocrush", "Grand Fall", "Wind Blade", "Thunderstorm",
  "Searing Light", "Inferno Howl", "Lunar Cry", "Tornado II",
  "Earthen Armor", "Tidal Roar", "Diamond Dust", "Judgment Bolt",
  "Mewing Lullaby", "Eerie Eye", "Bitter Elegy", "Chaos Roll",
  "Somnolence", "Nightmare", "Ultimate Terror", "Noctoshield",
  "Dream Shroud", "Altana's Favor", "Reraise", "Reraise II", "Reraise III",
  "Raise II", "Raise III"
];

// Blood Pacts: Ward (buffs/debuffs)
export const BLOOD_PACT_WARD_NAMES = [
  // Carbuncle
  "Shining Ruby", "Glittering Ruby", "Healing Ruby", "Healing Ruby II", 
  "Soothing Ruby", "Pacifying Ruby",
  // Autres avatars
  "Crimson Howl", "Inferno Howl",
  "Frost Armor", "Crystal Blessing", "Aerial Armor", "Hastega",
  "Fleet Wind", "Hastega II", "Earthen Ward", "Earthen Armor",
  "Rolling Thunder", "Lightning Armor", "Soothing Current", "Spring Water",
  "Ecliptic Growl", "Ecliptic Howl", "Heavenward Howl", "Lunar Cry",
  "Lunar Roar", "Raise II", "Reraise II", "Whispering Wind",
  "Healing Ruby", "Healing Ruby II", "Soothing Ruby", "Pacifying Ruby",
  "Shining Ruby", "Glittering Ruby", "Meteorite", "Healing Ruby",
  "Soothing Ruby", "Pacifying Ruby", "Poison Nails", "Predator Claws",
  "Slowga", "Tidal Roar", "Diamond Dust", "Earthen Ward",
  "Hastega", "Noctoshield", "Dream Shroud", "Perfect Defense",
  "Altana's Favor", "Reraise", "Reraise II", "Reraise III",
  "Raise II", "Raise III", "Whispering Wind", "Mewing Lullaby",
  "Eerie Eye", "Lunar Cry", "Lunar Roar", "Ecliptic Growl",
  "Ecliptic Howl", "Heavenward Howl", "Inferno Howl", "Earthen Armor",
  "Fleet Wind", "Hastega II", "Crystal Blessing", "Katabatic Blades",
  "Soothing Current", "Hastega", "Rolling Thunder", "Lightning Armor",
  "Crimson Howl", "Inferno Howl", "Frost Armor", "Aerial Armor"
];

// Fonction pour déterminer le recast ID d'un Blood Pact
export function getBloodPactRecastId(bloodPactName: string): number | null {
  if (BLOOD_PACT_RAGE_NAMES.includes(bloodPactName)) {
    return BLOOD_PACT_RAGE_ID;
  }
  if (BLOOD_PACT_WARD_NAMES.includes(bloodPactName)) {
    return BLOOD_PACT_WARD_ID;
  }
  return null;
}
