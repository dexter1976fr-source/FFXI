# 🗺️ AutoCast V2 - Roadmap de Développement

## 🎯 Vision

Créer un système d'automatisation **robuste, fiable et extensible** pour FFXI, inspiré de GearSwap mais focalisé sur les automatismes plutôt que le gear swapping.

---

## 📊 État Actuel (V1)

### ✅ Ce qui Fonctionne
- Web App React fonctionnelle
- Python bridge IPC
- Commandes manuelles instantanées
- AltControl.lua basique

### ❌ Ce qui Ne Fonctionne Pas
- Auto-buff BRD (50% échec)
- Timing instable
- Pas de validation des conditions
- Pas de gestion des edge cases
- Latence réseau problématique

### 📚 Ce qu'on a Appris
- GearSwap architecture
- Events Windower essentiels
- Conditions de validation
- Importance de la stabilité combat
- Queue de commandes nécessaire

---

## 🏗️ Phase 1 : Fondations (Core)

**Objectif:** Créer un core solide qui gère tous les états et events

### Tâches

1. **AutoCast_Core.lua**
   - [ ] Events listeners (status, buffs, action)
   - [ ] État global (player, combat, buffs)
   - [ ] Hooks pour jobs
   - [ ] IPC handling
   - [ ] Position tracking
   - [ ] Movement detection

2. **AutoCast_Queue.lua**
   - [ ] Queue avec priorités
   - [ ] Délai entre commandes
   - [ ] Validation avant exécution
   - [ ] Clear/Reset functions

3. **AutoCast_Validation.lua**
   - [ ] can_act()
   - [ ] can_cast_spell()
   - [ ] can_use_ability()
   - [ ] can_use_weaponskill()
   - [ ] can_engage()
   - [ ] Validation par type d'action

4. **AutoCast_Utils.lua**
   - [ ] Fonctions helper
   - [ ] Distance calculations
   - [ ] Target validation
   - [ ] Buff checking
   - [ ] Recast checking

### Tests Phase 1
- [ ] Core charge sans erreur
- [ ] Events détectés correctement
- [ ] État global mis à jour
- [ ] Queue fonctionne
- [ ] Validation bloque actions invalides

**Durée estimée:** 2-3 jours

---

## 🎭 Phase 2 : Premier Job (BRD)

**Objectif:** Implémenter BRD avec toutes les conditions

### Tâches

1. **AutoCast_BRD.lua**
   - [ ] Configuration songs
   - [ ] État BRD
   - [ ] Hooks (status_change, prerender)
   - [ ] Détection stabilité combat
   - [ ] Auto-songs logic
   - [ ] Gestion interruptions

2. **Conditions BRD Spécifiques**
   - [ ] Attendre premier coup
   - [ ] Attendre stabilité (2s)
   - [ ] Vérifier mouvement
   - [ ] Vérifier MP
   - [ ] Vérifier silence
   - [ ] Vérifier recast

3. **Cycle de Songs**
   - [ ] Rotation configurable
   - [ ] Délai entre songs
   - [ ] Reset au désengagement
   - [ ] Gestion Pianissimo
   - [ ] Gestion Nightingale

### Tests Phase 2
- [ ] Songs castent après stabilité
- [ ] Pas d'interruption
- [ ] Cycle complet fonctionne
- [ ] Reset propre au désengagement
- [ ] Fonctionne avec latence réseau

**Durée estimée:** 2-3 jours

---

## 🩹 Phase 3 : Deuxième Job (WHM)

**Objectif:** Valider l'architecture avec un job différent

### Tâches

1. **AutoCast_WHM.lua**
   - [ ] Configuration heals
   - [ ] État WHM
   - [ ] Auto-heal logic
   - [ ] Target selection (party)
   - [ ] Cure tier selection
   - [ ] Regen/Protect/Shell

2. **Conditions WHM Spécifiques**
   - [ ] Find heal target
   - [ ] HP threshold
   - [ ] Distance check
   - [ ] MP management
   - [ ] Priority healing

### Tests Phase 3
- [ ] Détecte party members
- [ ] Heal le plus bas HP
- [ ] Sélectionne bon tier de Cure
- [ ] Gère MP correctement
- [ ] Pas de spam heal

