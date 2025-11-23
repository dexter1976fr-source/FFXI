import React, { useState, useEffect } from "react";
import { Settings, RotateCcw, Save, Music, Sparkles, RefreshCw } from 'lucide-react';
import { backendService } from "../services/backendService";

interface AutoCastConfigPanelProps {
  onBack: () => void;
}

const AutoCastConfigPanel: React.FC<AutoCastConfigPanelProps> = ({ onBack }) => {
  const [activeTab, setActiveTab] = useState<"BRD" | "WHM" | "SCH" | "RDM">("BRD");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [partyMembers, setPartyMembers] = useState<string[]>([]);

  // Configuration BRD par défaut
  const [healerTarget, setHealerTarget] = useState<string>("[Heal]");
  const [meleeTarget, setMeleeTarget] = useState<string>("[Melee]");
  
  const [mageSong1, setMageSong1] = useState<string>("Mage's Ballad II");
  const [mageSong2, setMageSong2] = useState<string>("Mage's Ballad III");
  
  const [meleeSong1, setMeleeSong1] = useState<string>("Valor Minuet V");
  const [meleeSong2, setMeleeSong2] = useState<string>("Sword Madrigal");

  // Charger la config et les membres de party au démarrage
  useEffect(() => {
    loadConfigAndParty();
  }, []);

  const loadConfigAndParty = async () => {
    setLoading(true);
    try {
      // Charger la config AutoCast
      const config = await backendService.fetchAutoCastConfig();
      if (config && config.BRD) {
        setHealerTarget(config.BRD.healerTarget || "[Heal]");
        setMeleeTarget(config.BRD.meleeTarget || "[Melee]");
        setMageSong1(config.BRD.mageSongs?.[0] || "Mage's Ballad II");
        setMageSong2(config.BRD.mageSongs?.[1] || "Mage's Ballad III");
        setMeleeSong1(config.BRD.meleeSongs?.[0] || "Valor Minuet V");
        setMeleeSong2(config.BRD.meleeSongs?.[1] || "Sword Madrigal");
      }

      // Charger les membres de party
      const members = await backendService.fetchPartyMembers();
      setPartyMembers(members);
    } catch (error) {
      console.error("Error loading config:", error);
    } finally {
      setLoading(false);
    }
  };

  // Liste des songs BRD (à compléter plus tard avec les vraies données)
  const brdSongs = [
    "Mage's Ballad",
    "Mage's Ballad II",
    "Mage's Ballad III",
    "Army's Paeon",
    "Army's Paeon II",
    "Army's Paeon III",
    "Army's Paeon IV",
    "Army's Paeon V",
    "Valor Minuet",
    "Valor Minuet II",
    "Valor Minuet III",
    "Valor Minuet IV",
    "Valor Minuet V",
    "Sword Madrigal",
    "Blade Madrigal",
    "Victory March",
    "Advancing March",
    "Sheepfoe Mambo",
    "Dragonfoe Mambo",
    "Fowl Aubade",
    "Herb Pastoral",
    "Chocobo Mazurka",
  ];

  // Liste des targets (options génériques + membres de party)
  const targetOptions = ["[Heal]", "[Melee]", ...partyMembers];

  const handleReset = () => {
    setHealerTarget("[Heal]");
    setMeleeTarget("[Melee]");
    setMageSong1("Mage's Ballad II");
    setMageSong2("Mage's Ballad III");
    setMeleeSong1("Valor Minuet V");
    setMeleeSong2("Sword Madrigal");
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const config = {
        BRD: {
          healerTarget,
          meleeTarget,
          mageSongs: [mageSong1, mageSong2],
          meleeSongs: [meleeSong1, meleeSong2],
        }
      };

      const result = await backendService.saveAutoCastConfig(config);
      
      if (result.success) {
        alert("✅ Configuration BRD sauvegardée avec succès !");
      } else {
        alert(`❌ Erreur: ${result.message}`);
      }
    } catch (error) {
      console.error("Error saving config:", error);
      alert("❌ Erreur lors de la sauvegarde");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 overflow-auto">
      {/* Header */}
      <div className="bg-slate-900/80 border-b border-slate-700 p-4 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Settings className="w-8 h-8 text-cyan-400" />
            <h1 className="text-2xl font-bold text-white">AutoCast Configuration</h1>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={loadConfigAndParty}
              disabled={loading}
              className="flex items-center gap-2 bg-slate-700 hover:bg-slate-600 disabled:bg-slate-800 text-white font-bold px-4 py-2 rounded-lg transition-colors"
            >
              <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </button>
            <button
              onClick={onBack}
              className="bg-red-600 hover:bg-red-700 text-white font-bold px-6 py-2 rounded-lg transition-colors"
            >
              Retour
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto p-6">
        {/* Tabs */}
        <div className="flex gap-2 mb-6">
          {(["BRD", "WHM", "SCH", "RDM"] as const).map((job) => (
            <button
              key={job}
              onClick={() => setActiveTab(job)}
              className={`flex-1 py-3 px-6 rounded-lg font-bold text-lg transition-all ${
                activeTab === job
                  ? "bg-gradient-to-r from-cyan-500 to-blue-600 text-white shadow-lg shadow-cyan-500/30"
                  : "bg-slate-800 text-gray-400 hover:bg-slate-700"
              }`}
            >
              {job}
            </button>
          ))}
        </div>

        {/* Loading State */}
        {loading && (
          <div className="bg-slate-900/80 rounded-lg border border-slate-700 p-12 text-center">
            <RefreshCw className="w-12 h-12 animate-spin text-cyan-400 mx-auto mb-4" />
            <p className="text-gray-400 text-lg">Chargement de la configuration...</p>
          </div>
        )}

        {/* BRD Configuration */}
        {!loading && activeTab === "BRD" && (
          <div className="bg-slate-900/80 rounded-lg border border-slate-700 p-6">
            <div className="flex items-center gap-3 mb-6">
              <Music className="w-6 h-6 text-cyan-400" />
              <h2 className="text-xl font-bold text-white">Bard Configuration</h2>
              {partyMembers.length > 0 && (
                <span className="ml-auto text-sm text-green-400">
                  ✓ {partyMembers.length} membre(s) de party détecté(s)
                </span>
              )}
            </div>

            {/* Healer Target */}
            <div className="mb-6">
              <label className="block text-cyan-400 font-semibold mb-2">
                🎵 Healer Target (Mage Songs)
              </label>
              <select
                value={healerTarget}
                onChange={(e) => setHealerTarget(e.target.value)}
                className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-3 focus:outline-none focus:border-cyan-500 text-lg"
              >
                {targetOptions.map((target) => (
                  <option key={target} value={target}>
                    {target}
                  </option>
                ))}
              </select>
              <p className="text-gray-400 text-sm mt-2">
                💡 [Heal] = détection automatique du healer dans la party
              </p>
            </div>

            {/* Melee Target */}
            <div className="mb-6">
              <label className="block text-orange-400 font-semibold mb-2">
                ⚔️ Melee Target (Melee Songs)
              </label>
              <select
                value={meleeTarget}
                onChange={(e) => setMeleeTarget(e.target.value)}
                className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-3 focus:outline-none focus:border-orange-500 text-lg"
              >
                {targetOptions.map((target) => (
                  <option key={target} value={target}>
                    {target}
                  </option>
                ))}
              </select>
              <p className="text-gray-400 text-sm mt-2">
                💡 [Melee] = détection automatique d'un melee dans la party
              </p>
            </div>

            {/* Divider */}
            <div className="border-t border-slate-700 my-6"></div>

            {/* Mage Songs */}
            <div className="mb-6">
              <label className="block text-purple-400 font-semibold mb-3 flex items-center gap-2">
                <Sparkles className="w-5 h-5" />
                Mage Songs (2)
              </label>
              
              <div className="space-y-3">
                <div>
                  <label className="block text-gray-400 text-sm mb-1">Song 1</label>
                  <select
                    value={mageSong1}
                    onChange={(e) => setMageSong1(e.target.value)}
                    className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-2 focus:outline-none focus:border-purple-500"
                  >
                    {brdSongs.map((song) => (
                      <option key={song} value={song}>
                        {song}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-gray-400 text-sm mb-1">Song 2</label>
                  <select
                    value={mageSong2}
                    onChange={(e) => setMageSong2(e.target.value)}
                    className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-2 focus:outline-none focus:border-purple-500"
                  >
                    {brdSongs.map((song) => (
                      <option key={song} value={song}>
                        {song}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Melee Songs */}
            <div className="mb-6">
              <label className="block text-red-400 font-semibold mb-3 flex items-center gap-2">
                <Sparkles className="w-5 h-5" />
                Melee Songs (2)
              </label>
              
              <div className="space-y-3">
                <div>
                  <label className="block text-gray-400 text-sm mb-1">Song 1</label>
                  <select
                    value={meleeSong1}
                    onChange={(e) => setMeleeSong1(e.target.value)}
                    className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-2 focus:outline-none focus:border-red-500"
                  >
                    {brdSongs.map((song) => (
                      <option key={song} value={song}>
                        {song}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-gray-400 text-sm mb-1">Song 2</label>
                  <select
                    value={meleeSong2}
                    onChange={(e) => setMeleeSong2(e.target.value)}
                    className="w-full bg-slate-800 text-white border border-slate-600 rounded-lg px-4 py-2 focus:outline-none focus:border-red-500"
                  >
                    {brdSongs.map((song) => (
                      <option key={song} value={song}>
                        {song}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>

            {/* Buttons */}
            <div className="flex gap-4 mt-8">
              <button
                onClick={handleSave}
                disabled={saving}
                className="flex-1 flex items-center justify-center gap-2 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 disabled:from-gray-600 disabled:to-gray-700 disabled:cursor-not-allowed text-white font-bold py-3 rounded-lg transition-all shadow-lg shadow-green-500/30"
              >
                {saving ? (
                  <>
                    <RefreshCw className="w-5 h-5 animate-spin" />
                    Sauvegarde...
                  </>
                ) : (
                  <>
                    <Save className="w-5 h-5" />
                    Sauvegarder
                  </>
                )}
              </button>

              <button
                onClick={handleReset}
                disabled={saving}
                className="flex items-center justify-center gap-2 bg-slate-700 hover:bg-slate-600 disabled:bg-slate-800 disabled:cursor-not-allowed text-white font-bold py-3 px-6 rounded-lg transition-all"
              >
                <RotateCcw className="w-5 h-5" />
                Reset
              </button>
            </div>
          </div>
        )}

        {/* Autres jobs (placeholder) */}
        {!loading && activeTab !== "BRD" && (
          <div className="bg-slate-900/80 rounded-lg border border-slate-700 p-12 text-center">
            <p className="text-gray-400 text-xl">
              Configuration pour <span className="text-cyan-400 font-bold">{activeTab}</span> à venir...
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default AutoCastConfigPanel;
