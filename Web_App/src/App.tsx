import React, { useState, useEffect } from "react";
import Home from "./components/Home";
import AltController from "./components/AltController";
import AdminPage from "./components/AdminPage";
import AutoCastConfigPanel from "./components/AutoCastConfigPanel";
import { backendService, PythonAltData } from "./services/backendService";

function App() {
  const [currentPage, setCurrentPage] = useState<"home" | "control" | "admin" | "autocast">("home");
  const [selectedAltNames, setSelectedAltNames] = useState<string[]>([]);

  // 🆕 CORRECTION: Ne charger les ALTs QUE quand on va sur Control
  useEffect(() => {
    if (currentPage === "control") {
      console.log("[App] Entering control page with selected ALTs:", selectedAltNames);
      
      // Initialiser SocketIO pour les mises à jour live
      backendService.initSocketIO({
        onAltUpdate: (data) => {
          console.log("[App] ALT update received:", data.alt_name);
          // Les mises à jour sont gérées par AltController directement
        },
        onConnection: (status) => {
          console.log("[App] Connection status:", status);
        }
      });

      return () => {
        // Ne pas fermer SocketIO car on pourrait y revenir
      };
    }
  }, [currentPage]);

  // 🆕 CORRECTION: Navigation vers Control AVEC sélection
  const goToControl = (selectedNames: string[]) => {
    console.log("[App] goToControl called with:", selectedNames);
    
    if (selectedNames.length === 0) {
      console.error("[App] No ALTs selected!");
      return;
    }
    
    setSelectedAltNames(selectedNames);
    setCurrentPage("control");
  };

  // Navigation vers Admin
  const goToAdmin = () => {
    setCurrentPage("admin");
  };

  // Navigation vers AutoCast Config
  const goToAutoCast = () => {
    setCurrentPage("autocast");
  };

  // Retour à Home
  const goToHome = () => {
    console.log("[App] Returning to home");
    setCurrentPage("home");
    setSelectedAltNames([]); // Reset selection
    backendService.closeSocketIO();
  };

  // Page HOME
  if (currentPage === "home") {
    return (
      <Home
        onLaunch={goToControl}
        onAdmin={goToAdmin}
        onAutoCast={goToAutoCast}
      />
    );
  }

  // Page ADMIN
  if (currentPage === "admin") {
    return <AdminPage onBack={goToHome} />;
  }

  // Page AUTOCAST CONFIG
  if (currentPage === "autocast") {
    return <AutoCastConfigPanel onBack={goToHome} />;
  }

  // Page CONTROL
  console.log("[App] Rendering control page with ALTs:", selectedAltNames);

  if (selectedAltNames.length === 0) {
    return (
      <div className="h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-400 text-xl mb-4">⚠️ Aucun ALT sélectionné</p>
          <button
            onClick={goToHome}
            className="bg-cyan-600 hover:bg-cyan-700 text-white px-8 py-3 rounded-lg"
          >
            Retour à l'accueil
          </button>
        </div>
      </div>
    );
  }

  // 🆕 CORRECTION: Un seul ALT sélectionné
  if (selectedAltNames.length === 1) {
    return (
      <div className="h-screen">
        <AltController
          altId={1}
          altName={selectedAltNames[0]}
        />
        <button
          onClick={goToHome}
          className="fixed top-4 right-4 bg-red-600 hover:bg-red-700 text-white font-bold px-4 py-2 rounded-lg z-50 shadow-xl"
        >
          Quitter
        </button>
      </div>
    );
  }

  // 🆕 CORRECTION: Deux ALTs sélectionnés - Vue splitée
  return (
    <div className="h-screen flex flex-col">
      {/* Header avec bouton retour */}
      <div className="bg-slate-900 border-b border-slate-700 p-2 flex justify-between items-center">
        <div className="flex gap-6 text-sm">
          <span className="text-cyan-400 font-bold">
            Gauche: {selectedAltNames[0]}
          </span>
          <span className="text-orange-400 font-bold">
            Droite: {selectedAltNames[1]}
          </span>
        </div>
        <button
          onClick={goToHome}
          className="bg-red-600 hover:bg-red-700 text-white font-bold px-4 py-1 rounded text-sm"
        >
          Quitter
        </button>
      </div>

      {/* Vue splitée - 2 ALTs côte à côte */}
      <div className="flex-1 flex flex-col md:flex-row overflow-hidden">
        {/* ALT 1 - GAUCHE */}
        <div className="flex-1 border-b md:border-b-0 md:border-r border-slate-700 overflow-hidden">
          <AltController
            altId={1}
            altName={selectedAltNames[0]}
          />
        </div>
        
        {/* ALT 2 - DROITE */}
        <div className="flex-1 overflow-hidden">
          <AltController
            altId={2}
            altName={selectedAltNames[1]}
          />
        </div>
      </div>
    </div>
  );
}

export default App;