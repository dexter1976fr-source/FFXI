import { io, Socket } from 'socket.io-client';

// 🌐 Configuration dynamique du backend
// Détecte automatiquement l'URL du serveur (localhost ou IP réseau)
const getBackendUrl = (): string => {
  // Si on est en développement (localhost), utiliser localhost
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return 'http://localhost:5000';
  }
  
  // Sinon, utiliser l'IP/hostname actuel avec le port 5000
  return `http://${window.location.hostname}:5000`;
};

const BACKEND_CONFIG = {
  apiUrl: getBackendUrl(),
  socketUrl: getBackendUrl(),
};

// Log de la configuration au démarrage
console.log('[BackendService] Configuration:', {
  hostname: window.location.hostname,
  apiUrl: BACKEND_CONFIG.apiUrl,
  socketUrl: BACKEND_CONFIG.socketUrl,
});

// Interface pour les données ALT du serveur Python
export interface PythonAltData {
  name: string;
  ip: string;
  port: string;
  main_job: string;
  main_job_level: number;
  sub_job: string;
  sub_job_level: number;
  weapon_id: string;
  weapon_type: string;
  pet_name: string | null;
  pet_hp?: number;
  pet_hpp?: number;
  pet_tp?: number;
  is_engaged?: boolean;
  party: string[];
}

// Interface pour les abilities complètes d'un ALT
export interface PythonAltAbilities {
  alt_name: string;
  main_job: string;
  main_job_level: number;
  sub_job: string;
  sub_job_level: number;
  weapon_type: string;
  pet_name: string | null;
  pet_hp?: number;
  pet_hpp?: number;
  pet_tp?: number;
  bst_ready_charges?: number;
  is_engaged?: boolean;
  active_buffs?: string[];
  party: string[];
  spells: Array<{
    name: string;
    level: number;
    mp?: number;
    element?: string;
    type?: string;
    category?: string;
    targets?: string;
  }>;
  job_abilities: Array<{
    name: string;
    level: number;
    recast?: string;
    category?: string;
  }>;
  pet_commands: Array<{
    name: string;
    type?: string;
    category?: string;
    desc?: string;
  }>;
  pet_attacks: Record<string, Array<{
    name: string;
    category?: string;
    type?: string;
    level?: number;
    mp?: string | number;
  }>>;
  weapon_skills: string[];
  macros: Array<{
    name: string;
    command: string;
  }>;
  ability_recasts?: Record<string, number>;
  spell_recasts?: Record<string, number>;
}

// Interface pour l'envoi de commandes
export interface CommandPayload {
  altName: string;
  action: string;
}

/**
 * Service de communication avec le backend Python Flask + SocketIO
 */
class BackendService {
  private socket: Socket | null = null;
  private listeners: Map<string, Set<(data: any) => void>> = new Map();
  private connectionStatus: "connected" | "disconnected" | "reconnecting" = "disconnected";

  /**
   * Récupérer la liste de tous les ALTs connectés
   */
  async fetchAllAlts(): Promise<PythonAltData[]> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/all-alts`;
      console.log(`[BackendService] Fetching all ALTs from: ${url}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log("[BackendService] Received ALTs:", data);
      
