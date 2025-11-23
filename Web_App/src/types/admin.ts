export interface AltConfig {
  name: string;
  job: string;
  subJob: string;
  selectedSpells: string[];
  selectedWeaponSkills: string[];
}

export interface ServerAltData {
  name: string;
  job: string;
  subJob: string;
  availableSpells: string[];
  availableWeaponSkills: string[];
  jobAbilities: string[];
  petCommands: string[];
}

export interface AltConfigStorage {
  [key: string]: AltConfig; // key format: "AltName_Job_SubJob"
}
