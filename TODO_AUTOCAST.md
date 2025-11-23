# 📋 TODO AutoCast

## ✅ Phase 1: Fondations (TERMINÉ)

- [x] Créer AutoCast.lua (module principal)
- [x] Créer AutoCast_BRD.lua (logique BRD)
- [x] Intégrer dans AltControl.lua
- [x] Ajouter bouton dans WebApp
- [x] Déploiement automatique
- [x] Documentation complète

---

## 🔄 Phase 2: Tests et Ajustements (EN COURS)

### Tests à Effectuer

- [ ] Test 1: Chargement des modules
- [ ] Test 2: Positionnement vers healer
- [ ] Test 3: Pause pendant cast
- [ ] Test 4: Retour après cast
- [ ] Test 5: Bouton WebApp ON/OFF
- [ ] Test 6: Logs dans FFXI
- [ ] Test 7: Logs dans console web

### Ajustements Possibles

- [ ] Affiner les distances (home: 12-18y, melee: 3-7y, mob: 15-20y)
- [ ] Ajuster le cooldown global (actuellement 3s)
- [ ] Optimiser la fréquence d'update (actuellement 0.1s = 10 FPS)
- [ ] Améliorer la détection du healer (fallback sur p1 si pas de healer)

---

## 🎵 Phase 3: BRD Avancé

### Détection des Buffs Actifs

- [ ] Parser `active_buffs` pour détecter les chansons
- [ ] Mapper les buff IDs vers les noms de chansons
- [ ] Compter le nombre de chansons actives
- [ ] Afficher dans l'interface: "2/4 chansons actives"

### Rotation de Chansons

- [ ] Vérifier si une chanson prioritaire est manquante
- [ ] Calculer la durée restante (timestamp + durée - now)
- [ ] Refresh 30 secondes avant expiration
- [ ] Gérer le nombre max de chansons (2-4 selon équipement)

### Overwrite Intelligent

- [ ] Ne jamais écraser une chanson plus importante
- [ ] Système de priorités configurables
- [ ] Alertes si tentative d'overwrite

### Debuffs Automatiques

- [ ] Détecter nouveau mob engagé
- [ ] Vérifier si Elegy déjà actif
- [ ] Lancer Elegy si pas actif
- [ ] Priorité: Boss > Adds

### Job Abilities

- [ ] Soul Voice (boost massif des chansons)
- [ ] Nightingale (réduit recast)
- [ ] Pianissimo (chant sur 1 seul membre)
- [ ] Troubadour (augmente durée)

---

## 🎛️ Phase 4: Configuration Avancée

### Panel AutoCastConfig dans WebApp

- [ ] Créer composant `AutoCastConfig.tsx`
- [ ] Sliders pour les distances (min/max)
- [ ] Liste des chansons prioritaires avec drag & drop
- [ ] Toggle auto_songs / auto_movement
- [ ] Sélection du home_role (healer/tank/ranged)
- [ ] Bouton "Save Config"

### Backend Python

- [ ] Route `/autocast-config` GET
- [ ] Route `/autocast-config` POST
- [ ] Sauvegarde dans `data_json/autocast_configs.json`
- [ ] Format: `{altName}_{mainJob}_{subJob}`

### Chargement de la Config

- [ ] Charger depuis le serveur au démarrage
- [ ] Envoyer au Lua via `start_autocast(config_json)`
- [ ] Recharger si changement de job

---

## 🏥 Phase 5: WHM (White Mage)

### Auto Heal

- [ ] Créer `AutoCast_WHM.lua`
- [ ] Détecter HP% de chaque membre de party
- [ ] Cure I/II/III/IV selon HP manquant
- [ ] Priorités: Tank > Healer > DD
- [ ] Threshold configurable (ex: Cure si HP < 70%)

### Auto Raise

- [ ] Détecter membre mort (status = 2 ou 3)
- [ ] Vérifier si Reraise actif
- [ ] Lancer Raise/Raise II/Raise III
- [ ] Priorité: Healer > Tank > DD

### Auto Regen/Refresh

- [ ] Vérifier si Regen actif sur chaque membre
- [ ] Refresh avant expiration
- [ ] Priorité: Tank > Healer

### Auto Status Removal

- [ ] Détecter status négatifs (Poison, Paralyze, etc.)
- [ ] Lancer -na approprié (Poisona, Paralyna, etc.)

---

## 🔴 Phase 6: RDM (Red Mage)

