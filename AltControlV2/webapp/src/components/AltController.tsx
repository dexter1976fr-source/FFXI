import React, { useState, useEffect } from "react";
import { Target, Swords, Wand2, Zap, RefreshCw, Wifi, WifiOff } from 'lucide-react';
import CommandButton from "./CommandButton";
import { backendService, PythonAltAbilities } from "../services/backendService";

interface AltControllerProps {
  altId: number;
  altName: string;
}

const AltController: React.FC<AltControllerProps> = ({ altId, altName }) => {
  const [altData, setAltData] = useState<PythonAltAbilities | null>(null);
  const [loading, setLoading] = useState(true);
  const [connectionStatus, setConnectionStatus] = useState<"connected" | "disconnected" | "reconnecting">("connected");
  
  // États UI
  const [showSpells, setShowSpells] = useState(false);
  const [showAbilities, setShowAbilities] = useState(false);

  // Charger les données de l'ALT au démarrage
  useEffect(() => {
    loadAltData();
    
    // S'abonner aux mises à jour via SocketIO
    const unsubscribe = backendService.subscribe('alt_update', (data: PythonAltAbilities) => {
      if (data.alt_name === altName) {
        console.log(`[AltController ${altName}] Received update:`, data);
        setAltData(data);
      }
    });

    return () => {
      unsubscribe();
    };
  }, [altName]);

  const loadAltData = async () => {
    setLoading(true);
    try {
      const data = await backendService.fetchAltAbilities(altName);
      if (data) {
        console.log(`[AltController ${altName}] Loaded data:`, data);
        setAltData(data);
        setConnectionStatus("connected");
      } else {
        console.error(`[AltController ${altName}] No data received`);
        setConnectionStatus("disconnected");
      }
    } catch (error) {
      console.error(`[AltController ${altName}] Error loading data:`, error);
      setConnectionStatus("disconnected");
    } finally {
      setLoading(false);
    }
  };

  const sendCommand = async (action: string) => {
    if (!altData) return;

    console.log(`[AltController ${altName}] Sending: ${action}`);
    const result = await backendService.sendCommand({
      altName: altData.alt_name,
      action: action,
    });

    if (!result.success) {
      console.error(`[AltController ${altName}] Command failed:`, result.message);
    }
  };

  if (loading) {
    return (
      <div className="h-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="w-12 h-12 animate-spin text-cyan-400 mx-auto mb-4" />
          <p className="text-gray-400">Chargement de {altName}...</p>
        </div>
      </div>
    );
  }

  if (!altData) {
    return (
      <div className="h-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center">
        <div className="text-center">
          <p className="text-red-400 text-xl mb-2">⚠️ Erreur</p>
          <p className="text-gray-400">Impossible de charger {altName}</p>
          <button
            onClick={loadAltData}
            className="mt-4 bg-cyan-600 hover:bg-cyan-700 text-white px-6 py-2 rounded-lg"
          >
            Réessayer
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-2 pb-0 flex flex-col">
      {/* Header compact */}
      <div className="bg-gradient-to-r from-slate-800 to-slate-700 rounded-lg p-2 mb-2 shadow-xl border border-slate-600">
        <div className="flex items-center justify-between gap-2">
          {/* Nom et job */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className={`text-base font-bold ${altId === 1 ? "text-cyan-400" : "text-orange-400"}`}>
                ALT {altId}
              </span>
              <h2 className="text-lg font-bold text-white truncate">{altData.alt_name}</h2>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <span className="text-gray-300">
                {altData.main_job} {altData.main_job_level} / {altData.sub_job} {altData.sub_job_level}
              </span>
            </div>
            
            {/* Pet info */}
            {altData.pet_name && (
              <div className="mt-1">
                <span className="text-purple-400 font-semibold text-xs">
                  🐾 {altData.pet_name}
                </span>
              </div>
            )}
          </div>
          
          {/* Status */}
          <div className="flex items-center gap-2">
            {connectionStatus === "connected" ? (
              <Wifi className="w-4 h-4 text-green-500" />
            ) : connectionStatus === "reconnecting" ? (
              <RefreshCw className="w-4 h-4 text-yellow-500 animate-spin" />
            ) : (
              <WifiOff className="w-4 h-4 text-red-500" />
            )}
          </div>
        </div>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto pb-20">
        {/* Main Commands Grid */}
        <div className="grid grid-cols-3 gap-2 mb-3">
          <CommandButton
            label="Assist"
            icon={<Target />}
            onClick={() => sendCommand("/assist <p1>")}
            variant="primary"
          />
          <CommandButton
            label="Attack"
            icon={<Swords />}
            onClick={async () => {
              await sendCommand("/assist <p1>");
              await new Promise(resolve => setTimeout(resolve, 1000));
              await sendCommand("/attack <bt>");
            }}
            variant="danger"
          />
          <CommandButton
            label="Magic"
            icon={<Wand2 />}
            onClick={() => setShowSpells(!showSpells)}
            variant="primary"
          />
          <CommandButton
            label="Abilities"
            icon={<Zap />}
            onClick={() => setShowAbilities(!showAbilities)}
            variant="warning"
          />
        </div>

        {/* Spell List */}
        {showSpells && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">Magic Spells</h3>
            <div className="grid grid-cols-3 gap-2 max-h-64 overflow-y-auto">
              {altData.spells.map((spell, idx) => (
                <button
                  key={idx}
                  onClick={() => sendCommand(`/ma "${spell.name}" <t>`)}
                  className="bg-blue-700 hover:bg-blue-600 text-white px-2 py-2 rounded transition-colors text-left text-sm"
                >
                  {spell.name}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Job Abilities List */}
        {showAbilities && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">Job Abilities</h3>
            <div className="grid grid-cols-3 gap-2 max-h-64 overflow-y-auto">
              {altData.job_abilities.map((ability, idx) => (
                <button
                  key={idx}
                  onClick={() => sendCommand(`/ja "${ability.name}" <me>`)}
                  className="bg-slate-700 hover:bg-slate-600 text-white px-2 py-2 rounded transition-colors text-left text-sm"
                >
                  {ability.name}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default AltController;
