# 🔧 Fix AltPetOverlay - L'overlay ne s'affiche plus

## 🎯 Problème

L'overlay ne s'affiche plus après le formatage automatique de Kiro.

---

## ✅ Solution Rapide

### Étape 1 : Tester la version minimale

```lua
// In-game
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
//po test
```

**Si ça marche** → Le problème vient de la version graphique avec `windower.prim`

**Si ça ne marche pas** → Le problème vient d'autre chose (voir ci-dessous)

---

### Étape 2 : Vérifier AltControl

```lua
//lua reload AltControl
```

Regarder s'il y a des erreurs dans le chat.

---

### Étape 3 : Tester avec un vrai pet

```lua
// Pour BST
//ja "Call Beast" <me>

// Pour SMN
//ma "Carbuncle" <me>

// Pour DRG
//ja "Call Wyvern" <me>
```

Attendre 1-2 secondes pour que les données arrivent.

---

## 🔍 Diagnostic détaillé

### Vérifier que les addons sont chargés

```lua
//lua list
```

**Tu dois voir** :
- `AltControl`
- `AltPetOverlay` ou `AltPetOverlay_Minimal`

---

### Vérifier la position

Peut-être que l'overlay est hors écran :

```lua
//po pos 100 500
```

---

### Vérifier que l'IPC fonctionne

Dans AltControl, la fonction `broadcast_pet_to_overlay()` doit être appelée.

**Test manuel** :
1. Avoir un pet actif
2. Attendre 1-2 secondes
3. L'overlay devrait se mettre à jour

---

## 🐛 Problèmes connus

### Problème 1 : windower.prim ne fonctionne pas

**Symptôme** : La version graphique ne s'affiche pas, mais `//po test` ne montre rien

**Solution** : Utiliser la version minimale (texte seulement)

```lua
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
```

---

### Problème 2 : IPC ne fonctionne pas

**Symptôme** : `//po test` fonctionne, mais les vraies données ne s'affichent pas

**Solution** : Recharger AltControl

```lua
//lua reload AltControl
```

---

### Problème 3 : Overlay hors écran

**Symptôme** : L'addon est chargé mais rien ne s'affiche

**Solution** : Réinitialiser la position

```lua
//po pos 100 500
```

---

## 📝 Versions disponibles

### Version graphique (windower.prim)

**Fichier** : `AltPetOverlay.lua`

**Avantages** :
- Barres HP colorées
- Fond semi-transparent
- Style XIVParty

**Inconvénients** :
- Peut ne pas fonctionner sur toutes les versions de Windower
- Plus complexe

---

### Version minimale (texte seulement)

**Fichier** : `AltPetOverlay_Minimal.lua`

**Avantages** :
- Simple et fiable
- Fonctionne partout
- Facile à débugger

**Inconvénients** :
- Pas de graphiques
- Moins joli

---

## 🚀 Recommandation

**Pour l'instant, utilise la version minimale** :

```lua
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
//po test
```

Si ça marche, on pourra investiguer pourquoi la version graphique ne fonctionne plus.

---

## 📊 Checklist de debug

- [ ] AltControl est chargé (`//lua list`)
- [ ] AltPetOverlay_Minimal est chargé (`//lua list`)
- [ ] `//po test` affiche des données
- [ ] Position correcte (`//po pos 100 500`)
- [ ] Pet actif (BST/SMN/DRG)
- [ ] Attendre 1-2 secondes pour la mise à jour

---

**Si tout ça ne marche pas, dis-moi exactement ce que tu vois dans le chat !**
