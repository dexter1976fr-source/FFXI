# 🐾 AltPetOverlay - Récapitulatif

## ✅ Finalisé

**AltPetOverlay** est un addon Windower qui affiche les infos des pets en temps réel avec un style graphique.

---

## 🚀 Utilisation rapide

```lua
// In-game
//lua load AltControl
//lua load AltPetOverlay

// Tester
//po test

// Ajuster position
//po pos 100 500

// Nettoyer
//po clear
```

---

## 📁 Fichiers

### Workspace
- `AltPetOverlay_Graphics.lua` - Code source
- `AltControl.lua` - Modifié pour broadcast pet data
- `docs/PETOVERLAY_GUIDE.md` - Guide complet
- `TEST_PETOVERLAY.md` - Procédure de test

### Windower (installé)
- `A:\Jeux\PlayOnline\Windower4\addons\AltPetOverlay\AltPetOverlay.lua`
- `A:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua`

---

## 🎨 Fonctionnalités

- ✅ Barres HP colorées (vert/jaune/orange/rouge)
- ✅ Support BST (charges Ready)
- ✅ Support SMN (timer Blood Pact)
- ✅ Support DRG (status Healing Breath)
- ✅ Communication IPC temps réel
- ✅ Nettoyage automatique
- ✅ Position ajustable

---

## 📊 Architecture

```
AltControl → IPC → AltPetOverlay → Affichage graphique
```

---

**Status** : ✅ Prêt à utiliser  
**Version** : 1.0.0-graphics  
**Date** : 23 novembre 2024
