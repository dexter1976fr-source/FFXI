# 🚀 START HERE - FFXI Alt Control

## 🧹 PROJET NETTOYÉ - 25 NOV 2025

Le projet a été **complètement nettoyé** ! 
- ✅ 101 fichiers supprimés
- ✅ Structure claire et logique
- ✅ Un seul système BRD (SongService)
- ✅ Documentation à jour

---

## 📚 NAVIGATION RAPIDE

### 🎯 Nouveau sur le projet ?
→ **[GUIDE_DEMARRAGE_RAPIDE.md](GUIDE_DEMARRAGE_RAPIDE.md)** - Démarrage en 5 minutes

### 📖 Voir toute la documentation
→ **[INDEX_DOCUMENTATION.md](INDEX_DOCUMENTATION.md)** - Index complet

### 🧹 Comprendre le nettoyage
→ **[NETTOYAGE_COMPLET_25NOV.md](NETTOYAGE_COMPLET_25NOV.md)** - Détails du nettoyage
→ **[AVANT_APRES_NETTOYAGE.md](AVANT_APRES_NETTOYAGE.md)** - Comparaison visuelle

### 🎵 Système BRD
→ **[SONGSERVICE_TEST_GUIDE.md](SONGSERVICE_TEST_GUIDE.md)** - Guide complet SongService

### ✅ Tester le projet
→ **[TEST_APRES_NETTOYAGE.md](TEST_APRES_NETTOYAGE.md)** - Tests de validation

---

## ⚡ DÉMARRAGE ULTRA-RAPIDE

### 1. Lancer le serveur Python
```bash
python FFXI_ALT_Control.py
```

### 2. Dans FFXI, charger l'addon
```
//lua load altcontrol
```

### 3. Tester SongService
```
//ac songservice status
//ac songservice start
```

---

## 📁 STRUCTURE DU PROJET

```
FFXI_ALT_Control/
├── AltControl.lua              # Core
├── AltControlExtended.lua      # Extended
├── AutoCast.lua                # Loader
├── tools/
│   ├── SongService.lua         # BRD system ⭐
│   ├── AltPetOverlay.lua       # Pet overlay
│   ├── DistanceFollow.lua      # Follow
│   ├── PartyBuffs.lua          # Buffs
│   └── AutoEngage.lua          # Engage
├── data_json/
│   └── autocast_config.json    # Config
└── archive/                    # Backups
```

---

## 🎯 FICHIERS ESSENTIELS

- **3 fichiers Lua core** (AltControl, Extended, AutoCast)
- **5 fichiers tools** (SongService, Overlay, Follow, Buffs, Engage)
- **13 fichiers documentation** (guides, tests, architecture)
- **4 scripts Python** (serveur, fixes SCH)

**Total : ~25 fichiers essentiels** (vs 120+ avant nettoyage)

---

## ✅ AVANTAGES DU NETTOYAGE

- ✅ **Plus de conflits** - Un seul système BRD
- ✅ **Code maintenable** - Structure claire
- ✅ **Moins de bugs** - Pas de doublons
- ✅ **Navigation facile** - Documentation organisée
- ✅ **Backups sécurisés** - Tout archivé

---

## 🆘 BESOIN D'AIDE ?

1. **Documentation complète** : [INDEX_DOCUMENTATION.md](INDEX_DOCUMENTATION.md)
2. **Guide rapide** : [GUIDE_DEMARRAGE_RAPIDE.md](GUIDE_DEMARRAGE_RAPIDE.md)
3. **Tests** : [TEST_APRES_NETTOYAGE.md](TEST_APRES_NETTOYAGE.md)
4. **Architecture** : [REFACTORING_ARCHITECTURE.md](REFACTORING_ARCHITECTURE.md)

---

## 🎉 PRÊT À DÉVELOPPER !

**Le projet est maintenant propre, organisé et prêt pour le développement ! ✨**

---

**Version:** 2.0.0 (Après nettoyage)
**Date:** 25 novembre 2025  
**Status:** ✅ Nettoyé et testé
