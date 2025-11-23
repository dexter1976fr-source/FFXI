# 🧪 Test AltPetOverlay - Procédure Rapide

## 🎯 Objectif

Tester que l'overlay fonctionne correctement in-game.

---

## 📋 Checklist de test

### 1. Charger les addons

```lua
//lua load AltControl
//lua load AltPetOverlay
```

**Résultat attendu** :
```
[AltControl] Loaded
[AltPetOverlay] Graphics version loaded
[AltPetOverlay] Type //po test
```

---

### 2. Tester avec données de test

```lua
//po test
```

**Résultat attendu** :
- Deux pets s'affichent à l'écran
- Barres HP colorées visibles
- Texte lisible (noms, HP, charges/timer)

**Exemple d'affichage** :
```
Dexterbrown → BlackbeardRandy
████████████░░░░░░░░ 650/1000
Ready: ●●●○○ (3/5)

Summoner → Ifrit
████████████████░░░░ 800/1000
BP: 2.5s
```

---

### 3. Ajuster la position

```lua
//po pos 100 500
```

**Résultat attendu** :
```
[PetOverlay] Position: 100, 500
```

L'overlay se déplace à la nouvelle position.

---

### 4. Nettoyer l'affichage

```lua
//po clear
```

**Résultat attendu** :
```
[PetOverlay] Cleared
```

Les pets de test disparaissent.

---

### 5. Tester avec un vrai pet

**Pour BST** :
```lua
//ja "Call Beast" <me>
```

**Pour SMN** :
```lua
//ma "Carbuncle" <me>
```

**Pour DRG** :
```lua
//ja "Call Wyvern" <me>
```

**Résultat attendu** :
- Le pet s'affiche automatiquement dans l'overlay
- Les données se mettent à jour en temps réel
- La barre HP change de couleur selon le HP%

---

### 6. Tester les charges Ready (BST uniquement)

```lua
//ja "Ready" <t>
```

**Résultat attendu** :
- Le nombre de charges diminue après chaque utilisation
- Les cercles changent : ●●●○○ → ●●○○○

---

### 7. Tester le timer Blood Pact (SMN uniquement)

```lua
//pet "Assault" <t>
```

**Résultat attendu** :
- Le timer BP s'affiche : "BP: 60.0s"
- Le timer diminue progressivement
- Quand il atteint 0 : "BP Ready" en vert

---

## 🐛 Problèmes courants

### L'overlay ne s'affiche pas

**Solution 1** : Vérifier que l'addon est chargé
```lua
//lua list
```

**Solution 2** : Recharger l'addon
```lua
//lua reload AltPetOverlay
```

**Solution 3** : Vérifier la position
```lua
//po pos 100 500
```

---

### Les données ne se mettent pas à jour

**Solution 1** : Recharger AltControl
```lua
//lua reload AltControl
```

**Solution 2** : Vérifier qu'AltControl envoie les données
```lua
//lua reload AltControl
//lua reload AltPetOverlay
```

**Solution 3** : Attendre 1-2 secondes (délai de mise à jour)

---

### Les barres HP ne s'affichent pas

**Cause** : Problème avec `windower.prim`

**Solution** : Vérifier la version de Windower (doit être récente)

---

### Les couleurs sont bizarres

**Cause** : Problème de calcul du HP%

**Solution** : Vérifier que le pet a bien du HP (pas mort)

---

## ✅ Validation finale

Si tous les tests passent :

- ✅ L'overlay s'affiche correctement
- ✅ Les données se mettent à jour en temps réel
- ✅ Les barres HP sont colorées correctement
- ✅ Les infos job-spécifiques s'affichent (charges/timer)
- ✅ La position est ajustable
- ✅ Le nettoyage fonctionne

**→ L'addon est prêt à utiliser !**

---

## 📝 Notes

### Fréquence de mise à jour

- **AltControl** envoie les données toutes les **1 seconde**
- **AltPetOverlay** nettoie les données obsolètes toutes les **5 secondes**

### Nettoyage automatique

Les pets qui n'ont pas été mis à jour depuis **10 secondes** sont automatiquement supprimés.

### Performance

L'overlay utilise `windower.prim` qui est très performant. Pas d'impact sur les FPS.

---

**Date** : 23 novembre 2024  
**Version** : 1.0.0-graphics