**Durée estimée:** 2 jours

---

## 🐾 Phase 4 : Jobs avec Pet (BST/SMN)

**Objectif:** Gérer les jobs avec pets

### Tâches

1. **AutoCast_BST.lua**
   - [ ] Configuration pet
   - [ ] Auto-reward
   - [ ] Auto-ready
   - [ ] Pet HP tracking
   - [ ] Pet TP tracking
   - [ ] Ready move selection

2. **AutoCast_SMN.lua**
   - [ ] Avatar management
   - [ ] Auto-blood pact
   - [ ] MP management (perpetuation)
   - [ ] BP rotation
   - [ ] Avatar HP tracking

### Tests Phase 4
- [ ] Pet détecté correctement
- [ ] Reward au bon moment
- [ ] Ready moves appropriés
- [ ] Avatar maintenu
- [ ] BP utilisés intelligemment

**Durée estimée:** 3 jours

---

## 🎲 Phase 5 : Jobs Complexes (GEO/COR)

**Objectif:** Gérer les mécaniques complexes

### Tâches

1. **AutoCast_GEO.lua**
   - [ ] Indi-spell management
   - [ ] Geo-spell management
   - [ ] Bubble tracking
   - [ ] Entrust logic
   - [ ] Luopan HP tracking

2. **AutoCast_COR.lua**
   - [ ] Roll management
   - [ ] Lucky number detection
   - [ ] Bust detection
   - [ ] Quick Draw
   - [ ] Phantom Roll rotation

### Tests Phase 5
- [ ] Bubbles maintenues
- [ ] Rolls optimisés
- [ ] Bust évité
- [ ] Entrust fonctionne

**Durée estimée:** 3-4 jours

---

## 🎮 Phase 6 : Jobs DD (WAR/SAM/DRK)

**Objectif:** Auto-engage et auto-WS

### Tâches

1. **Auto-Engage Logic**
   - [ ] Find nearest enemy
   - [ ] Distance check
   - [ ] Claim check
   - [ ] Auto-attack

2. **Auto-WS Logic**
   - [ ] TP threshold
   - [ ] WS selection
   - [ ] Target validation
   - [ ] Distance check

3. **Job-Specific**
   - [ ] WAR: Berserk, Warcry
   - [ ] SAM: Hasso, Meditate
   - [ ] DRK: Last Resort, Souleater

### Tests Phase 6
- [ ] Engage automatique
- [ ] WS au bon moment
- [ ] Abilities utilisées
- [ ] Pas d'engage sur claimed

**Durée estimée:** 3 jours

---

## 🛡️ Phase 7 : Jobs Tank (PLD/RUN)

**Objectif:** Auto-tank et defensive

### Tâches

1. **AutoCast_PLD.lua**
   - [ ] Flash sur aggro
   - [ ] Sentinel si HP bas
   - [ ] Cure self
   - [ ] Provoke rotation

2. **AutoCast_RUN.lua**
   - [ ] Rune management
   - [ ] Ward rotation
   - [ ] Vallation/Valiance
   - [ ] Element selection

### Tests Phase 7
- [ ] Flash sur aggro détecté
- [ ] Defensive abilities utilisées
- [ ] Runes maintenues
- [ ] Self-heal fonctionne

**Durée estimée:** 3 jours

---

## 🌐 Phase 8 : Web App V2

**Objectif:** Interface améliorée

### Tâches

1. **UI Améliorée**
   - [ ] Status display (états en temps réel)
   - [ ] Mode toggles (ON/OFF visuels)
   - [ ] Queue display (voir commandes en attente)
   - [ ] Logs display (historique actions)

2. **Configuration**
   - [ ] Job-specific settings
   - [ ] Song rotation editor (BRD)
   - [ ] Heal thresholds (WHM)
   - [ ] Roll preferences (COR)

3. **Monitoring**
   - [ ] HP/MP bars
   - [ ] Buff icons
   - [ ] Pet status
   - [ ] Recast timers

