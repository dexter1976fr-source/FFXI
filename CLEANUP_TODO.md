# Nettoyage du projet - TODO

## ✅ Complété

### DistanceFollow universel
- ✅ Supprimé les références à MageFastFollow dans AltControl.lua
- ✅ Supprimé la commande SCH-specific dfollow stop dans la webapp
- ✅ Simplifié la logique stopfollow (plus de code job-specific)

## 🔄 À faire plus tard

### SCH AutoCast / Heal system
**Statut:** Code existant mais incomplet, à refaire proprement

**Fichiers concernés:**
- `AutoCast_SCH.lua` (si existe)
- Logique de heal dans `handleSchAutocast()` (webapp)
- Backend SCH autocast dans `backendService.ts`

**Plan:**
1. Garder le code actuel en l'état (ne pas toucher pour l'instant)
2. Plus tard, créer un système de heal intelligent pour SCH
3. Utiliser DistanceFollow pour le positionnement
4. Implémenter la détection de HP party
5. Ajouter la logique Accession pour les heals AoE

**Raison du report:**
- DistanceFollow universel résout déjà le problème de positionnement
- Le système de heal nécessite une réflexion approfondie
- Mieux vaut le faire proprement plus tard que de patcher l'existant

### BRD AutoCast
**Statut:** Fonctionnel, à optimiser

**Améliorations possibles:**
- Refactoriser le système de queue
- Améliorer la détection des buffs manquants
- Optimiser le cycle de chansons

### Fichiers obsolètes à archiver

**Anciens fichiers de test/debug:**
```
AltPetOverlay_*.lua (sauf AltPetOverlay.lua final)
- AltPetOverlay_Clean.lua
- AltPetOverlay_Final_v2.lua
- AltPetOverlay_Working.lua
- AltPetOverlay_Images.lua
- AltPetOverlay_Hybrid.lua
- AltPetOverlay_Final.lua
- AltPetOverlay_XIVStyle.lua
- AltPetOverlay_Minimal.lua
- AltPetOverlay_Graphics.lua
- AltPetOverlay_Main.lua
- AltPetOverlay_Debug.lua
- AltPetOverlay_Simple.lua
```

**Anciens fichiers de documentation:**
```
PETOVERLAY_*.md (garder seulement le guide final)
- PETOVERLAY_TROUBLESHOOT.md
- FIX_PETOVERLAY.md
- TEST_PETOVERLAY.md
- docs/SESSION_PETOVERLAY_FINAL.md (garder)
- docs/PETOVERLAY_GUIDE.md (garder)
- docs/SESSION_PETOVERLAY_XIVSTYLE.md
- docs/PETOVERLAY_XIVSTYLE_PLAN.md
- docs/PETOVERLAY_INSTALLATION.md
```

**Anciens systèmes remplacés:**
```
MageFastFollow.lua (remplacé par DistanceFollow)
DistanceFollow.lua (ancien, remplacé par tools/DistanceFollow.lua)
```

**Action suggérée:**
Créer un dossier `archive/` et y déplacer ces fichiers

### Code mort à supprimer

**Dans AltController.tsx:**
- `handleAutoEngageToggle` (déclaré mais jamais utilisé)
- `isSelfOnlyAccession` (déclaré mais jamais utilisé)

**Dans AltControl.lua:**
- Vérifier s'il reste des références à l'ancien système de follow

### Documentation à mettre à jour

**Fichiers à réviser:**
- `README.md` - Ajouter DistanceFollow dans les features
- `docs/V2_ROADMAP.md` - Marquer DistanceFollow comme complété
- `ROADMAP_PROCHAINES_ETAPES.md` - Mettre à jour les priorités

### Tests à effectuer

**DistanceFollow:**
- ✅ Test basique (Follow ON/OFF)
- ✅ Test avec AutoEngage
- ✅ Test SMN (changement de target)
- ⏳ Test sur différents jobs (MNK, RNG, WHM, etc.)
- ⏳ Test avec plusieurs personnages simultanément
- ⏳ Test de performance (FPS avec 6 personnages)

**AutoCast BRD:**
- ⏳ Test cycle complet de chansons
- ⏳ Test debuffs sur mobs
- ⏳ Test avec différentes configurations

**AltPetOverlay:**
- ⏳ Test avec BST (Ready charges)
- ⏳ Test avec DRG (Breath timer)
- ⏳ Test avec plusieurs SMN

## 📋 Priorités

### Court terme (cette semaine)
1. ✅ Nettoyer le code SCH-specific follow
2. ⏳ Tester DistanceFollow sur tous les jobs
3. ⏳ Documenter les cas d'usage avancés

### Moyen terme (ce mois)
1. Archiver les fichiers obsolètes
2. Mettre à jour la documentation
3. Implémenter la configuration via admin panel (follow target)

### Long terme (plus tard)
1. Refaire le système SCH heal proprement
2. Optimiser AutoCast BRD
3. Ajouter des presets de distance par job
4. Créer un système de heal intelligent universel

## 🎯 Objectif

Avoir un codebase propre, maintenable et bien documenté avec :
- Moins de duplication
- Code modulaire et réutilisable
- Documentation à jour
- Tests validés
- Fichiers obsolètes archivés
