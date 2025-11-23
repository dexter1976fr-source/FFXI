import { PartyMember } from "../types";

/**
 * Récupère la liste des membres de la party depuis le serveur Python
 * @returns Promise<PartyMember[]>
 */
export async function fetchPartyMembers(): Promise<PartyMember[]> {
  try {
    // À configurer avec l'URL de votre serveur Python
    const response = await fetch("http://localhost:5000/api/party/members");
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    return data.members || [];
  } catch (error) {
    console.error("Erreur lors de la récupération des membres de party:", error);
    // Retourne une liste vide en cas d'erreur
    return [];
  }
}

/**
 * Met à jour la liste des membres de la party
 * Cette fonction peut être appelée périodiquement ou lors d'événements spécifiques
 */
export function setupPartySync(
  onUpdate: (members: PartyMember[]) => void,
  intervalMs: number = 5000
): () => void {
  // Première récupération immédiate
  fetchPartyMembers().then(onUpdate);

  // Récupération périodique
  const intervalId = setInterval(() => {
    fetchPartyMembers().then(onUpdate);
  }, intervalMs);

  // Fonction de nettoyage
  return () => clearInterval(intervalId);
}