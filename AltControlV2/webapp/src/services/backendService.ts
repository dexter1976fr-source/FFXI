import { io, Socket } from 'socket.io-client';

// Configuration dynamique du backend
const getBackendUrl = (): string => {
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return 'http://localhost:5000';
  }
  return `http://${window.location.hostname}:5000`;
};

const BACKEND_CONFIG = {
  apiUrl: getBackendUrl(),
  socketUrl: getBackendUrl(),
};

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
}

// Export singleton instance
export const backendService = new BackendService();
