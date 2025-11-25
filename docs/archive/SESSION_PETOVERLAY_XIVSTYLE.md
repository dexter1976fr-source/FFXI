# 🎨 Session : AltPetOverlay Style XIVParty

## 📅 Date : 23 novembre 2024 - 11h

## 🎯 Objectif

Créer AltPetOverlay avec le **vrai style graphique XIVParty** pour cohésion visuelle.

---

## ✅ Ce qu'on a Déjà

1. ✅ XIVParty copié dans `AltPetOverlay/`
2. ✅ Assets (images) copiés
3. ✅ Version texte fonctionnelle
4. ✅ IPC fonctionne
5. ✅ Données de test s'affichent

---

## 🔧 Ce qu'on va Faire

### Étape 1 : Utiliser les UI Components XIVParty

Fichiers à utiliser :
- `uiElement.lua` - Classe de base
- `uiImage.lua` - Pour afficher images
- `uiBar.lua` - Pour les barres HP
- `uiText.lua` - Pour le texte
- `uiContainer.lua` - Pour grouper les éléments

### Étape 2 : Créer PetListItem Component

Un composant qui affiche UN pet avec :
- Background XIVParty
- Barre HP graphique
- Texte stylisé
- Charges/Timer

### Étape 3 : Créer le Main avec UI

Remplacer le `texts.new()` par des vrais composants graphiques.

---

## 📝 Notes de Session

**11h00** - Début session
**11h05** - XIVParty copié
**11h10** - Version texte fonctionnelle
**11h15** - Décision : Style XIVParty complet
**11h20** - Début implémentation style graphique...

---

## 🚀 Prochaines Étapes

1. Créer `petListItem.lua`
2. Modifier `AltPetOverlay.lua` pour utiliser UI components
3. Tester avec `//po test`
4. Ajuster positions/couleurs
5. Polish final

---

**Status:** En cours...
