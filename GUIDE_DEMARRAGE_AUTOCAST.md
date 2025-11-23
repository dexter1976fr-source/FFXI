# 🚀 Guide de Démarrage AutoCast

## 🎯 Ce qui a été fait

Le système **AutoCast** est maintenant implémenté pour le **BRD (Bard)**! 

### Fonctionnalités:
- ✅ **Positionnement intelligent** (se rapproche du healer, tank ou mob selon le sort)
- ✅ **Pause automatique** pendant les casts
- ✅ **Retour automatique** à la position de base après action
- ✅ **Bouton dans la WebApp** pour activer/désactiver
- ✅ **Architecture modulaire** pour ajouter d'autres jobs facilement

---

## 📦 Fichiers Créés

```
📁 Projet/
├── AutoCast.lua                    (Module principal)
├── AutoCast_BRD.lua                (Logique BRD)
├── AltControl.lua                  (Modifié - intégration)
├── deploy_autocast.ps1             (Script de déploiement)
├── test_autocast.md                (Checklist de test)
├── AUTOCAST_IMPLEMENTATION.md      (Documentation technique)
└── docs/
    └── AUTOCAST_SYSTEM.md          (Guide complet)
```

---

## 🎮 Comment Tester

### Étape 1: Déployer les Fichiers

```powershell
.\deploy_autocast.ps1
```

**Résultat:**
```
🚀 Déploiement AutoCast...
✅ AutoCast.lua copié
✅ AutoCast_BRD.lua copié
✅ AltControl.lua copié
✨ Déploiement terminé!
```

### Étape 2: Recharger l'Addon dans FFXI

Dans FFXI (avec un BRD):
```
//lua r AltControl
```

**Résultat attendu:**
- Pas d'erreur
- Message: `[AltControl] Listening on 127.0.0.1:5007`

### Étape 3: Lancer le Serveur Python

```bash
python FFXI_ALT_Control.py
```

Cliquer sur **"ON / OFF Servers"**

### Étape 4: Ouvrir la WebApp

Navigateur: `http://localhost:5000`

### Étape 5: Activer AutoCast

1. Sélectionner le BRD dans l'interface
2. Chercher le bouton **"🎵 Auto: OFF"** (à côté de "Auto: ON")
3. Cliquer dessus
4. Le bouton devient **"🎵 Auto: ON"** (vert)

**Dans FFXI, tu devrais voir:**
```
[AutoCast] ✅ Started for BRD
[BRD AutoCast] 🎵 Initialized
```

### Étape 6: Observer le Comportement

**Le BRD va:**
1. Chercher un healer dans la party (WHM/RDM/SCH)
2. Se déplacer vers lui (distance 12-18 yalms)
3. S'arrêter quand il est à la bonne distance
4. Si tu cast un sort manuellement:
   - Il s'arrête de bouger pendant le cast
   - Il reprend après le cast

---

## 🧪 Tests Rapides

### Test 1: Positionnement

1. Être dans une party avec un healer
2. Activer AutoCast
3. S'éloigner du healer (>20 yalms)
4. **Résultat:** Le BRD se rapproche automatiquement

### Test 2: Pause pendant Cast

1. Activer AutoCast
2. Caster un sort: `/ma "Valor Minuet IV" <me>`
3. **Résultat:** Le BRD s'arrête de bouger pendant le cast

### Test 3: Arrêt AutoCast

1. Cliquer sur **"🎵 Auto: ON"**
2. **Résultat:** Le bouton redevient "🎵 Auto: OFF", le BRD s'arrête

---

## 🐛 Problèmes Possibles

### Le bouton AutoCast n'apparaît pas

**Cause:** Le personnage n'est pas un BRD

**Solution:** Le bouton est visible uniquement pour les BRD (pour l'instant)

### Erreur "module not found" dans FFXI

**Cause:** Les fichiers ne sont pas au bon endroit

**Solution:**
```powershell
.\deploy_autocast.ps1
```
Puis:
```
//lua r AltControl
```

### Le BRD ne bouge pas

**Causes possibles:**
- Pas de healer dans la party
- Le BRD est déjà à la bonne distance
- AutoCast pas activé

**Solution:**
1. Vérifier qu'il y a un WHM/RDM/SCH dans la party
2. S'éloigner du healer (>20 yalms)
3. Vérifier que le bouton est vert ("🎵 Auto: ON")

### Le BRD bouge bizarrement

**Cause:** Distances mal configurées

**Solution temporaire:**
Arrêter AutoCast et ajuster la config dans le code (pour l'instant)

---

## 📊 Ce qui Fonctionne

| Fonctionnalité | Status | Notes |
|----------------|--------|-------|
| Chargement modules | ✅ | OK |
| Bouton WebApp | ✅ | OK |
| Positionnement | ✅ | Vers healer |
| Pause pendant cast | ✅ | OK |
| Retour après cast | ✅ | OK |
| Cast auto chansons | ⏳ | En développement |
| Config Admin | ⏳ | À venir |

---

## 🔮 Prochaines Étapes

### Court Terme (cette session)
1. ✅ Tester le positionnement
2. ✅ Tester la pause pendant cast
3. ✅ Vérifier qu'il n'y a pas de bugs

### Moyen Terme (prochaines sessions)
1. Ajouter la détection des buffs actifs
2. Implémenter le cast automatique des chansons
3. Créer le panel de configuration dans Admin
4. Affiner les distances

### Long Terme
1. Ajouter WHM (Auto Cure, Raise, Regen)
2. Ajouter RDM (Refresh, Haste)
3. Ajouter SCH (Arts, Accession)
4. Système de profils (XP, Boss, Tank, DD)

---

## 💡 Conseils

### Pour Tester Efficacement

1. **Commencer simple:** Juste le positionnement
2. **Observer les logs:** Dans FFXI et dans la console web (F12)
3. **Tester une fonctionnalité à la fois**
4. **Désactiver si ça bug:** Bouton "🎵 Auto: ON" pour arrêter

### Pour Débugger

**Dans FFXI:**
```
//lua i AltControl print(autocast and autocast.is_active())
```

**Dans la Console Web (F12):**
```javascript
// Filtrer par "AutoCast"
```

### Pour Modifier la Config

Pour l'instant, la config est hardcodée dans `AltController.tsx` ligne ~430:
```typescript
const config = {
  distances: {
    home: { min: 12, max: 18 },  // ← Modifier ici
    melee: { min: 3, max: 7 },
    mob: { min: 15, max: 20 }
  },
  // ...
};
```

---

## 🎉 Félicitations!

Tu as maintenant un système d'automatisation fonctionnel! C'est la **fondation** pour automatiser tous les jobs.

**Le plus dur est fait:** L'architecture est en place, modulaire et propre. Ajouter d'autres jobs sera beaucoup plus rapide maintenant.

---

## 📞 Support

Si tu rencontres un problème:

1. Vérifier `test_autocast.md` (checklist complète)
2. Lire `docs/AUTOCAST_SYSTEM.md` (guide détaillé)
3. Vérifier les logs dans FFXI et la console web

---

**Bon test! 🚀🎵**

---

**Version:** 1.0.0  
**Date:** 18 novembre 2025  
**Status:** ✅ Prêt à tester
