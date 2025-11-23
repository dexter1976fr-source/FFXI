import { Command } from "../types";

// URL du serveur Python local (à configurer)
const SERVER_URL = "http://localhost:5000/command";

export const sendCommand = async (altId: number, command: Command): Promise<void> => {
  try {
    const payload = {
      altId,
      timestamp: Date.now(),
      ...command,
    };

    console.log("📤 Sending command:", payload);

    // Pour le moment, juste un log. Plus tard, envoi réel au serveur Python
    // const response = await fetch(SERVER_URL, {
    //   method: "POST",
    //   headers: {
    //     "Content-Type": "application/json",
    //   },
    //   body: JSON.stringify(payload),
    // });

    // if (!response.ok) {
    //   throw new Error(`Server error: ${response.status}`);
    // }

    // Simulation d'envoi réussi
    await new Promise(resolve => setTimeout(resolve, 100));
    
  } catch (error) {
    console.error("❌ Error sending command:", error);
    throw error;
  }
};
