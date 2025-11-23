import { AltConfig, AltConfigStorage, ServerAltData } from "../types/admin";

const STORAGE_KEY = "ffxi_alt_configs";

// Récupérer les données des ALTs depuis le serveur Python
export const fetchAltDataFromServer = async (): Promise<ServerAltData[]> => {
  try {
    // TODO: Remplacer par l'URL réelle de votre serveur Python
    const response = await fetch("http://localhost:5000/api/alts");
    if (!response.ok) throw new Error("Failed to fetch ALT data");
    return await response.json();
  } catch (error) {
    console.error("Error fetching ALT data from server:", error);
    // Données d'exemple pour le développement
    return [
      {
        name: "Altair",
        job: "WAR",
        subJob: "NIN",
        availableSpells: ["Utsusemi: Ichi", "Utsusemi: Ni", "Monomi: Ichi"],
        availableWeaponSkills: ["Raging Rush", "Steel Cyclone", "King's Justice", "Metatron Torment"],
        jobAbilities: ["Berserk", "Warcry", "Aggressor", "Defender", "Retaliation"],
        petCommands: []
      },
      {
        name: "Vega",
        job: "WHM",
        subJob: "BLM",
        availableSpells: ["Cure", "Cure II", "Cure III", "Cure IV", "Protect", "Shell", "Haste", "Regen"],
        availableWeaponSkills: ["Hexa Strike", "Black Halo", "Realmrazer"],
        jobAbilities: ["Divine Seal", "Afflatus Solace", "Benediction"],
        petCommands: []
      }
    ];
  }
};

// Générer la clé unique pour un ALT
const getConfigKey = (name: string, job: string, subJob: string): string => {
  return `${name}_${job}_${subJob}`;
};

// Charger toutes les configurations sauvegardées
export const loadAllConfigs = (): AltConfigStorage => {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : {};
  } catch (error) {
    console.error("Error loading configs:", error);
    return {};
  }
};

// Charger la configuration d'un ALT spécifique
export const loadAltConfig = (name: string, job: string, subJob: string): AltConfig | null => {
  const configs = loadAllConfigs();
  const key = getConfigKey(name, job, subJob);
  return configs[key] || null;
};

// Sauvegarder la configuration d'un ALT
export const saveAltConfig = (config: AltConfig): void => {
  try {
    const configs = loadAllConfigs();
    const key = getConfigKey(config.name, config.job, config.subJob);
    configs[key] = config;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(configs));
    console.log(`Configuration saved for ${key}:`, config);
    
    // Émettre un événement pour notifier les composants du changement
    window.dispatchEvent(new CustomEvent("altConfigChanged", { detail: config }));
  } catch (error) {
    console.error("Error saving config:", error);
  }
};

// Obtenir la configuration avec valeurs par défaut si non existante
export const getOrCreateConfig = (name: string, job: string, subJob: string): AltConfig => {
  const existing = loadAltConfig(name, job, subJob);
  if (existing) return existing;
  
  return {
    name,
    job,
    subJob,
    selectedSpells: [],
    selectedWeaponSkills: []
  };
};
