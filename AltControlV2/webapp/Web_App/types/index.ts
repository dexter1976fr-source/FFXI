export interface AltCharacter {
  name: string;
  job: string;
  subJob: string;
}

export interface Command {
  type: string;
  action: string;
  target?: string;
  parameters?: Record<string, unknown>;
}

export type TeleportLocation = 
  | "Warp"
  | "Holla"
  | "Dem"
  | "Mea"
  | "Vahzl"
  | "Library"
  | "expcamp"
  | "expclassic"
  | "Caldera";

export type Direction = "up" | "down" | "left" | "right";

export interface Spell {
  name: string;
  level: number;
  mpCost: number;
  type: "offensive" | "support";
}

export interface PartyMember {
  id: string;
  name: string;
  job?: string;
}

export interface JobAbility {
  name: string;
  recast: number;
}

export interface WeaponSkill {
  name: string;
  tpCost: number;
}