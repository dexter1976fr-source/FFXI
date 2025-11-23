import { AltConfigPersist } from "../types/backend";
import { backendService } from "./backendService";

const STORAGE_KEY = "ffxi_alt_configs_v2";
// Utiliser l'URL actuelle du navigateur pour construire l'API URL
const API_URL = `${window.location.protocol}//${window.location.hostname}:${window.location.port || '5000'}`;

/**
 * Service de gestion des configurations ALT avec synchronisation serveur
 */
class ConfigService {
  private listeners: Set<(config: AltConfigPersist) => void> = new Set();
  private cache: Map<string, AltConfigPersist> = new Map();

  constructor() {
    // Charger le cache au démarrage
    this.loadCache();
    
    // S'abonner aux mises à jour de config depuis le serveur
    backendService.subscribe('config_updated', (config: AltConfigPersist) => {
      console.log('[ConfigService] Received config update from server:', config);
      const key = this.getConfigKey(config.alt_name, config.main_job, config.sub_job);
      this.cache.set(key, config);
      this.saveToStorage(); // Backup local
      this.notifyListeners(config);
    });
  }

  /**
   * Générer une clé unique pour un ALT
   */
  private getConfigKey(altName: string, mainJob: string, subJob: string): string {
    return `${altName}_${mainJob}_${subJob}`.toUpperCase();
  }

  /**
   * Charger toutes les configurations depuis le localStorage
   */
  private loadCache(): void {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const configs: Record<string, AltConfigPersist> = JSON.parse(stored);
        Object.entries(configs).forEach(([key, config]) => {
          this.cache.set(key, config);
        });
        console.log(`Loaded ${this.cache.size} configurations from storage`);
      }
    } catch (error) {
      console.error("Error loading config cache:", error);
    }
  }

  /**
   * Sauvegarder toutes les configurations dans le localStorage
   */
  private saveToStorage(): void {
    try {
      const configs: Record<string, AltConfigPersist> = {};
      this.cache.forEach((config, key) => {
        configs[key] = config;
      });
      localStorage.setItem(STORAGE_KEY, JSON.stringify(configs));
      console.log(`Saved ${this.cache.size} configurations to storage`);
    } catch (error) {
      console.error("Error saving config to storage:", error);
    }
  }

  /**
   * Obtenir la configuration d'un ALT (depuis le cache ou le serveur)
   */
  getConfig(altName: string, mainJob: string, subJob: string): AltConfigPersist | null {
    const key = this.getConfigKey(altName, mainJob, subJob);
    const config = this.cache.get(key);
    
    // Si pas en cache, charger depuis le serveur en arrière-plan
    if (!config) {
      this.loadConfigFromServer(altName, mainJob, subJob).then(serverConfig => {
        if (serverConfig) {
          console.log(`[ConfigService] Loaded config from server for ${key}`);
          this.notifyListeners(serverConfig);
        }
      });
    }
    
    console.log(`Getting config for ${key}:`, config);
    return config || null;
  }

  /**
   * Sauvegarder la configuration d'un ALT (sur le serveur)
   */
  async saveConfig(config: AltConfigPersist): Promise<void> {
    const key = this.getConfigKey(config.alt_name, config.main_job, config.sub_job);
    config.last_updated = Date.now();
    
    console.log(`[ConfigService] Saving config for ${key} to server:`, config);
    
    // Sauvegarder localement d'abord (backup)
    this.cache.set(key, config);
    this.saveToStorage();
    
    // Envoyer au serveur
    try {
      const response = await fetch(`${API_URL}/config`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      });
      
      if (!response.ok) {
        throw new Error(`Server returned ${response.status}`);
      }
      
      const result = await response.json();
      console.log('[ConfigService] Config saved to server:', result);
      
      // Notifier les listeners locaux
      this.notifyListeners(config);
    } catch (error) {
      console.error('[ConfigService] Error saving config to server:', error);
      // En cas d'erreur, on garde quand même la config locale
      this.notifyListeners(config);
    }
  }
  
  /**
   * Charger la configuration depuis le serveur
   */
  async loadConfigFromServer(altName: string, mainJob: string, subJob: string): Promise<AltConfigPersist | null> {
    try {
      const response = await fetch(`${API_URL}/config/${altName}/${mainJob}/${subJob}`);
      
      if (!response.ok) {
        return null;
      }
      
      const config = await response.json();
      
      if (config) {
        const key = this.getConfigKey(altName, mainJob, subJob);
        this.cache.set(key, config);
        this.saveToStorage(); // Backup local
        console.log(`[ConfigService] Loaded config from server for ${key}`);
      }
      
      return config;
    } catch (error) {
      console.error('[ConfigService] Error loading config from server:', error);
      return null;
    }
  }

  /**
   * S'abonner aux changements de configuration
   */
  subscribe(callback: (config: AltConfigPersist) => void): () => void {
    this.listeners.add(callback);
    console.log(`Listener subscribed. Total listeners: ${this.listeners.size}`);
    
    // Return unsubscribe function
    return () => {
      this.listeners.delete(callback);
      console.log(`Listener unsubscribed. Total listeners: ${this.listeners.size}`);
    };
  }

  /**
   * Notifier tous les listeners
   */
  private notifyListeners(config: AltConfigPersist): void {
    console.log(`Notifying ${this.listeners.size} listeners of config change`);
    this.listeners.forEach(callback => {
      try {
        callback(config);
      } catch (error) {
        console.error("Error in config listener:", error);
      }
    });
  }

  /**
   * Obtenir toutes les configurations
   */
  getAllConfigs(): AltConfigPersist[] {
    return Array.from(this.cache.values());
  }

  /**
   * Supprimer la configuration d'un ALT
   */
  deleteConfig(altName: string, mainJob: string, subJob: string): void {
    const key = this.getConfigKey(altName, mainJob, subJob);
    this.cache.delete(key);
    this.saveToStorage();
    sessionStorage.removeItem(`config_${key}`);
    console.log(`Deleted config for ${key}`);
  }

  /**
   * Vérifier si une configuration existe
   */
  hasConfig(altName: string, mainJob: string, subJob: string): boolean {
    const key = this.getConfigKey(altName, mainJob, subJob);
    return this.cache.has(key);
  }

  /**
   * Obtenir une configuration avec vérification de fraîcheur
   * Utile pour détecter les modifications récentes
   */
  getConfigWithFreshness(
    altName: string, 
    mainJob: string, 
    subJob: string
  ): { config: AltConfigPersist | null; isRecent: boolean } {
    const config = this.getConfig(altName, mainJob, subJob);
    if (!config) {
      return { config: null, isRecent: false };
    }
    
    // Consider config "recent" if updated within last 5 seconds
    const isRecent = Date.now() - config.last_updated < 5000;
    return { config, isRecent };
  }

  /**
   * Forcer le rechargement du cache depuis le storage
   */
  reload(): void {
    console.log("Reloading config cache from storage...");
    this.cache.clear();
    this.loadCache();
  }
}

// Export singleton instance
export const configService = new ConfigService();