      // Le serveur Python retourne {alts: [...]}
      return data.alts || [];
    } catch (error) {
      console.error("[BackendService] Error fetching ALTs:", error);
      return [];
    }
  }

  /**
   * Récupérer les capacités complètes d'un ALT spécifique
   */
  async fetchAltAbilities(altName: string): Promise<PythonAltAbilities | null> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/alt-abilities/${encodeURIComponent(altName)}`;
      console.log(`[BackendService] Fetching abilities for ${altName} from: ${url}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log(`[BackendService] Received abilities for ${altName}:`, data);
      return data;
    } catch (error) {
      console.error(`[BackendService] Error fetching abilities for ${altName}:`, error);
      return null;
    }
  }

  /**
   * Envoyer une commande à un ALT
   */
  async sendCommand(payload: CommandPayload): Promise<{ success: boolean; message?: string }> {
    try {
      console.log("[BackendService] Sending command:", payload);
      
      const response = await fetch(`${BACKEND_CONFIG.apiUrl}/command`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      console.log("[BackendService] Command result:", result);
      
      return { 
        success: result.success === true, 
        message: result.message || "Command sent" 
      };
    } catch (error) {
      console.error("[BackendService] Error sending command:", error);
      return { 
        success: false, 
        message: error instanceof Error ? error.message : "Unknown error" 
      };
    }
  }

  /**
   * Recharger les données (force les ALTs à se reconnecter)
   */
  async reloadData(): Promise<{ success: boolean; message?: string }> {
    try {
      console.log("[BackendService] Reloading JSON data...");
      
      const response = await fetch(`${BACKEND_CONFIG.apiUrl}/reload-data`, {
        method: "POST",
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      console.log("[BackendService] Reload result:", result);
      
      return { 
        success: result.success === true, 
        message: result.message || "Data reloaded" 
      };
    } catch (error) {
      console.error("[BackendService] Error reloading data:", error);
      return { 
        success: false, 
        message: error instanceof Error ? error.message : "Unknown error" 
      };
    }
  }

  /**
   * Initialiser la connexion SocketIO pour les mises à jour temps réel
   */
  initSocketIO(callbacks?: {
    onAltUpdate?: (data: PythonAltAbilities) => void;
    onConnection?: (status: string) => void;
  }): void {
    if (this.socket?.connected) {
      console.log("[BackendService] SocketIO already connected");
      return;
    }

    try {
      console.log(`[BackendService] Connecting to SocketIO: ${BACKEND_CONFIG.socketUrl}`);
      
      this.socket = io(BACKEND_CONFIG.socketUrl, {
        transports: ['websocket', 'polling'],
        reconnection: true,
        reconnectionDelay: 2000,
        reconnectionAttempts: 10,
      });

      this.socket.on('connect', () => {
        console.log("[BackendService] SocketIO connected");
        this.connectionStatus = "connected";
        this.notifyListeners("connection", { status: "connected" });
        
        if (callbacks?.onConnection) {
          callbacks.onConnection("connected");
        }
      });

      this.socket.on('disconnect', () => {
        console.log("[BackendService] SocketIO disconnected");
        this.connectionStatus = "disconnected";
        this.notifyListeners("connection", { status: "disconnected" });
        
        if (callbacks?.onConnection) {
          callbacks.onConnection("disconnected");
        }
      });

      this.socket.on('reconnecting', () => {
        console.log("[BackendService] SocketIO reconnecting...");
        this.connectionStatus = "reconnecting";
        this.notifyListeners("connection", { status: "reconnecting" });
        
        if (callbacks?.onConnection) {
          callbacks.onConnection("reconnecting");
        }
      });

      // Écouter les mises à jour des ALTs
      this.socket.on('alt_update', (data: PythonAltAbilities) => {
        console.log("[BackendService] ALT update received:", data);
        this.notifyListeners("alt_update", data);
        
        if (callbacks?.onAltUpdate) {
          callbacks.onAltUpdate(data);
        }
      });

      // Écouter la liste complète des ALTs
      this.socket.on('all_alts', (data: { alts: PythonAltData[] }) => {
        console.log("[BackendService] All ALTs update received:", data);
        this.notifyListeners("all_alts", data.alts);
      });

      // Écouter les données spécifiques d'un ALT
      this.socket.on('alt_data', (data: PythonAltAbilities) => {
        console.log("[BackendService] ALT data received:", data);
        this.notifyListeners("alt_data", data);
      });

    } catch (error) {
      console.error("[BackendService] Error initializing SocketIO:", error);
      this.connectionStatus = "disconnected";
    }
  }

  /**
   * Demander les données d'un ALT spécifique via SocketIO
   */
  requestAltData(altName: string): void {
    if (this.socket?.connected) {
      console.log(`[BackendService] Requesting data for ${altName}`);
      this.socket.emit('request_alt_data', { alt_name: altName });
    } else {
      console.warn("[BackendService] SocketIO not connected, cannot request ALT data");
    }
  }

  /**
   * S'abonner aux événements
   */
  subscribe(eventType: string, callback: (data: any) => void): () => void {
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, new Set());
    }
    this.listeners.get(eventType)!.add(callback);

    // Return unsubscribe function
    return () => {
      const callbacks = this.listeners.get(eventType);
      if (callbacks) {
        callbacks.delete(callback);
      }
    };
  }

  /**
   * Notifier les listeners
   */
  private notifyListeners(eventType: string, data: any): void {
    const callbacks = this.listeners.get(eventType);
    if (callbacks) {
      callbacks.forEach(callback => {
        try {
          callback(data);
        } catch (error) {
          console.error(`[BackendService] Error in listener for ${eventType}:`, error);
        }
      });
    }
  }

  /**
   * Fermer la connexion SocketIO
   */
  closeSocketIO(): void {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
    this.connectionStatus = "disconnected";
  }

  /**
   * Obtenir le statut de connexion
   */
  getConnectionStatus(): "connected" | "disconnected" | "reconnecting" {
    return this.connectionStatus;
  }

  /**
   * Récupérer la configuration AutoCast
   */
  async fetchAutoCastConfig(): Promise<any> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/autocast/config`;
      console.log(`[BackendService] Fetching AutoCast config from: ${url}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log("[BackendService] Received AutoCast config:", data);
      return data;
    } catch (error) {
      console.error("[BackendService] Error fetching AutoCast config:", error);
      return null;
    }
  }

  /**
   * Contrôler le SCH AutoCast
   */
  async controlSchAutocast(action: 'start' | 'stop'): Promise<{ success: boolean; message?: string }> {
    try {
      console.log(`[BackendService] SCH AutoCast ${action}`);
      
      const response = await fetch(`${BACKEND_CONFIG.apiUrl}/sch/autocast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action }),
      });
      
      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.error || `HTTP ${response.status}`);
      }
      
      return result;
    } catch (error) {
      console.error('[BackendService] Error controlling SCH AutoCast:', error);
      throw error;
    }
  }

  /**
   * Contrôler le SCH AutoCast
   */
  async controlSchAutocast(action: 'start' | 'stop'): Promise<{ success: boolean; message?: string }> {
    try {
      console.log(`[BackendService] SCH AutoCast ${action}`);
      
      const response = await fetch(`${BACKEND_CONFIG.apiUrl}/sch/autocast`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ action }),
      });
      
      const result = await response.json();
      
      if (!response.ok) {
        throw new Error(result.error || `HTTP ${response.status}`);
      }
      
      return result;
    } catch (error) {
      console.error('[BackendService] Error controlling SCH AutoCast:', error);
      throw error;
    }
  }

  /**
   * Sauvegarder la configuration AutoCast
   */
  async saveAutoCastConfig(config: any): Promise<{ success: boolean; message?: string }> {
    try {
      console.log("[BackendService] Saving AutoCast config:", config);
      
      const response = await fetch(`${BACKEND_CONFIG.apiUrl}/autocast/config`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(config),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      console.log("[BackendService] Save result:", result);
      
      return { 
        success: result.success === true, 
        message: result.message || "Config saved" 
      };
    } catch (error) {
      console.error("[BackendService] Error saving AutoCast config:", error);
      return { 
        success: false, 
        message: error instanceof Error ? error.message : "Unknown error" 
      };
    }
  }

  /**
   * Récupérer la liste des membres de party
   */
  async fetchPartyMembers(): Promise<string[]> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/party/members`;
      console.log(`[BackendService] Fetching party members from: ${url}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log("[BackendService] Received party members:", data);
      return data.members || [];
    } catch (error) {
      console.error("[BackendService] Error fetching party members:", error);
      return [];
    }
  }

  /**
   * Fetch party roles (main character, etc.)
   */
  async fetchPartyRoles(): Promise<{ main_character: string }> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/party/roles`;
      console.log(`[BackendService] Fetching party roles from: ${url}`);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log("[BackendService] Received party roles:", data);
      return data;
    } catch (error) {
      console.error("[BackendService] Error fetching party roles:", error);
      return { main_character: "" };
    }
  }

  /**
   * Save party roles (main character, alt1, alt2)
   */
  async savePartyRoles(roles: { main_character: string; alt1?: string; alt2?: string }): Promise<boolean> {
    try {
      const url = `${BACKEND_CONFIG.apiUrl}/party/roles`;
      console.log(`[BackendService] Saving party roles to: ${url}`, roles);
      
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(roles),
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data = await response.json();
      console.log("[BackendService] Party roles saved:", data);
      return data.success || false;
    } catch (error) {
      console.error("[BackendService] Error saving party roles:", error);
      return false;
    }
  }
}

// Export singleton instance
export const backendService = new BackendService();