### Refresh Rotation

- [ ] Créer `AutoCast_RDM.lua`
- [ ] Vérifier MP% de chaque membre
- [ ] Lancer Refresh sur les mages (BLM, WHM, SCH, etc.)
- [ ] Rotation intelligente (pas tous en même temps)

### Haste sur Mêlée

- [ ] Détecter les jobs mêlée
- [ ] Vérifier si Haste actif
- [ ] Refresh avant expiration
- [ ] Priorité: Tank > DD

### Cure Backup

- [ ] Si WHM mort ou absent
- [ ] Cure I/II/III selon HP manquant
- [ ] Threshold plus bas que WHM (ex: 50%)

### Debuffs Intelligents

- [ ] Slow sur boss
- [ ] Paralyze sur adds
- [ ] Blind sur mêlée ennemis

---

## 🎓 Phase 7: SCH (Scholar)

### Arts Management

- [ ] Créer `AutoCast_SCH.lua`
- [ ] Détecter le mode actuel (Light/Dark/None)
- [ ] Switcher selon la situation:
  - Light Arts si besoin de heal/buff
  - Dark Arts si besoin de nuke/debuff

### Accession Buffs

- [ ] Détecter si plusieurs membres ont besoin du même buff
- [ ] Lancer Light Arts + Accession + Buff
- [ ] Buffs concernés: Protect, Shell, Haste, Regen, etc.

### Helix Rotation

- [ ] Lancer Helix sur le mob
- [ ] Rotation des éléments selon résistances
- [ ] Refresh avant expiration

### Stratagem Usage

- [ ] Rapture (boost heal)
- [ ] Ebullience (boost nuke)
- [ ] Immanence (instant cast)

---

## 🌍 Phase 8: GEO (Geomancer)

### Bubble Management

- [ ] Créer `AutoCast_GEO.lua`
- [ ] Indi-Fury (ATK boost) sur soi
- [ ] Geo-Frailty (DEF down) sur mob
- [ ] Refresh avant expiration

### Entrust

- [ ] Détecter si Entrust disponible
- [ ] Lancer Indi sur un autre membre
- [ ] Priorité: Tank ou DD principal

---

## 🎲 Phase 9: COR (Corsair)

### Roll Management

- [ ] Créer `AutoCast_COR.lua`
- [ ] Lancer 2 rolls prioritaires
- [ ] Vérifier les lucky numbers
- [ ] Re-roll si unlucky

### Quick Draw

- [ ] Lancer Quick Draw sur mob
- [ ] Rotation des éléments

---

## 🎯 Phase 10: Système de Profils

### Profils par Situation

- [ ] Profil "XP" (focus buffs, pas de debuffs)
- [ ] Profil "Boss" (focus debuffs, heals prioritaires)
- [ ] Profil "Tank" (focus tank, moins sur DD)
- [ ] Profil "DD" (focus DD, moins sur tank)

### Switch Automatique

- [ ] Détecter le type de combat
- [ ] Switcher de profil automatiquement
- [ ] Ou switch manuel depuis la WebApp

---

## 🔧 Phase 11: Optimisations

### Performance

- [ ] Réduire la fréquence d'update si pas en combat
- [ ] Cache des positions de party
- [ ] Optimiser les calculs de distance

### Logs

- [ ] Niveaux de log (DEBUG, INFO, WARN, ERROR)
- [ ] Toggle logs depuis la WebApp
- [ ] Logs dans un fichier

### Sécurité

- [ ] Vérifier que le sort est disponible avant de caster
- [ ] Vérifier le MP/TP suffisant
- [ ] Vérifier la portée du sort
- [ ] Éviter le spam de casts

---

## 📊 Priorités

### Court Terme (cette semaine)
1. ✅ Tester Phase 1 (fondations)
2. 🔄 Ajuster distances et cooldowns
3. 🔄 Implémenter détection buffs actifs
4. 🔄 Rotation de chansons BRD

### Moyen Terme (ce mois)
1. Panel de configuration dans WebApp
2. WHM Auto Heal
3. RDM Refresh rotation
4. SCH Arts management

### Long Terme (futur)
1. Tous les jobs supportés
2. Système de profils
3. IA avancée (apprentissage des patterns)
4. Multi-ALT coordination

---

**Dernière mise à jour:** 18 novembre 2025  
**Version:** 1.0.0  
**Status:** Phase 1 terminée, Phase 2 en cours
