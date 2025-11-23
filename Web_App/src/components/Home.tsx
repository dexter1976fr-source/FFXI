import React, { useState, useEffect } from "react";
import { Gamepad2, Settings, RefreshCw, Wand2 } from 'lucide-react';
import { backendService, PythonAltData } from "../services/backendService";

interface HomeProps {
  onLaunch: (selectedAlts: string[]) => void;
  onAdmin: () => void;
  onAutoCast: () => void;
}

const Home: React.FC<HomeProps> = ({ onLaunch, onAdmin, onAutoCast }) => {
  const [availableAlts, setAvailableAlts] = useState<PythonAltData[]>([]);
  const [mainCharacter, setMainCharacter] = useState<string>("");
  const [selectedAlt1, setSelectedAlt1] = useState<string>("");
  const [selectedAlt2, setSelectedAlt2] = useState<string>("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAvailableAlts();
    loadPartyRoles();
    
    // S'abonner aux mises à jour des ALTs
    const unsubscribe = backendService.subscribe('all_alts', (alts: PythonAltData[]) => {
      console.log("[Home] Received ALTs update:", alts);
      setAvailableAlts(alts);
    });

    return () => unsubscribe();
  }, []);

  const loadAvailableAlts = async () => {
    setLoading(true);
    try {
      const alts = await backendService.fetchAllAlts();
      console.log("[Home] Loaded ALTs:", alts);
      setAvailableAlts(alts);
      
      // Auto-sélectionner les 2 premiers si disponibles
      if (alts.length > 0) {
        setSelectedAlt1(alts[0].name);
        if (alts.length > 1) {
          setSelectedAlt2(alts[1].name);
        }
      }
    } catch (error) {
      console.error("[Home] Error loading ALTs:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadPartyRoles = async () => {
    try {
      const roles = await backendService.fetchPartyRoles();
      console.log("[Home] Loaded party roles:", roles);
      if (roles.main_character) {
        setMainCharacter(roles.main_character);
      }
    } catch (error) {
      console.error("[Home] Error loading party roles:", error);
    }
  };

  const handleMainCharacterChange = async (newMain: string) => {
    setMainCharacter(newMain);
    try {
      await backendService.savePartyRoles({ main_character: newMain });
      console.log("[Home] Main character saved:", newMain);
    } catch (error) {
      console.error("[Home] Error saving main character:", error);
    }
  };

  const handleLaunch = () => {
    const selectedAlts = [selectedAlt1, selectedAlt2].filter(Boolean);
    
    if (selectedAlts.length === 0) {
      alert("Veuillez sélectionner au moins un ALT");
      return;
    }
    
    console.log("[Home] Launching with ALTs:", selectedAlts);
    onLaunch(selectedAlts);
  };

  return (
    <div className="h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center p-4">
      <div className="text-center max-w-2xl w-full">
        {/* Logo/Icon */}
        <div className="mb-8 flex justify-center">
          <div className="bg-gradient-to-br from-cyan-500 to-blue-600 p-6 rounded-full shadow-2xl shadow-cyan-500/50 animate-pulse">
            <Gamepad2 className="w-20 h-20 text-white" />
          </div>
        </div>

        {/* Title */}
        <h1 className="text-6xl font-bold mb-3 bg-gradient-to-r from-cyan-400 via-blue-500 to-purple-600 bg-clip-text text-transparent">
          FFXI ALT CONTROL
        </h1>

        {/* Subtitle */}
        <p className="text-2xl text-gray-400 mb-8 font-light">
          By Dexter Brown
        </p>

        {/* 🆕 ALT Selection Section */}
        {loading ? (
          <div className="mb-8 p-6 bg-slate-900/50 rounded-lg border border-slate-700">
            <RefreshCw className="w-8 h-8 animate-spin text-cyan-400 mx-auto mb-3" />
            <p className="text-gray-400">Chargement des ALTs connectés...</p>
          </div>
        ) : availableAlts.length === 0 ? (
          <div className="mb-8 p-6 bg-red-900/20 rounded-lg border border-red-700/50">
            <p className="text-red-400 mb-3">⚠️ Aucun ALT connecté</p>
            <p className="text-gray-400 text-sm mb-4">
              Assurez-vous que le serveur Python est lancé et que vos personnages sont connectés au jeu.
            </p>
            <button
              onClick={loadAvailableAlts}
              className="bg-cyan-600 hover:bg-cyan-700 text-white px-6 py-2 rounded-lg"
            >
              Réessayer
            </button>
          </div>
        ) : (
          <div className="mb-8 p-6 bg-slate-900/80 rounded-lg border border-slate-700">
            <h2 className="text-xl font-bold text-white mb-4">
              Sélectionner les ALTs à contrôler
            </h2>
            
            {/* Main Character Selection */}
            <div className="mb-6 p-4 bg-gradient-to-r from-yellow-900/30 to-amber-900/30 rounded-lg border border-yellow-600/50">
              <label className="block text-yellow-400 font-bold mb-2 text-left flex items-center gap-2">
                <span className="text-2xl">👑</span>
                Main Character (Leader)
              </label>
              <select
                value={mainCharacter}
                onChange={(e) => handleMainCharacterChange(e.target.value)}
                className="w-full bg-slate-800 text-white border border-yellow-600 rounded-lg px-4 py-3 focus:outline-none focus:border-yellow-500 text-lg font-semibold"
              >
                <option value="">-- Sélectionner le Main --</option>
                {availableAlts.map((alt) => (
                  <option key={alt.name} value={alt.name}>
                    {alt.name} ({alt.main_job}/{alt.sub_job} Lv.{alt.main_job_level})
                  </option>
                ))}
              </select>
              <p className="text-yellow-300/70 text-sm mt-2 text-left">
                Le Main Character déclenche les cycles automatiques (BRD, etc.)
              </p>
            </div>
            
            {/* ALT 1 Selection */}
            <div className="mb-4">
              <label className="block text-cyan-400 font-semibold mb-2 text-left">
                ALT 1 (Gauche)
              </label>
              <select
                value={selectedAlt1}
                onChange={(e) => setSelectedAlt1(e.target.value)}
                className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-3 focus:outline-none focus:border-cyan-500 text-lg"
              >
                <option value="">-- Aucun --</option>
                {availableAlts.map((alt) => (
                  <option 
                    key={alt.name} 
                    value={alt.name}
                    disabled={alt.name === selectedAlt2}
                  >
                    {alt.name} ({alt.main_job}/{alt.sub_job} Lv.{alt.main_job_level})
                  </option>
                ))}
              </select>
            </div>

            {/* ALT 2 Selection */}
            <div className="mb-4">
              <label className="block text-orange-400 font-semibold mb-2 text-left">
                ALT 2 (Droite)
              </label>
              <select
                value={selectedAlt2}
                onChange={(e) => setSelectedAlt2(e.target.value)}
                className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-3 focus:outline-none focus:border-orange-500 text-lg"
              >
                <option value="">-- Aucun --</option>
                {availableAlts.map((alt) => (
                  <option 
                    key={alt.name} 
                    value={alt.name}
                    disabled={alt.name === selectedAlt1}
                  >
                    {alt.name} ({alt.main_job}/{alt.sub_job} Lv.{alt.main_job_level})
                  </option>
                ))}
              </select>
            </div>

            {/* Info sur les ALTs disponibles */}
            <div className="mt-4 p-3 bg-slate-800/50 rounded text-left text-sm">
              <p className="text-gray-400">
                <span className="text-green-400 font-semibold">{availableAlts.length}</span> ALT(s) connecté(s) :
              </p>
              <ul className="mt-2 space-y-1">
                {availableAlts.map((alt) => (
                  <li key={alt.name} className="text-gray-300">
                    • <span className="text-cyan-300">{alt.name}</span> - {alt.main_job} Lv.{alt.main_job_level}
                    {/* {alt.pet_name && <span className="text-purple-400"> (Pet: {alt.pet_name})</span>} */}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}

        {/* Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center">
          <button
            onClick={handleLaunch}
            disabled={!selectedAlt1 || loading}
            className="bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-600 hover:to-blue-700 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white font-bold text-xl px-12 py-4 rounded-lg shadow-xl shadow-cyan-500/30 transition-all duration-300 transform hover:scale-105 active:scale-95 disabled:transform-none disabled:opacity-50"
          >
            Launch Control
          </button>
          
          <button
            onClick={onAdmin}
            className="flex items-center gap-3 bg-gradient-to-r from-purple-500 to-pink-600 hover:from-purple-600 hover:to-pink-700 text-white font-bold text-xl px-12 py-4 rounded-lg shadow-xl shadow-purple-500/30 transition-all duration-300 transform hover:scale-105 active:scale-95"
          >
            <Settings className="w-6 h-6" />
            Admin ALTs
          </button>

          <button
            onClick={onAutoCast}
            className="flex items-center gap-3 bg-gradient-to-r from-orange-500 to-amber-600 hover:from-orange-600 hover:to-amber-700 text-white font-bold text-xl px-12 py-4 rounded-lg shadow-xl shadow-orange-500/30 transition-all duration-300 transform hover:scale-105 active:scale-95"
          >
            <Wand2 className="w-6 h-6" />
            AutoCast Config
          </button>
        </div>

        {/* Decorative line */}
        <div className="mt-12 flex items-center justify-center gap-4">
          <div className="h-px w-20 bg-gradient-to-r from-transparent to-cyan-500"></div>
          <div className="w-2 h-2 bg-cyan-500 rounded-full animate-pulse"></div>
          <div className="h-px w-20 bg-gradient-to-l from-transparent to-cyan-500"></div>
        </div>
      </div>
    </div>
  );
};

export default Home;