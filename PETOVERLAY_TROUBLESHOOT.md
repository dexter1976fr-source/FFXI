# 🔧 AltPetOverlay - Troubleshooting

## 📋 Situation

Après le formatage automatique de Kiro, l'overlay ne s'affiche plus.

---

## ✅ Ce qui a été fait

### 1. Création d'une version minimale

**Fichier** : `AltPetOverlay_Minimal.lua`

Version simplifiée qui utilise uniquement `texts` (pas de `windower.prim`).

**Avantages** :
- Plus simple
- Plus fiable
- Facile à débugger

**Installation** :
```
A:\Jeux\PlayOnline\Windower4\addons\AltPetOverlay\AltPetOverlay_Minimal.lua
```

---

### 2. Vérification d'AltControl

Le fichier `AltControl.lua` a été recopié vers Windower pour s'assurer que les modifications sont bien présentes.

**Fonction ajoutée** : `broadcast_pet_to_overlay()`

---

### 3. Guides de dépannage

**Fichiers créés** :
- `DEBUG_PETOVERLAY.md` - Diagnostic complet
- `FIX_PETOVERLAY.md` - Solutions aux problèmes
- `TEST_RAPIDE_PETOVERLAY.md` - Test en 30 secondes

---

## 🎮 Test rapide

### Charger la version minimale

```lua
//lua reload AltControl
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
//po test
```

**Si ça marche** → Utiliser cette version pour l'instant

**Si ça ne marche pas** → Voir les guides de dépannage

---

## 🔍 Causes possibles du problème

### 1. windower.prim ne fonctionne pas

La version graphique utilise `windower.prim` pour dessiner les rectangles et barres.

**Solution** : Utiliser la version minimale (texte seulement)

---

### 2. Formatage a cassé le code

Le formatage automatique peut avoir modifié l'indentation ou la syntaxe.

**Solution** : Fichiers recopiés depuis le workspace

---

### 3. IPC ne fonctionne pas

La communication entre AltControl et AltPetOverlay peut être bloquée.

**Solution** : Recharger les deux addons

---

### 4. Position hors écran

L'overlay peut être positionné en dehors de l'écran.

**Solution** : `//po pos 100 500`

---

## 📊 Comparaison des versions

| Fonctionnalité | Graphique | Minimale |
|----------------|-----------|----------|
| Barres HP colorées | ✅ | ❌ |
| Fond transparent | ✅ | ✅ |
| Texte stylisé | ✅ | ✅ |
| Fiabilité | ⚠️ | ✅ |
| Simplicité | ❌ | ✅ |
| Performance | ✅ | ✅ |

---

## 🚀 Recommandation

**Pour l'instant** :
1. Utiliser `AltPetOverlay_Minimal` (version texte)
2. Tester que tout fonctionne
3. Si besoin, on pourra investiguer la version graphique plus tard

**Commandes** :
```lua
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
//po test
```

---

## 📝 Prochaines étapes

Une fois que la version minimale fonctionne :

1. ✅ Confirmer que l'IPC fonctionne
2. ✅ Tester avec de vrais pets
3. ⏳ Investiguer pourquoi la version graphique ne marche plus
4. ⏳ Corriger ou améliorer la version graphique

---

**Status** : En cours de dépannage  
**Version recommandée** : AltPetOverlay_Minimal  
**Date** : 23 novembre 2024
