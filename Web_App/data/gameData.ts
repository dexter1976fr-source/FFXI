import { Spell, JobAbility, WeaponSkill, PartyMember } from "../types";

// Exemples de sorts (à remplacer plus tard)
export const exampleSpells: Spell[] = [
  { name: "Cure", level: 1, mpCost: 8, type: "support" },
  { name: "Cure II", level: 11, mpCost: 24, type: "support" },
  { name: "Cure III", level: 21, mpCost: 46, type: "support" },
  { name: "Fire", level: 4, mpCost: 9, type: "offensive" },
  { name: "Fire II", level: 26, mpCost: 51, type: "offensive" },
  { name: "Blizzard", level: 1, mpCost: 8, type: "offensive" },
  { name: "Thunder", level: 7, mpCost: 12, type: "offensive" },
  { name: "Protect", level: 7, mpCost: 9, type: "support" },
  { name: "Shell", level: 17, mpCost: 18, type: "support" },
  { name: "Haste", level: 40, mpCost: 40, type: "support" },
];

// Exemples de Job Abilities
export const exampleJobAbilities: JobAbility[] = [
  { name: "Provoke", recast: 30 },
  { name: "Berserk", recast: 300 },
  { name: "Defender", recast: 180 },
  { name: "Warcry", recast: 300 },
  { name: "Aggressor", recast: 300 },
  { name: "Sneak Attack", recast: 60 },
  { name: "Trick Attack", recast: 60 },
];

// Exemples de Weapon Skills
export const exampleWeaponSkills: WeaponSkill[] = [
  { name: "Fast Blade", tpCost: 1000 },
  { name: "Burning Blade", tpCost: 1000 },
  { name: "Red Lotus Blade", tpCost: 1000 },
  { name: "Vorpal Blade", tpCost: 1000 },
  { name: "Savage Blade", tpCost: 1000 },
  { name: "Dancing Edge", tpCost: 1000 },
  { name: "Shark Bite", tpCost: 1000 },
];

// Exemples de Pet Commands
export const examplePetCommands: string[] = [
  "Fight",
  "Heel",
  "Stay",
  "Release",
  "Assault",
  "Retreat",
];

// Locations de téléportation
export const teleportLocations = [
  "Warp",
  "Holla",
  "Dem",
  "Mea",
  "Vahzl",
  "Library",
  "expcamp",
  "expclassic",
  "Caldera",
];

// Membres de party (exemples - à remplacer par les données du serveur Python)
export const examplePartyMembers: PartyMember[] = [
  { id: "p1", name: "Main (You)", job: "PLD" },
  { id: "p2", name: "Altair", job: "WAR" },
  { id: "p3", name: "Vega", job: "WHM" },
  { id: "p4", name: "Sirius", job: "BLM" },
  { id: "p5", name: "Rigel", job: "THF" },
  { id: "p6", name: "Betelgeuse", job: "DRK" },
];