import React, { useState, useEffect } from "react";
import { Target, Swords, Wand2, Zap, Sword, Dog, Rabbit, UserPlus, Navigation, Wifi, WifiOff, RefreshCw } from 'lucide-react';
import CommandButton from "./CommandButton";
import CommandButtonWithRecast from "./CommandButtonWithRecast";
import DirectionalPad from "./DirectionalPad";
import { Direction } from "../types";
import { backendService, PythonAltAbilities } from "../services/backendService";
import { configService } from "../services/configService";
import { getSpellId } from "../data/spellIds";
import { getBloodPactRecastId } from "../data/bloodPactRecastIds";
import { ABILITY_RECAST_IDS } from "../data/recastIds";

interface AltControllerProps {
  altId: number;
  altName: string;
}

const AltController: React.FC<AltControllerProps> = ({ altId, altName }) => {
  const [altData, setAltData] = useState<PythonAltAbilities | null>(null);
  const [loading, setLoading] = useState(true);
  const [connectionStatus, setConnectionStatus] = useState<"connected" | "disconnected" | "reconnecting">("connected");
  
  // États UI
  const [followActive, setFollowActive] = useState(false);
  const [mountActive, setMountActive] = useState(false);
  const [showSpells, setShowSpells] = useState(false);
  const [showAbilities, setShowAbilities] = useState(false);
  const [showWeaponSkills, setShowWeaponSkills] = useState(false);
  const [showPetCommands, setShowPetCommands] = useState(false);
  const [showBloodPactRage, setShowBloodPactRage] = useState(false);
  const [showBloodPactWard, setShowBloodPactWard] = useState(false);
  const [showTeleports, setShowTeleports] = useState(false);
  const [showMacros, setShowMacros] = useState(false);
  const [selectedSpellTarget, setSelectedSpellTarget] = useState<{ spell: any; showTargets: boolean }>({ spell: null, showTargets: false });
  const [autoEngage, setAutoEngage] = useState(false);
  
  // 🎓 SCH: Tracker le mode Arts actif (Light/Dark/None)
  const [schArtsMode, setSchArtsMode] = useState<'light' | 'dark' | 'none'>('none');
  const [schAutoCastActive, setSchAutoCastActive] = useState(false);

  // Fonction pour contrôler le SCH AutoCast
  const handleSchAutocast = async () => {
    const newState = !schAutoCastActive;
    setSchAutoCastActive(newState);
    
    try {
      const result = await backendService.controlSchAutocast(newState ? 'start' : 'stop');
      if (result.success) {
        console.log(`SCH AutoCast ${newState ? 'started' : 'stopped'}`);
        
        // Si on désactive, envoyer les commandes de stop
        if (!newState) {
          await sendCommand('/console send @sch //ac dfollow stop');
        }
      }
    } catch (error) {
      console.error(`Error controlling SCH AutoCast:`, error);
      setSchAutoCastActive(!newState); // Rollback en cas d'erreur
    }
  };
  
  // 🎵 AutoCast: État du système d'automatisation
  const [autoCastActive, setAutoCastActive] = useState(false);

  // Configuration filtrée
  const [configuredSpells, setConfiguredSpells] = useState<any[]>([]);
  const [configuredJobAbilities, setConfiguredJobAbilities] = useState<any[]>([]);
  const [configuredWeaponSkills, setConfiguredWeaponSkills] = useState<string[]>([]);
  const [configuredMacros, setConfiguredMacros] = useState<any[]>([]);

  /**
   * Trie les spells par type: Heal → Buff → Debuff → Attack
   */
  const sortSpellsByType = (spells: any[]) => {
    const typeOrder: { [key: string]: number } = {
      // 1. Healing en premier
      'Healing': 1,
      'Cure': 1,
      'Curing': 1,
      // 2. Buffs ensuite
      'Enhancing': 2,
      'Buff': 2,
      'Support': 2,
      // 3. Debuffs
      'Enfeebling': 3,
      'Debuff': 3,
      // 4. Attaques en dernier
      'Elemental': 4,
      'Offensive': 4,
      'Attack': 4,
      'Dark Magic': 4,
      'Ninjutsu': 4,
      'Blue Magic': 4,
    };

    return [...spells].sort((a, b) => {
      const typeA = typeOrder[a.type] || 999;
      const typeB = typeOrder[b.type] || 999;
      
      // Tri par type d'abord
      if (typeA !== typeB) {
        return typeA - typeB;
      }
      
      // Puis par level
      const levelA = parseInt(a.level) || 0;
      const levelB = parseInt(b.level) || 0;
      if (levelA !== levelB) {
        return levelA - levelB;
      }
      
      // Enfin par nom alphabétique
      return (a.name || '').localeCompare(b.name || '');
    });
  };

  // 🆕 Auto Engage: Utilise le tool Lua AutoEngage
  const handleAutoEngageToggle = async () => {
    if (!altData) return;
    
    const newState = !autoEngage;
    setAutoEngage(newState);
    
    if (newState) {
      // Activer: Assiste automatiquement le premier membre de la party engagé
      console.log(`[Auto Engage] ✅ Starting - Will assist first engaged party member`);
      await sendCommand('//ac autoengage start');
    } else {
      // Désactiver
      console.log(`[Auto Engage] 🛑 Stopping`);
      await sendCommand('//ac autoengage stop');
    }
  };

  // Charger les données de l'ALT au démarrage
  useEffect(() => {
    loadAltData();
    
    // S'abonner aux mises à jour via SocketIO
    const unsubscribe = backendService.subscribe('alt_update', (data: PythonAltAbilities) => {
      if (data.alt_name === altName) {
        console.log(`[AltController ${altName}] Received update:`, data);
        setAltData(data);
        
        // 🎓 SCH: Mettre à jour le mode Arts depuis les buffs du serveur
        if (data.main_job === 'SCH') {
          console.log('[SCH] Active buffs from server:', data.active_buffs);
          
          // Le serveur Python envoie toujours un array maintenant
          const buffs = data.active_buffs || [];
          console.log('[SCH] Buffs array:', buffs);
          
          // Détecter le mode Arts
          if (buffs.includes('Light Arts') || buffs.includes('Addendum: White')) {
            console.log('[SCH] ✅ Setting mode to LIGHT from server');
            setSchArtsMode('light');
          } else if (buffs.includes('Dark Arts') || buffs.includes('Addendum: Black')) {
            console.log('[SCH] ✅ Setting mode to DARK from server');
            setSchArtsMode('dark');
          } else {
            // Pas d'Arts détecté
            console.log('[SCH] ⚪ No Arts detected, setting to NONE');
            setSchArtsMode('none');
          }
        }
      }
    });

    return () => {
      unsubscribe();
    };
  }, [altName]);

  // 🆕 CORRECTION: Optimiser les re-renders - Ne recharger que si vraiment nécessaire
  useEffect(() => {
    if (altData) {
      // Ne réappliquer la config que si pet, arme ou taille de party change
      console.log(`[AltController ${altName}] Checking for changes...`);
      applyConfiguration();
    }
  }, [altData?.pet_name, altData?.weapon_type, altData?.party?.length]);  // 🐾 pet_name for Blood Pact menu
  
  // 🆕 Premier chargement uniquement
  useEffect(() => {
    if (altData && altData.alt_name) {
      console.log(`[AltController ${altName}] Initial load`);
      applyConfiguration();
    }
  }, [altData?.alt_name]);

  // Recharger la configuration quand elle change
  useEffect(() => {
    const unsubscribe = configService.subscribe((config) => {
      if (altData && 
          config.alt_name === altData.alt_name && 
          config.main_job === altData.main_job && 
          config.sub_job === altData.sub_job) {
        console.log(`[AltController ${altName}] Config changed, reloading...`);
        applyConfiguration();
      }
    });

    return () => unsubscribe();
  }, [altData]);

  const loadAltData = async () => {
    setLoading(true);
    try {
      const data = await backendService.fetchAltAbilities(altName);
      if (data) {
        console.log(`[AltController ${altName}] Loaded data:`, data);
        setAltData(data);
        setConnectionStatus("connected");
        
        // 🎓 SCH: Initialiser le mode Arts depuis les buffs
        if (data.main_job === 'SCH' && data.active_buffs) {
          const buffs = data.active_buffs || [];
          if (buffs.includes('Light Arts') || buffs.includes('Addendum: White')) {
            setSchArtsMode('light');
            console.log('[SCH] Initial mode: Light Arts detected');
          } else if (buffs.includes('Dark Arts') || buffs.includes('Addendum: Black')) {
            setSchArtsMode('dark');
            console.log('[SCH] Initial mode: Dark Arts detected');
          } else {
            setSchArtsMode('none');
            console.log('[SCH] Initial mode: No Arts detected');
          }
        }
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

  const applyConfiguration = () => {
    if (!altData) return;

    // Charger depuis le serveur en arrière-plan
    configService.loadConfigFromServer(
      altData.alt_name,
      altData.main_job,
      altData.sub_job
    ).then(serverConfig => {
      if (serverConfig) {
        console.log(`[AltController] Loaded config from server, applying...`);
        applyConfigurationWithData(serverConfig);
      } else {
        // Fallback sur le cache local
        const localConfig = configService.getConfig(
          altData.alt_name,
          altData.main_job,
          altData.sub_job
        );
        if (localConfig) {
          applyConfigurationWithData(localConfig);
        } else {
          // Pas de config, tout afficher
          console.log(`[AltController ${altName}] No config, showing all`);
          setConfiguredSpells(sortSpellsByType(altData.spells));
          setConfiguredJobAbilities(altData.job_abilities);
          setConfiguredWeaponSkills(altData.weapon_skills);
          setConfiguredMacros(altData.macros);
        }
      }
    });
  };
  
  const applyConfigurationWithData = (config: any) => {
    if (!altData) return;

    // Filtrer selon la configuration sauvegardée
    const filteredSpells = altData.spells.filter(spell =>
      config.selected_spells.includes(spell.name)
    );
    setConfiguredSpells(sortSpellsByType(filteredSpells));

    const filteredAbilities = altData.job_abilities.filter(ability =>
      config.selected_job_abilities?.includes(ability.name)
    );
    setConfiguredJobAbilities(filteredAbilities);

    const filteredWS = altData.weapon_skills.filter(ws =>
      config.selected_weapon_skills.includes(ws)
    );
    setConfiguredWeaponSkills(filteredWS);

    const filteredMacros = altData.macros.filter(macro =>
      config.selected_macros.includes(macro.name)
    );
    setConfiguredMacros(filteredMacros);

    console.log(`[AltController ${altName}] Applied config:`, {
      spells: filteredSpells.length,
      abilities: filteredAbilities.length,
      ws: filteredWS.length,
      macros: filteredMacros.length,
      // petAttacks: altData.pet_name ? Object.keys(altData.pet_attacks).length : 0,  // 🗑️ Removed
      recasts: altData.spell_recasts ? Object.keys(altData.spell_recasts).length : 0
    });
  };

  // 🆕 Helper pour obtenir le recast d'un spell par son nom
  const getSpellRecast = (spellName: string): number => {
    if (!altData) return 0;
    
    // Vérifier si c'est un Blood Pact (ils utilisent ability_recasts, pas spell_recasts!)
    const bloodPactRecastId = getBloodPactRecastId(spellName);
    if (bloodPactRecastId !== null && altData.ability_recasts) {
      return altData.ability_recasts[bloodPactRecastId.toString()] || 0;
    }
    
    // Sinon, utiliser l'ID normal du spell dans spell_recasts
    if (!altData.spell_recasts) return 0;
    const spellId = getSpellId(spellName);
    if (!spellId) return 0;
    
    return altData.spell_recasts[spellId.toString()] || 0;
  };

  // 🆕 Helper pour obtenir le recast d'une ability par son nom
  const getAbilityRecast = (abilityName: string): number => {
    if (!altData || !altData.ability_recasts) return 0;
    
    // Utiliser ABILITY_RECAST_IDS qui contient les vrais recast IDs
    const recastId = ABILITY_RECAST_IDS[abilityName];
    if (recastId === undefined) return 0;
    
    return altData.ability_recasts[recastId.toString()] || 0;
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
      // TODO: Afficher un toast d'erreur
    }
  };

  const handleDirection = (direction: Direction, isPressed: boolean) => {
    const directionMap: Record<Direction, { key: string; action: string }> = {
      up: { key: "numpad8", action: isPressed ? "down" : "up" },
      down: { key: "numpad2", action: isPressed ? "down" : "up" },
      left: { key: "numpad4", action: isPressed ? "down" : "up" },
      right: { key: "numpad6", action: isPressed ? "down" : "up" },
    };
    
    const cmd = directionMap[direction];
    sendCommand(`//setkey ${cmd.key} ${cmd.action}`);
  };

  const handleDirectionStart = (direction: Direction) => {
    handleDirection(direction, true);
  };

  const handleDirectionEnd = (direction: Direction) => {
    handleDirection(direction, false);
  };

  const toggleFollow = async () => {
  const newState = !followActive;
  setFollowActive(newState);
  
  if (newState) {
    // Follow ON : utiliser DistanceFollow avec le mode approprié
    // Si AutoEngage est actif, mode combat, sinon mode suivi
    const mode = autoEngage ? 'combat' : 'follow';
    const command = `//ac dfollow Dexterbrown ${mode}`;
    console.log(`[Follow] Sending command: ${command}`);
    // TODO: À terme, configurable via la webapp (page admin) comme pour l'overlay
    await sendCommand(command);
  } else {
    // Follow OFF : arrêter DistanceFollow
    console.log('[Follow] Stopping DistanceFollow');
    await sendCommand("//ac dfollow stop");
  }
};

  const toggleMount = () => {
    const newState = !mountActive;
    setMountActive(newState);
    sendCommand(newState ? "/mount chocobo" : "/dismount");
  };

  /**
   * 🎵 AutoCast: Toggle le système d'automatisation
   */
  const toggleAutoCast = async () => {
    const newState = !autoCastActive;
    setAutoCastActive(newState);
    
    if (newState) {
      console.log(`[AutoCast] Starting for ${altData?.alt_name} (${altData?.main_job})`);
      
      // 🆕 Notifier le serveur Python pour le BRD
      if (altData?.main_job === 'BRD') {
        try {
          await fetch('http://127.0.0.1:5000/brd/autocast', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'start' })
          });
          console.log('[AutoCast] ✅ BRD Manager notified (start)');
        } catch (error) {
          console.error('[AutoCast] Error notifying BRD Manager:', error);
        }
      }
      
      // Démarrer AutoCast
      await sendCommand(`//ac start`);
      
      // 🆕 Pour le BRD: NE PAS activer auto_songs
      // Le serveur Python gère tout automatiquement
      console.log(`[AutoCast] ✅ Started - Server will manage songs automatically`)
      
      // 🆕 AUTO-DÉTECTION DU HEALER
      if (altData?.party && altData.party.length > 0) {
        try {
          // Récupérer tous les ALTs pour connaître leurs jobs
          const allAlts = await backendService.fetchAllAlts();
          
          // Liste des Trusts healers connus (par ordre de priorité)
          const trustHealers = [
            'mildaurion',        // 🌟 BEST healer!
            'apururu', 'kupipi', 'yoran-oran', 'cherukiki', 'joachim',
            'koru-moru', 'ajido-marujido', 'karaha-baruha', 'romaa mihgo',
            'star sibyl', 'ulmia', 'qultada', 'adelheid', 'sylvie',
            'monberaux', 'valaineral'
          ];
          
          // Chercher un healer dans la party
          const healerJobs = ['WHM', 'RDM', 'SCH'];
          let healerName = null;
          
          for (const memberName of altData.party) {
            // 1. Vérifier si c'est un ALT healer
            const memberAlt = allAlts.find(alt => alt.name === memberName);
            if (memberAlt && healerJobs.includes(memberAlt.main_job)) {
              healerName = memberName;
              console.log(`[AutoCast] 🏥 Found ALT healer: ${healerName} (${memberAlt.main_job})`);
              break;
            }
            
            // 2. Vérifier si c'est un Trust healer (case insensitive)
            const nameLower = memberName.toLowerCase();
            if (trustHealers.some(trust => nameLower.includes(trust))) {
              healerName = memberName;
              console.log(`[AutoCast] 🏥 Found Trust healer: ${healerName}`);
              break;
            }
          }
          
          if (healerName) {
            // Envoyer la commande follow automatiquement
            await new Promise(resolve => setTimeout(resolve, 500)); // Attendre 0.5s
            await sendCommand(`//ac follow ${healerName}`);
            console.log(`[AutoCast] ✅ Auto-following healer: ${healerName}`);
          } else {
            console.log(`[AutoCast] ⚠️ No healer found in party, following <p1>`);
          }
        } catch (error) {
          console.error('[AutoCast] Error finding healer:', error);
        }
      }
    } else {
      console.log(`[AutoCast] Stopping for ${altData?.alt_name}`);
      
      // 🆕 Notifier le serveur Python pour le BRD
      if (altData?.main_job === 'BRD') {
        try {
          await fetch('http://127.0.0.1:5000/brd/autocast', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ action: 'stop' })
          });
          console.log('[AutoCast] ✅ BRD Manager notified (stop)');
        } catch (error) {
          console.error('[AutoCast] Error notifying BRD Manager:', error);
        }
      }
      
      // Arrêter le follow d'abord
      await sendCommand(`//ac stopfollow`);
      await new Promise(resolve => setTimeout(resolve, 200));
      
      // Pour le BRD: Désactiver auto-songs et debuffs avant de stop
      if (altData?.main_job === 'BRD') {
        await sendCommand(`//ac disable_auto_songs`);
        await new Promise(resolve => setTimeout(resolve, 200));
        await sendCommand(`//ac disable_debuffs`);
        await new Promise(resolve => setTimeout(resolve, 200));
      }
      
      await sendCommand(`//ac stop`);
    }
  };

  /**
   * 🆕 CORRECTION: Walk/Run toggle - Simule l'appui+relâchement de la touche /
   */
  const handleWalkRun = () => {
    // Appuyer sur la touche
    sendCommand("//setkey numpad/ down");
    // Relâcher immédiatement après
    setTimeout(() => {
      sendCommand("//setkey numpad/ up");
    }, 50); // 50ms de délai
  };

  /**
   * 🆕 CORRECTION: Cast un sort avec le bon ciblage (utilise NOM au lieu de <p1>)
   * Gère aussi les pet attacks qui nécessitent un ciblage party
   */
  const handleSpellCast = (spell: any, memberName: string) => {
    const spellType = spell.type || "";
    
    if (spellType === "pet_attack") {
      // C'est un Blood Pact Ward de type party
      sendCommand(`/pet "${spell.name}" ${memberName}`);
    } else {
      // Sort normal
      sendCommand(`/ma "${spell.name}" ${memberName}`);
    }
    
    setSelectedSpellTarget({ spell: null, showTargets: false });
  };

  /**
   * 🎓 SCH: Cast un buff sur toute la party avec Accession
   */
  const handleSchAccessionCast = async (spell: any) => {
    const startTime = Date.now();
    console.log(`[SCH Accession] ⏱️ START - Casting ${spell.name} on all party`);
    console.log(`[SCH Accession] Current Arts mode:`, schArtsMode);
    
    // 1. Vérifier si Light Arts est actif (via notre tracker local)
    let needsLightArts = false;
    if (schArtsMode !== 'light') {
      console.log(`[SCH Accession] Activating Light Arts (current mode: ${schArtsMode})...`);
      await sendCommand('/ja "Light Arts" <me>');
      setSchArtsMode('light');
      needsLightArts = true;
    } else {
      console.log(`[SCH Accession] ✅ Light Arts already active!`);
    }
    
    // 2. Lancer Accession (attendre plus si on vient de lancer Light Arts)
    if (needsLightArts) {
      await new Promise(resolve => setTimeout(resolve, 2000)); // 2s après Light Arts
    }
    console.log(`[SCH Accession] Activating Accession...`);
    await sendCommand('/ja "Accession" <me>');
    await new Promise(resolve => setTimeout(resolve, 500)); // 0.5s pour que Accession soit actif
    
    // 3. Lancer le sort sur soi (Accession le rendra AoE)
    console.log(`[SCH Accession] Casting ${spell.name}...`);
    await sendCommand(`/ma "${spell.name}" <me>`);
    
    const totalTime = Date.now() - startTime;
    console.log(`[SCH Accession] ✅ DONE in ${totalTime}ms`);
    
    setSelectedSpellTarget({ spell: null, showTargets: false });
  };

  const handleJobAbility = (ability: any) => {
    const abilityName = typeof ability === "string" ? ability : ability.name;
    const category = typeof ability === "object" ? ability.category?.toLowerCase() : "";
    
    // 🎓 SCH: Tracker les Arts quand on les lance manuellement
    if (altData?.main_job === 'SCH') {
      const abilityLower = abilityName.toLowerCase();
      if (abilityLower.includes('light arts') || abilityLower.includes('addendum: white')) {
        setSchArtsMode('light');
        console.log('[SCH] Mode set to Light Arts');
      } else if (abilityLower.includes('dark arts') || abilityLower.includes('addendum: black')) {
        setSchArtsMode('dark');
        console.log('[SCH] Mode set to Dark Arts');
      }
    }
    
    // 🎯 Logique de ciblage intelligente basée sur la catégorie
    let target = "<me>"; // Par défaut: self
  
  // Catégories qui ciblent l'ennemi (<t>)
  const targetCategories = [
    "target", "attack", "offense", "offensive", "debuff", 
    "quick_draw", "flourish"
  ];
  
  // Catégories qui ciblent la party (<party>)
  const partyCategories = ["party"];
  
  if (targetCategories.includes(category)) {
    target = "<t>";
  } else if (partyCategories.includes(category)) {
    target = "<party>";
  }
  // Sinon reste <me> (self, buff, enhancing, special, stance, etc.)
  
  console.log(`[handleJobAbility] ${abilityName} (${category}) → ${target}`);
  sendCommand(`/ja "${abilityName}" ${target}`);
};

  const handleWeaponSkill = (wsName: string) => {
    // Myrkr est une WS spéciale qui cible soi-même pour récupérer du MP
    if (wsName.toLowerCase() === "myrkr") {
      sendCommand(`/ws "Myrkr" <me>`);
    } else {
      sendCommand(`/ws "${wsName}" <t>`);
    }
  };

  /**
   * 🎯 Pet Command avec ciblage intelligent basé sur la catégorie
   */
  const handlePetCommand = (cmd: any) => {
    const commandName = typeof cmd === "string" ? cmd : cmd.name;
    const category = typeof cmd === "object" ? cmd.category?.toLowerCase() : "";
    
    console.log(`[handlePetCommand] Command:`, cmd);
    
    let target = "<me>"; // Par défaut
    
    // 🎯 Catégories qui ciblent l'ennemi (<t>)
    const targetCategories = ["attack", "offense", "offensive"];
    
    // 🎯 Catégories qui ciblent soi-même (<me>)
    const selfCategories = ["support", "utility", "self", "pet"];
    
    // Utiliser la catégorie si disponible
    if (category && targetCategories.includes(category)) {
      target = "<t>";
    } else if (category && selfCategories.includes(category)) {
      target = "<me>";
    } else {
      // Fallback: détection par nom de commande
      const commandLower = commandName.toLowerCase();
      
      // Commandes d'attaque (ciblent <t>)
      const attackCommands = ["assault", "sic", "fight"];
      
      // Commandes de contrôle/support (ciblent <me>)
      const supportCommands = ["release", "retreat", "heel", "stay", "withdraw", "dismiss"];
      
      if (attackCommands.some(c => commandLower === c)) {
        target = "<t>";
      } else if (supportCommands.some(c => commandLower === c)) {
        target = "<me>";
      }
    }
    
    console.log(`[handlePetCommand] ${commandName} → ${target} (category: ${category})`);
    sendCommand(`/pet "${commandName}" ${target}`);
  };

  /**
   * 🆕 AJOUT: Gestion des pet attacks avec ciblage intelligent
   */
  const handlePetAttack = (attack: any) => {
    const attackName = typeof attack === "string" ? attack : attack.name;
    const type = typeof attack === "object" ? attack.type?.toLowerCase() : "";
    const category = typeof attack === "object" ? attack.category?.toLowerCase() : "";
    
    // 🆕 CONFIGURATION: Blood Pacts Ward qui nécessitent un ciblage party
    const wardPartyTargets = [
      "sleepga", "hastega", "slowga", "spring water", "whispering wind"
    ];
    
    // 🆕 CONFIGURATION: Blood Pacts qui ciblent <me> (buffs self)
    const wardSelfTargets = [
      "healing ruby", "healing ruby ii", "soothing ruby", "shining ruby", "glittering ruby",
      "crimson howl", "inferno howl", "earthen ward", "earthen armor", "stone ii armor", "stone iv armor",
      "aerial armor", "fleet wind", "frost armor", "crystal blessing", "diamond storm",
      "rolling thunder", "lightning armor", "shock squall", "thunderstorm",
      "lunar cry", "ecliptic growl", "ecliptic howl", "heavenward howl",
      "noctoshield", "dream shroud", "nightmare", "ultimate terror",
      "astral flow +", "hastega ii", "mewing lullaby", "eerie eye",
      "katabatic blades", "wind's blessing", "chinook"
    ];
    
    const attackLower = attackName.toLowerCase();
    
    // Détection intelligente du ciblage
    let target = "<t>"; // Par défaut: cible actuelle
    
    if (wardPartyTargets.some(ward => attackLower.includes(ward))) {
      // Ouvre le menu de sélection party
      console.log(`[handlePetAttack] ${attackName} nécessite sélection party`);
      setSelectedSpellTarget({ spell: { name: attackName, type: "pet_attack" }, showTargets: true });
      return;
    } else if (wardSelfTargets.some(ward => attackLower.includes(ward)) || 
               category === "support" || 
			    category === "buff" ||    // 🆕 AJOUT pour BST
               type === "enhancing") {
      target = "<me>";
    }
    
    console.log(`[handlePetAttack] ${attackName} → ${target}`);
    sendCommand(`/pet "${attackName}" ${target}`);
  };

  const handleMacro = (macro: any) => {
    sendCommand(macro.command);
  };

  const handleTeleport = (location: string) => {
    sendCommand(`!${location}`);
  };

  const teleportLocations = ["Warp", "Holla", "Dem", "Mea", "Vahzl", "Library", "Expcamp", "Expclassic"];

  /**
   * 🆕 CORRECTION: Déterminer si un sort nécessite un ciblage (party/ally)
   * UTILISE spell.category au lieu de spell.targets
   */
  const needsTargeting = (spell: any) => {
    const category = spell.category?.toLowerCase() || "";
    const type = spell.type?.toLowerCase() || "";
    const name = spell.name?.toLowerCase() || "";
    
    // DEBUG: Afficher les infos du sort
    console.log(`[needsTargeting] ${spell.name}: category="${category}", type="${type}"`);
    
    // 🆕 Pour SCH: Sorts self-only qui peuvent utiliser Accession
    const selfOnlyAccessionSpells = ["blink", "stoneskin", "aquaveil", "phalanx", "refresh"];
    const isSelfOnlyAccession = selfOnlyAccessionSpells.some(s => name.includes(s));
    
    // Si c'est un SCH avec un sort self-only Accession, ouvrir le menu
    if (altData?.main_job === 'SCH' && isSelfOnlyAccession) {
      return true;
    }
    
    // Si category est "self" ou "area" (AoE), jamais de menu (sauf exceptions ci-dessus)
    if (category === "self" || category === "area") {
      return false;
    }
    
    // Si category est "party", toujours ouvrir le menu (même pour Waltz)
    if (category === "party" || category === "ally") {
      return true;
    }
    
    // Sorts qui sont self-only par défaut (sauf si category="party")
    const selfOnlySpells = ["samba", "jig", "step", "flourish"];
    const isSelfOnly = selfOnlySpells.some(s => name.includes(s));
    
    if (isSelfOnly) {
      return false;
    }
    
    // 🆕 Pour SCH: Cure I-IV peuvent utiliser Accession, donc ouvrir le menu party
    const schAccessionSpells = ["cure", "cure ii", "cure iii", "cure iv"];
    const isSchAccessionSpell = schAccessionSpells.some(s => name === s);
    
    // Sorts qui nécessitent la sélection d'un membre de party
    // Liste explicite de sorts de soin/buff connus
    const healingSpells = ["cura", "curaga", "regen", "protect", "shell", "haste", "refresh", "raise", "phalanx"];
    const isHealingSpell = healingSpells.some(h => name.toLowerCase().includes(h));
    
    return category === "support" ||
           type === "healing" ||
           isHealingSpell ||
           isSchAccessionSpell ||
           (category === "target" && (type === "enhancing" || type === "healing"));
  };

  /**
   * 🆕 AJOUT: Séparer les Blood Pacts en Rage et Ward
   */
  const separateBloodPacts = (attacks: any[]) => {
    const rage: any[] = [];
    const ward: any[] = [];
    const other: any[] = [];
    
    attacks.forEach(attack => {
      const category = attack.category?.toLowerCase() || '';
      
      // Utiliser la catégorie du jobs.json
      if (category === 'attack') {
        // Blood Pact: Rage (attaques)
        rage.push(attack);
      } else if (category === 'support') {
        // Blood Pact: Ward (support/buffs)
        ward.push(attack);
      } else {
        // Autres (ne devrait pas arriver pour les Blood Pacts)
        other.push(attack);
      }
    });
    
    return { rage, ward, other };
  };

  /**
   * 🆕 AJOUT: Récupérer les attaques du pet actif
   */
  const getActivePetAttacks = (): any[] => {
    if (!altData || !altData.pet_name) return [];
    
    console.log('[DEBUG getActivePetAttacks] pet_name:', altData.pet_name);
    console.log('[DEBUG getActivePetAttacks] pet_attacks:', altData.pet_attacks);
    
    // Récupérer les attaques du pet actif depuis pet_attacks
    const attacks = altData.pet_attacks[altData.pet_name] || [];
    
    console.log('[DEBUG getActivePetAttacks] attacks found:', attacks);
    
    // Si c'est un tableau de strings, le convertir en objets
    return attacks.map(attack => {
      if (typeof attack === "string") {
        return { name: attack };
      }
      return attack;
    });
  };

  /**
   * 🆕 AJOUT: Déterminer la couleur d'un sort selon son type
   */
  const getSpellColor = (spell: any): string => {
    const type = spell.type?.toLowerCase() || "";
    const category = spell.category?.toLowerCase() || "";

    // Debuffs (violet clair)
    if (type === "enfeebling" || type.includes("debuff")) {
      return "bg-purple-500 hover:bg-purple-400";
    }

    // Sorts offensifs (rouge)
    if (type.includes("elemental") || type.includes("dark") || category === "attack") {
      return "bg-red-700 hover:bg-red-600";
    }

    // Sorts de soin (vert)
    if (type === "healing") {
      return "bg-green-700 hover:bg-green-600";
    }

    // Sorts d'amélioration/buff (bleu)
    if (type === "enhancing" || category === "support" || category === "party" || category === "self") {
      return "bg-blue-700 hover:bg-blue-600";
    }

    // Summoning (violet foncé)
    if (type === "summoning") {
      return "bg-purple-700 hover:bg-purple-600";
    }

    // Par défaut (gris)
    return "bg-slate-700 hover:bg-slate-600";
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

  const activePetAttacks = getActivePetAttacks();
  
  // Séparer Blood Pacts seulement pour SMN
  const isSMN = altData?.main_job === 'SMN';
  const { rage: bloodPactRage, ward: bloodPactWard, other: otherPetAttacks } = isSMN 
    ? separateBloodPacts(activePetAttacks)
    : { rage: [], ward: [], other: activePetAttacks };

  // 🐛 DEBUG: Vérifier le job pour le bouton AutoCast
  console.log(`[AltController] Job: ${altData?.main_job}, Show AutoCast button: ${altData?.main_job === 'BRD'}`);

  return (
    <div className="h-full bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 p-2 pb-0 flex flex-col">
      {/* 📱 Header compact pour tablette */}
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
              {/* 🎓 SCH: Indicateur du mode Arts */}
              {altData.main_job === 'SCH' && (
                <span className={`text-xs font-bold px-2 py-0.5 rounded ${
                  schArtsMode === 'light' ? 'bg-blue-600 text-white' :
                  schArtsMode === 'dark' ? 'bg-gray-900 text-white border border-gray-700' :
                  'bg-gray-600 text-gray-300'
                }`}>
                  {schArtsMode === 'light' ? '🔵 Light' :
                   schArtsMode === 'dark' ? '⚫ Dark' :
                   '⚪ None'}
                </span>
              )}
            </div>
            
            {/* 🗑️ Pet info removed - now in AltPetOverlay */}
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
        {/* 📱 Main Commands Grid - 3 colonnes pour tablette */}
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
              // Attack fait automatiquement Assist + Attack
              await sendCommand("/assist <p1>");
              await new Promise(resolve => setTimeout(resolve, 1000));
              await sendCommand("/attack <bt>");
            }}
            variant="danger"
          />
          <CommandButton
            label={autoEngage ? "⚔️ Engage: ON" : "⚔️ Engage: OFF"}
            icon={<Zap />}
            onClick={() => {
              const newState = !autoEngage;
              setAutoEngage(newState);
              sendCommand(newState ? '//ac autoengage start' : '//ac autoengage stop');
            }}
            variant={autoEngage ? "success" : "warning"}
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
          <CommandButton
            label="Weapon Skills"
            icon={<Sword />}
            onClick={() => setShowWeaponSkills(!showWeaponSkills)}
            variant="danger"
          />
          {/* 🆕 CORRECTION: Afficher Pet si commandes OU attaques disponibles */}
          {(altData.pet_commands.length > 0 || activePetAttacks.length > 0) && (
            <CommandButton
              label="Pet"
              icon={<Dog />}
              onClick={() => setShowPetCommands(!showPetCommands)}
              variant="success"
            />
          )}
          <CommandButton
            label={mountActive ? "Dismount" : "Mount"}
            icon={<Rabbit />}
            onClick={toggleMount}
            variant={mountActive ? "danger" : "warning"}
          />
          <CommandButton
            label="Walk/Run"
            icon={<Navigation />}
            onClick={handleWalkRun}
            variant="primary"
          />
          
          {/* 🎵 AutoCast OU Follow (pas les deux en même temps) */}
          {altData.main_job === 'BRD' ? (
            <CommandButton
              label={autoCastActive ? "🎵 Auto: ON" : "🎵 Auto: OFF"}
              icon={<Wand2 />}
              onClick={toggleAutoCast}
              variant={autoCastActive ? "success" : "primary"}
            />
          ) : altData.main_job === 'SCH' ? (
            <CommandButton
              label={schAutoCastActive ? "📚 Auto: ON" : "📚 Auto: OFF"}
              icon={<Wand2 />}
              onClick={handleSchAutocast}
              variant={schAutoCastActive ? "success" : "primary"}
            />
          ) : (
            <CommandButton
              label={followActive ? "Follow: ON" : "Follow: OFF"}
              icon={<UserPlus />}
              onClick={toggleFollow}
              variant={followActive ? "success" : "primary"}
            />
          )}
        </div>

        {/* Macros Button */}
        {configuredMacros.length > 0 && (
          <div className="mb-4">
            <CommandButton
              label={`Macros (${configuredMacros.length})`}
              icon={<span className="text-xl">📋</span>}
              onClick={() => setShowMacros(!showMacros)}
              variant="primary"
            />
          </div>
        )}

        {/* Teleport Button */}
        <div className="mb-4">
          <CommandButton
            label="Teleport"
            icon={<Navigation />}
            onClick={() => setShowTeleports(!showTeleports)}
            variant="primary"
          />
        </div>

        {/* 🆕 CORRECTION: Spell List avec couleurs dynamiques et detection category */}
        {showSpells && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">Magic Spells</h3>
            {configuredSpells.length === 0 ? (
              <p className="text-gray-400 text-center py-4 text-sm">
                Aucun sort configuré. Allez dans Admin pour configurer.
              </p>
            ) : (
              <div className="grid grid-cols-3 gap-2 max-h-64 overflow-y-auto">
                {configuredSpells.map((spell, idx) => {
                  const recastTime = getSpellRecast(spell.name);
                  return (
                    <CommandButtonWithRecast
                      key={idx}
                      label={spell.name}
                      recastTime={recastTime}
                      onClick={() => {
                        console.log(`[AltController] Spell clicked:`, spell);
                        if (needsTargeting(spell)) {
                          console.log(`[AltController] Opening party menu for ${spell.name}`);
                          setSelectedSpellTarget({ spell, showTargets: true });
                        } else {
                          const category = spell.category?.toLowerCase() || "";
                          const target = category === "self" ? "<me>" : "<t>";
                          console.log(`[AltController] Casting ${spell.name} on ${target}`);
                          handleSpellCast(spell, target);
                        }
                      }}
                      className={`${getSpellColor(spell)} text-white px-2 py-2 rounded transition-colors text-left`}
                    />
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Job Abilities List */}
        {showAbilities && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">Job Abilities</h3>
            {configuredJobAbilities.length === 0 ? (
              <p className="text-gray-400 text-center py-4 text-sm">
                Aucune ability configurée. Allez dans Admin pour configurer.
              </p>
            ) : (
              <div className="grid grid-cols-3 gap-2 max-h-64 overflow-y-auto">
                {configuredJobAbilities.map((ability, idx) => {
                  const recastTime = getAbilityRecast(ability.name);
                  return (
                    <CommandButtonWithRecast
                      key={idx}
                      label={ability.name}
                      recastTime={recastTime}
                      onClick={() => handleJobAbility(ability)}
                      className="bg-slate-700 hover:bg-slate-600 text-white px-2 py-2 rounded transition-colors text-left"
                    />
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Weapon Skills List */}
        {showWeaponSkills && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">Weapon Skills</h3>
            {configuredWeaponSkills.length === 0 ? (
              <p className="text-gray-400 text-center py-4 text-sm">
                Aucun WS configuré. Allez dans Admin pour configurer.
              </p>
            ) : (
              <div className="grid grid-cols-3 gap-2 max-h-64 overflow-y-auto">
                {configuredWeaponSkills.map((ws, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleWeaponSkill(ws)}
                    className="bg-slate-700 hover:bg-slate-600 text-white px-2 py-2 rounded transition-colors text-left text-sm font-semibold"
                  >
                    {ws}
                  </button>
                ))}
              </div>
            )}
          </div>
        )}

        {/* 🆕 CORRECTION: Pet Commands + Pet Attacks séparés */}
        {showPetCommands && (altData.pet_commands.length > 0 || activePetAttacks.length > 0) && (
          <div className="bg-slate-800 rounded-lg p-3 mb-3 border border-slate-600">
            <h3 className="text-white font-bold mb-2 text-base">
              Pet Commands {altData.pet_name && `(${altData.pet_name})`}
            </h3>
            
            {/* Commandes basiques du pet (Assault, Release, etc.) */}
            {altData.pet_commands.length > 0 && (
              <div className="mb-3">
                <h4 className="text-gray-300 text-sm font-semibold mb-2">Basic Commands</h4>
                <div className="grid grid-cols-3 gap-2">
                  {altData.pet_commands.map((cmd, idx) => (
                    <CommandButtonWithRecast
                      key={idx}
                      label={cmd.name}
                      recastTime={getAbilityRecast(cmd.name)}
                      onClick={() => handlePetCommand(cmd)}
                      className="bg-blue-700 hover:bg-blue-600 text-white px-2 py-2 rounded transition-colors text-sm font-semibold"
                    />
                  ))}
                </div>
              </div>
            )}

            {/* 🆕 Blood Pacts avec sous-menus */}
            {(bloodPactRage.length > 0 || bloodPactWard.length > 0) && (
              <div>
                <h4 className="text-gray-300 text-sm font-semibold mb-2">Blood Pacts</h4>
                
                {/* Boutons principaux Blood Pact */}
                <div className="grid grid-cols-2 gap-2 mb-2">
                  {bloodPactRage.length > 0 && (
                    <CommandButtonWithRecast
                      label="Blood Pact: Rage"
                      recastTime={getAbilityRecast("Blood Pact: Rage")}
                      onClick={() => setShowBloodPactRage(!showBloodPactRage)}
                      className="bg-red-700 hover:bg-red-600 text-white px-2 py-2 rounded transition-colors text-sm font-semibold"
                    />
                  )}
                  {bloodPactWard.length > 0 && (
                    <CommandButtonWithRecast
                      label="Blood Pact: Ward"
                      recastTime={getAbilityRecast("Blood Pact: Ward")}
                      onClick={() => setShowBloodPactWard(!showBloodPactWard)}
                      className="bg-blue-700 hover:bg-blue-600 text-white px-2 py-2 rounded transition-colors text-sm font-semibold"
                    />
                  )}
                </div>

                {/* Sous-menu Blood Pact: Rage */}
                {showBloodPactRage && bloodPactRage.length > 0 && (
                  <div className="bg-slate-900 rounded p-2 mb-2">
                    <div className="grid grid-cols-3 gap-1 max-h-48 overflow-y-auto">
                      {bloodPactRage.map((attack, idx) => (
                        <button
                          key={idx}
                          onClick={() => {
                            handlePetAttack(attack);
                            setShowBloodPactRage(false);
                          }}
                          className="bg-red-600 hover:bg-red-500 text-white px-2 py-1 rounded text-xs"
                        >
                          {attack.name}
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Sous-menu Blood Pact: Ward */}
                {showBloodPactWard && bloodPactWard.length > 0 && (
                  <div className="bg-slate-900 rounded p-2 mb-2">
                    <div className="grid grid-cols-3 gap-1 max-h-48 overflow-y-auto">
                      {bloodPactWard.map((attack, idx) => (
                        <button
                          key={idx}
                          onClick={() => {
                            handlePetAttack(attack);
                            setShowBloodPactWard(false);
                          }}
                          className="bg-blue-600 hover:bg-blue-500 text-white px-2 py-1 rounded text-xs"
                        >
                          {attack.name}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* 🆕 Ready moves BST et autres pet attacks (non-SMN) */}
            {!isSMN && otherPetAttacks.length > 0 && (
              <div>
                <h4 className="text-gray-300 text-sm font-semibold mb-2">
                  {altData.main_job === 'BST' ? 'Ready Moves' : 'Pet Attacks'}
                </h4>
                <div className="grid grid-cols-3 gap-2">
                  {otherPetAttacks.map((attack, idx) => (
                    <button
                      key={idx}
                      onClick={() => handlePetAttack(attack)}
                      className="bg-green-700 hover:bg-green-600 text-white px-2 py-2 rounded text-xs"
                    >
                      {attack.name}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {altData.pet_commands.length === 0 && activePetAttacks.length === 0 && (
              <p className="text-gray-400 text-center py-4 text-sm">
                Aucune commande de pet disponible
              </p>
            )}
          </div>
        )}

        {/* Macros List */}
        {showMacros && configuredMacros.length > 0 && (
          <div className="bg-slate-800 rounded-lg p-4 mb-4 border border-slate-600">
            <h3 className="text-white font-bold mb-3 text-lg">Macros</h3>
            <div className="grid grid-cols-1 gap-2">
              {configuredMacros.map((macro, idx) => (
                <button
                  key={idx}
                  onClick={() => handleMacro(macro)}
                  className="bg-slate-700 hover:bg-slate-600 text-white px-3 py-2 rounded transition-colors text-left text-sm"
                >
                  <div className="font-semibold">{macro.name}</div>
                  <div className="text-xs text-gray-400 mt-1 font-mono">{macro.command}</div>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* 🆕 CORRECTION: Target Selection for Party Spells */}
        {selectedSpellTarget.showTargets && selectedSpellTarget.spell && (
          <div className="bg-slate-800 rounded-lg p-4 mb-4 border border-green-500 shadow-2xl">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-white font-bold text-lg">
                Cible pour {selectedSpellTarget.spell.name}
              </h3>
              <button
                onClick={() => setSelectedSpellTarget({ spell: null, showTargets: false })}
                className="text-red-400 hover:text-red-300 font-bold text-2xl"
              >
                ✕
              </button>
            </div>
            <div className="grid grid-cols-2 gap-2">
              {/* 🆕 Bouton "All" pour SCH avec Accession */}
              {altData.main_job === 'SCH' && altData.party.length > 1 && selectedSpellTarget.spell && (
                (() => {
                  const spellName = selectedSpellTarget.spell.name || '';
                  
                  // Liste des sorts qui peuvent être castés avec Accession
                  const accessionSpells = [
                    'Cure', 'Cure II', 'Cure III', 'Cure IV',  // Heals
                    'Protect', 'Shell', 'Haste', 'Refresh', 'Regen',  // Buffs party
                    'Blink', 'Stoneskin', 'Aquaveil', 'Phalanx'  // Buffs self → party avec Accession
                  ];
                  
                  // Sorts self-only qui deviennent party avec Accession
                  const selfOnlyAccessionSpells = ['Blink', 'Stoneskin', 'Aquaveil', 'Phalanx', 'Refresh'];
                  const isSelfOnlyAccession = selfOnlyAccessionSpells.some(spell => spellName === spell || spellName.includes(spell));
                  
                  const isAccessionSpell = accessionSpells.some(spell => spellName === spell || spellName.includes(spell));
                  
                  return isAccessionSpell ? (
                    <button
                      onClick={() => handleSchAccessionCast(selectedSpellTarget.spell)}
                      className="col-span-2 bg-purple-700 hover:bg-purple-600 text-white px-3 py-3 rounded transition-colors text-center text-sm font-bold"
                    >
                      🎯 All (Accession + {selectedSpellTarget.spell.name})
                    </button>
                  ) : null;
                })()
              )}
              
              {/* 🆕 Pour les sorts self-only avec Accession, afficher seulement l'ALT */}
              {(() => {
                const spellName = selectedSpellTarget.spell.name || '';
                const selfOnlyAccessionSpells = ['Blink', 'Stoneskin', 'Aquaveil', 'Phalanx', 'Refresh'];
                const isSelfOnlyAccession = selfOnlyAccessionSpells.some(spell => spellName === spell || spellName.includes(spell));
                
                if (isSelfOnlyAccession && altData.main_job === 'SCH') {
                  // Afficher seulement le nom de l'ALT (pas toute la party)
                  return (
                    <button
                      onClick={() => handleSpellCast(selectedSpellTarget.spell, '<me>')}
                      className="col-span-2 bg-blue-700 hover:bg-blue-600 text-white px-3 py-2 rounded transition-colors text-center text-sm font-bold"
                    >
                      {altData.alt_name} (Self)
                    </button>
                  );
                }
                
                // Pour les autres sorts, afficher toute la party
                return altData.party.length > 0 ? (
                  altData.party.map((memberName, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSpellCast(selectedSpellTarget.spell, memberName)}
                      className="bg-green-700 hover:bg-green-600 text-white px-3 py-2 rounded transition-colors text-left text-sm"
                    >
                      <div className="font-semibold">{memberName}</div>
                    </button>
                  ))
                ) : (
                  <p className="col-span-2 text-gray-400 text-center py-4">
                    Aucun membre de party détecté
                  </p>
                );
              })()}
            </div>
          </div>
        )}

        {/* Teleport Locations */}
        {showTeleports && (
          <div className="bg-slate-800 rounded-lg p-4 mb-4 border border-slate-600">
            <h3 className="text-white font-bold mb-3 text-lg">Teleport</h3>
            <div className="grid grid-cols-3 gap-2">
              {teleportLocations.map((location) => (
                <button
                  key={location}
                  onClick={() => handleTeleport(location)}
                  className="bg-slate-700 hover:bg-slate-600 text-white px-3 py-2 rounded transition-colors text-sm font-semibold"
                >
                  {location}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* 📱 Fixed Directional Controls - Toujours visible en bas */}
      <div className="sticky bottom-0 bg-slate-800 rounded-t-lg p-3 border-t-2 border-slate-600 flex justify-center shadow-2xl">
        <DirectionalPad 
          onDirectionStart={handleDirectionStart}
          onDirectionEnd={handleDirectionEnd}
        />
      </div>
    </div>
  );
};

export default AltController;