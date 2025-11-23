import React, { useState, useEffect } from "react";
import { Check, Save, RefreshCw } from 'lucide-react';
import { AltConfigPersist } from "../types/backend";
import { backendService, PythonAltData, PythonAltAbilities } from "../services/backendService";
import { configService } from "../services/configService";
import SelectableButton from "./SelectableButton";

interface AltAdminPanelProps {
  altNumber: 1 | 2;
}

const AltAdminPanel: React.FC<AltAdminPanelProps> = ({ altNumber }) => {
  const [availableAlts, setAvailableAlts] = useState<PythonAltData[]>([]);
  const [selectedAlt, setSelectedAlt] = useState<PythonAltData | null>(null);
  const [altAbilities, setAltAbilities] = useState<PythonAltAbilities | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingAbilities, setLoadingAbilities] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);

  // Configuration sélectionnée
  const [selectedSpells, setSelectedSpells] = useState<Set<string>>(new Set());
  const [selectedJobAbilities, setSelectedJobAbilities] = useState<Set<string>>(new Set());
  const [selectedWeaponSkills, setSelectedWeaponSkills] = useState<Set<string>>(new Set());
  const [selectedMacros, setSelectedMacros] = useState<Set<string>>(new Set());

  // Charger les ALTs disponibles depuis le backend
  useEffect(() => {
    loadAltData();
  }, []);

  // Charger les abilities quand un ALT est sélectionné
  useEffect(() => {
    if (selectedAlt) {
      loadAltAbilities();
    }
  }, [selectedAlt]);

  // Charger la configuration existante quand les abilities sont chargées
  useEffect(() => {
    if (altAbilities) {
      loadExistingConfig();
    }
  }, [altAbilities]);

  const loadAltData = async () => {
    setLoading(true);
    try {
      const alts = await backendService.fetchAllAlts();
      console.log(`[AdminPanel] Loaded ${alts.length} ALTs:`, alts);
      setAvailableAlts(alts);
      
      // Auto-sélectionner le premier ALT si disponible
      if (alts.length > 0 && !selectedAlt) {
        setSelectedAlt(alts[0]);
      }
    } catch (error) {
      console.error("[AdminPanel] Error loading ALT data:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadAltAbilities = async () => {
    if (!selectedAlt) return;

    setLoadingAbilities(true);
    try {
      const abilities = await backendService.fetchAltAbilities(selectedAlt.name);
      console.log(`[AdminPanel] Loaded abilities for ${selectedAlt.name}:`, abilities);
      setAltAbilities(abilities);
    } catch (error) {
      console.error(`[AdminPanel] Error loading abilities for ${selectedAlt.name}:`, error);
    } finally {
      setLoadingAbilities(false);
    }
  };

  const loadExistingConfig = () => {
    if (!altAbilities) return;

    const config = configService.getConfig(
      altAbilities.alt_name,
      altAbilities.main_job,
      altAbilities.sub_job
    );

    console.log(`[AdminPanel] Loading config for ${altAbilities.alt_name}:`, config);

    if (config) {
      setSelectedSpells(new Set(config.selected_spells));
      setSelectedJobAbilities(new Set(config.selected_job_abilities || []));
      setSelectedWeaponSkills(new Set(config.selected_weapon_skills));
      setSelectedMacros(new Set(config.selected_macros));
    } else {
      // Aucune config existante, réinitialiser
      setSelectedSpells(new Set());
      setSelectedJobAbilities(new Set());
      setSelectedWeaponSkills(new Set());
      setSelectedMacros(new Set());
    }
  };

  const toggleSpell = (spellName: string) => {
    const newSet = new Set(selectedSpells);
    if (newSet.has(spellName)) {
      newSet.delete(spellName);
    } else {
      newSet.add(spellName);
    }
    setSelectedSpells(newSet);
  };

  const toggleWeaponSkill = (wsName: string) => {
    const newSet = new Set(selectedWeaponSkills);
    if (newSet.has(wsName)) {
      newSet.delete(wsName);
    } else {
      newSet.add(wsName);
    }
    setSelectedWeaponSkills(newSet);
  };

  const toggleJobAbility = (abilityName: string) => {
    const newSet = new Set(selectedJobAbilities);
    if (newSet.has(abilityName)) {
      newSet.delete(abilityName);
    } else {
      newSet.add(abilityName);
    }
    setSelectedJobAbilities(newSet);
  };

  const toggleMacro = (macroName: string) => {
    const newSet = new Set(selectedMacros);
    if (newSet.has(macroName)) {
      newSet.delete(macroName);
    } else {
      newSet.add(macroName);
    }
    setSelectedMacros(newSet);
  };

  const saveConfiguration = async () => {
    if (!altAbilities) return;

    setSaving(true);
    console.log(`[AdminPanel] Saving configuration for ${altAbilities.alt_name}...`);

    const config: AltConfigPersist = {
      alt_name: altAbilities.alt_name,
      main_job: altAbilities.main_job,
      sub_job: altAbilities.sub_job,
      selected_spells: Array.from(selectedSpells),
      selected_job_abilities: Array.from(selectedJobAbilities),
      selected_weapon_skills: Array.from(selectedWeaponSkills),
      selected_macros: Array.from(selectedMacros),
      last_updated: Date.now(),
    };

    console.log("[AdminPanel] Saving config:", config);
    
    try {
      await configService.saveConfig(config);
      
      // Afficher le message de succès
      setSaveSuccess(true);
      
      // Recharger la page après 1 seconde pour forcer la synchro
      setTimeout(() => {
        window.location.reload();
      }, 1000);
    } catch (error) {
      console.error("[AdminPanel] Error saving config:", error);
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-slate-900/50">
        <div className="text-center">
          <RefreshCw className="w-8 h-8 animate-spin text-cyan-400 mx-auto mb-3" />
          <p className="text-gray-400">Chargement des ALTs...</p>
        </div>
      </div>
    );
  }

  if (availableAlts.length === 0) {
    return (
      <div className="h-full flex items-center justify-center bg-slate-900/50">
        <div className="text-center p-6">
          <p className="text-red-400 text-xl mb-2">⚠️</p>
          <p className="text-gray-400 mb-4">Aucun ALT connecté</p>
          <button
            onClick={loadAltData}
            className="bg-cyan-600 hover:bg-cyan-700 text-white px-6 py-2 rounded-lg"
          >
            Réessayer
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-gradient-to-br from-slate-900 to-slate-800">
      {/* Header avec sélection ALT */}
      <div className="bg-slate-800/80 border-b border-slate-700 p-4">
        <div className="mb-3">
          <h2 className={`text-xl font-bold ${altNumber === 1 ? "text-cyan-400" : "text-orange-400"}`}>
            Configuration ALT {altNumber}
          </h2>
        </div>
        
        <select
          value={selectedAlt?.name || ""}
          onChange={(e) => {
            const alt = availableAlts.find(a => a.name === e.target.value);
            setSelectedAlt(alt || null);
            setAltAbilities(null); // Reset abilities
          }}
          className="w-full bg-slate-700 text-white border border-slate-600 rounded-lg px-4 py-2 focus:outline-none focus:border-cyan-500"
        >
          <option value="">-- Sélectionner un ALT --</option>
          {availableAlts.map((alt) => (
            <option key={alt.name} value={alt.name}>
              {alt.name} ({alt.main_job}/{alt.sub_job} Lv.{alt.main_job_level})
            </option>
          ))}
        </select>

        {selectedAlt && (
          <div className="mt-3 text-sm text-gray-300">
            <div>Arme: {selectedAlt.weapon_type}</div>
            {/* 🗑️ Pet data removed - now in AltPetOverlay */}
            {/* {selectedAlt.pet_name && <div>Pet: {selectedAlt.pet_name}</div>} */}
            {selectedAlt.party.length > 0 && (
              <div className="text-xs mt-1 text-gray-400">
                Party: {selectedAlt.party.join(', ')}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Content scrollable */}
      {loadingAbilities ? (
        <div className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <RefreshCw className="w-8 h-8 animate-spin text-cyan-400 mx-auto mb-3" />
            <p className="text-gray-400">Chargement des capacités...</p>
          </div>
        </div>
      ) : altAbilities ? (
        <div className="flex-1 overflow-y-auto p-4">
          {/* Magic Section */}
          {altAbilities.spells.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white font-bold text-lg mb-3 flex items-center gap-2">
                <span className="text-purple-400">✨</span>
                Sorts ({selectedSpells.size}/{altAbilities.spells.length})
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {altAbilities.spells.map((spell, idx) => (
                  <SelectableButton
                    key={idx}
                    label={spell.name}
                    sublabel={`Lv.${spell.level}`}
                    isSelected={selectedSpells.has(spell.name)}
                    onClick={() => toggleSpell(spell.name)}
                    variant="success"
                  />
                ))}
              </div>
            </div>
          )}

          {/* Job Abilities Section */}
          {altAbilities.job_abilities.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white font-bold text-lg mb-3 flex items-center gap-2">
                <span className="text-yellow-400">⚡</span>
                Job Abilities ({selectedJobAbilities.size}/{altAbilities.job_abilities.length})
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {altAbilities.job_abilities.map((ability, idx) => (
                  <SelectableButton
                    key={idx}
                    label={ability.name}
                    sublabel={`Lv.${ability.level}`}
                    isSelected={selectedJobAbilities.has(ability.name)}
                    onClick={() => toggleJobAbility(ability.name)}
                    variant="warning"
                  />
                ))}
              </div>
            </div>
          )}

          {/* Weapon Skills Section */}
          {altAbilities.weapon_skills.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white font-bold text-lg mb-3 flex items-center gap-2">
                <span className="text-red-400">⚔️</span>
                Weapon Skills ({selectedWeaponSkills.size}/{altAbilities.weapon_skills.length})
              </h3>
              <div className="grid grid-cols-2 gap-2">
                {altAbilities.weapon_skills.map((ws, idx) => (
                  <SelectableButton
                    key={idx}
                    label={ws}
                    isSelected={selectedWeaponSkills.has(ws)}
                    onClick={() => toggleWeaponSkill(ws)}
                    variant="danger"
                  />
                ))}
              </div>
            </div>
          )}

          {/* Macros Section */}
          {altAbilities.macros.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white font-bold text-lg mb-3 flex items-center gap-2">
                <span className="text-yellow-400">📋</span>
                Macros ({selectedMacros.size}/{altAbilities.macros.length})
              </h3>
              <div className="grid grid-cols-1 gap-2">
                {altAbilities.macros.map((macro, idx) => (
                  <SelectableButton
                    key={idx}
                    label={macro.name}
                    sublabel={macro.command}
                    isSelected={selectedMacros.has(macro.name)}
                    onClick={() => toggleMacro(macro.name)}
                    variant="warning"
                  />
                ))}
              </div>
            </div>
          )}

          {/* Job Abilities (Info only) */}
          {/* Pet Commands (Info only) */}
          {altAbilities.pet_commands.length > 0 && (
            <div className="mb-6">
              <h3 className="text-white font-bold text-lg mb-3 flex items-center gap-2">
                <span className="text-green-400">🐾</span>
                Pet Commands (Toutes incluses: {altAbilities.pet_commands.length})
              </h3>
              <div className="grid grid-cols-2 gap-2 opacity-60">
                {altAbilities.pet_commands.map((cmd, idx) => (
                  <div
                    key={idx}
                    className="bg-slate-700 text-white px-3 py-2 rounded text-sm"
                  >
                    <div className="font-semibold">{cmd.name}</div>
                    <div className="text-xs text-green-300">{cmd.type}</div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      ) : (
        <div className="flex-1 flex items-center justify-center">
          <p className="text-gray-400 text-center">
            Sélectionnez un ALT pour configurer
          </p>
        </div>
      )}

      {/* Footer avec bouton Save */}
      {altAbilities && (
        <div className="bg-slate-800/80 border-t border-slate-700 p-4">
          <button
            onClick={saveConfiguration}
            disabled={saving || saveSuccess}
            className={`w-full py-3 rounded-lg font-bold text-white transition-all flex items-center justify-center gap-2 ${
              saveSuccess
                ? "bg-green-600"
                : "bg-gradient-to-r from-cyan-600 to-purple-600 hover:from-cyan-500 hover:to-purple-500"
            } ${(saving || saveSuccess) ? "opacity-75 cursor-not-allowed" : ""}`}
          >
            {saveSuccess ? (
              <>
                <Check className="w-5 h-5" />
                Configuration sauvegardée !
              </>
            ) : saving ? (
              <>
                <RefreshCw className="w-5 h-5 animate-spin" />
                Sauvegarde...
              </>
            ) : (
              <>
                <Save className="w-5 h-5" />
                Sauvegarder Configuration
              </>
            )}
          </button>
          <div className="mt-2 text-center text-xs text-gray-400">
            {selectedSpells.size} sorts • {selectedWeaponSkills.size} WS • {selectedMacros.size} macros
          </div>
        </div>
      )}
    </div>
  );
};

export default AltAdminPanel;