### Tests Phase 8
- [ ] UI responsive
- [ ] États mis à jour en temps réel
- [ ] Configuration sauvegardée
- [ ] Fonctionne sur tablette

**Durée estimée:** 4-5 jours

---

## 🔧 Phase 9 : Optimisation & Polish

**Objectif:** Peaufiner et optimiser

### Tâches

1. **Performance**
   - [ ] Optimiser prerender
   - [ ] Réduire overhead
   - [ ] Cache calculations
   - [ ] Profiling

2. **Robustesse**
   - [ ] Error handling
   - [ ] Fallback logic
   - [ ] Recovery mechanisms
   - [ ] Logging amélioré

3. **Documentation**
   - [ ] User guide
   - [ ] Configuration guide
   - [ ] Troubleshooting
   - [ ] API documentation

### Tests Phase 9
- [ ] Pas de lag
- [ ] Pas de crash
- [ ] Erreurs gérées proprement
- [ ] Documentation complète

**Durée estimée:** 3 jours

---

## 📦 Phase 10 : Release

**Objectif:** Préparer la release publique

### Tâches

1. **Packaging**
   - [ ] Installer script
   - [ ] Default configs
   - [ ] README
   - [ ] LICENSE

2. **Testing Final**
   - [ ] Test tous les jobs
   - [ ] Test multi-character
   - [ ] Test latence réseau
   - [ ] Test edge cases

3. **Release**
   - [ ] GitHub release
   - [ ] Documentation site
   - [ ] Video demo
   - [ ] Community announcement

**Durée estimée:** 2 jours

---

## 📅 Timeline Estimée

| Phase | Durée | Cumul |
|-------|-------|-------|
| Phase 1: Core | 3 jours | 3 jours |
| Phase 2: BRD | 3 jours | 6 jours |
| Phase 3: WHM | 2 jours | 8 jours |
| Phase 4: BST/SMN | 3 jours | 11 jours |
| Phase 5: GEO/COR | 4 jours | 15 jours |
| Phase 6: DD Jobs | 3 jours | 18 jours |
| Phase 7: Tank Jobs | 3 jours | 21 jours |
| Phase 8: Web App V2 | 5 jours | 26 jours |
| Phase 9: Polish | 3 jours | 29 jours |
| Phase 10: Release | 2 jours | 31 jours |

**Total: ~1 mois de développement**

---

## 🎯 Priorités

### Must Have (V2.0)
- ✅ Core solide
- ✅ BRD fonctionnel
- ✅ WHM fonctionnel
- ✅ Validation complète
- ✅ Queue robuste

### Should Have (V2.1)
- ✅ BST/SMN
- ✅ GEO/COR
- ✅ Web App améliorée

### Nice to Have (V2.2+)
- ✅ DD Jobs
- ✅ Tank Jobs
- ✅ Advanced features

---

## 🚀 Prochaines Étapes Immédiates

1. **Finir la documentation** (en cours)
   - [x] V2_CONDITIONS_VALIDATION.md
   - [x] V2_ARCHITECTURE_COMPLETE.md
   - [x] V2_ROADMAP.md
   - [ ] V2_IMPLEMENTATION_GUIDE.md

2. **Repos et réflexion** 🎂
   - Profiter de ton anniversaire !
   - Laisser les idées maturer
   - Revenir avec l'esprit frais

3. **Commencer Phase 1**
   - Créer AutoCast_Core.lua
   - Implémenter events listeners
   - Tester état global

---

## 💡 Notes Importantes

### Ce qu'on a Appris de V1
- ❌ Ne pas gérer la logique en Python/React
- ❌ Ne pas caster sans vérifier les conditions
- ❌ Ne pas ignorer la latence réseau
- ✅ Tout doit être en Lua
- ✅ Validation est critique
- ✅ Queue est nécessaire
- ✅ GearSwap a raison sur tout

### Principes de V2
1. **Robustesse avant features**
2. **Validation avant exécution**
3. **Un job à la fois**
4. **Tester chaque edge case**
5. **Documentation continue**

---

**Date:** 22 novembre 2024  
**Version:** 2.0 - Roadmap complète  
**Status:** Planification  
**Prochaine session:** Quand tu seras prêt ! 🎉
