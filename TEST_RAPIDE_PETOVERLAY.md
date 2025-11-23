# ⚡ Test Rapide AltPetOverlay

## 🎯 Test en 30 secondes

### Option 1 : Version minimale (recommandé pour debug)

```lua
//lua reload AltControl
//lua unload AltPetOverlay
//lua load AltPetOverlay_Minimal
//po test
```

**Résultat attendu** :
```
=== Pet Overlay ===
Dexterbrown → BlackbeardRandy
  HP: 650/1000 (65%)
  Ready: ●●●○○ (3/5)

Summoner → Ifrit
  HP: 800/1000 (80%)
  BP: 2.5s
```

---

### Option 2 : Version graphique

```lua
//lua reload AltControl
//lua reload AltPetOverlay
//po test
```

**Résultat attendu** :
- Deux rectangles avec barres HP colorées
- Texte avec noms et valeurs

---

## 🐛 Si ça ne marche pas

### Erreur : "addon not found"

```lua
//lua load AltPetOverlay_Minimal
```

Si ça ne marche pas, le fichier n'est pas copié correctement.

---

### Erreur : "module 'texts' not found"

La library `texts` n'est pas installée dans Windower.

**Solution** : Vérifier que Windower est à jour.

---

### Rien ne s'affiche

```lua
//po pos 100 500
//po show
```

---

## ✅ Si ça marche

Tester avec un vrai pet :

```lua
// BST
//ja "Call Beast" <me>

// SMN
//ma "Carbuncle" <me>

// DRG
//ja "Call Wyvern" <me>
```

Attendre 1-2 secondes → L'overlay devrait se mettre à jour automatiquement.

---

## 📝 Résultat

**Dis-moi** :
- [ ] Version minimale fonctionne
- [ ] Version graphique fonctionne
- [ ] Données de test s'affichent
- [ ] Vraies données s'affichent
- [ ] Erreurs dans le chat (copie-colle)

Je pourrai corriger en fonction !
