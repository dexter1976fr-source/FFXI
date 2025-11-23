/**
 * Types TypeScript pour l'application
 */

export interface AltData {
  name: string;
  main_job: string;
  sub_job: string;
  main_job_level: number;
  sub_job_level: number;
  hp: number;
  hpp: number;
  mp: number;
  mpp: number;
  tp: number;
  status: number;
  is_engaged: boolean;
  
  // Position
  x: number;
  y: number;
  z: number;
  
  // Données spéciales
  weapon_type?: string;
  pet_name?: string;
  pet_hp?: number;
  pet_hpp?: number;
  pet_tp?: number;
  bst_ready_charges?: number;
  
  // Buffs et party
  active_buffs: number[];
  party: string[];
  
  // Recasts
  spell_recasts?: Record<string, number>;
  ability_recasts?: Record<string, number>;
  
  // Données job
  spells?: any[];
  job_abilities?: any[];
  pet_commands?: any[];
  pet_attacks?: Record<string, any[]>;
  weapon_skills?: string[];
  macros?: any[];
  
  // Connexion
  address?: [string, number];
  last_update?: number;
}

export interface CommandButtonProps {
  label: string;
  icon?: React.ReactNode;
  onClick: () => void;
  variant?: 'primary' | 'success' | 'warning' | 'danger';
  disabled?: boolean;
}

export interface Spell {
  name: string;
  level: number;
  mp: number;
  element?: string;
  type: string;
  category: string;
}

export interface JobAbility {
  name: string;
  level: number;
  recast: number;
  type: string;
  category: string;
}
