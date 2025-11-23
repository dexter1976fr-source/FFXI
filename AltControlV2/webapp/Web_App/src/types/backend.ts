// Types complets pour les données backend JSON

export interface BackendSpell {
  name: string;
  type: "offensive" | "support" | "healing" | "enfeebling" | "enhancing";
  mpCost: number;
  recast?: number;
  level: number;
  targets?: string; // "self", "party", "enemy", "area"
  element?: string;
  description?: string;
}

export interface BackendJobAbility {
  name: string;
  recast: number;
  level: number;
  description?: string;
  type?: string;
}

export interface BackendWeaponSkill {
  name: string;
  tpCost: number;
  weaponType: string;
  skillchain?: string[];
  description?: string;
}

export interface BackendPetCommand {
  name: string;
  type: "attack" | "ability" | "ready" | "stance";
  description?: string;
  mpCost?: number;
  tpCost?: number;
}

export interface BackendMacro {
  id: string;
  name: string;
  command: string;
  description?: string;
  icon?: string;
}

export interface BackendWeapon {
  id: string;
  name: string;
  type: string; // "sword", "staff", "dagger", etc.
  damage?: number;
  delay?: number;
}

export interface BackendPet {
  name: string;
  type: string; // "wyvern", "avatar", "automaton", etc.
  level?: number;
  hp?: number;
  mp?: number;
  attacks: BackendPetCommand[];
}

export interface BackendPartyMember {
  id: string;
  name: string;
  job: string;
  subJob?: string;
  level?: number;
  hp?: number;
  mp?: number;
  status?: string; // "alive", "dead", "offline"
}

export interface BackendAltData {
  alt_name: string;
  main_job: string;
  sub_job: string;
  main_job_level: number;
  sub_job_level: number;
  weapon: BackendWeapon;
  pet?: BackendPet;
  available_spells: BackendSpell[];
  job_abilities: BackendJobAbility[];
  weapon_skills: BackendWeaponSkill[];
  pet_commands: BackendPetCommand[];
  macros: BackendMacro[];
  party_members: BackendPartyMember[];
  connection_status?: "connected" | "disconnected" | "reconnecting";
  position?: { x: number; y: number; z: number; zone?: string };
  stats?: {
    hp: number;
    mp: number;
    tp: number;
    max_hp: number;
    max_mp: number;
  };
}

export interface BackendCommandPayload {
  altName: string;
  action: string;
}

export interface WebSocketMessage {
  type: "update" | "status" | "party" | "command_result" | "error";
  altName?: string;
  data: any;
  timestamp?: number;
}

export interface AltConfigPersist {
  alt_name: string;
  main_job: string;
  sub_job: string;
  selected_spells: string[];
  selected_job_abilities: string[];
  selected_weapon_skills: string[];
  selected_macros: string[];
  last_updated: number;
}
