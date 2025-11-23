# Test du split AltControl

## ✅ Fichiers créés

- `AltControl.lua` (Core - 200 lignes)
- `AltControlExtended.lua` (Module - 1000 lignes)

## 🧪 Tests à faire dans FFXI

### Test 1 : Core seul

```lua
// Recharger AltControl
//lua r altcontrol

// Vérifier le status
//ac status

// Résultat attendu:
// [AltControl] Core: ACTIVE
// [AltControl] Extended: NOT LOADED
```

### Test 2 : Charger Extended

```lua
// Charger Extended
//ac load_extended

// Résultat attendu:
// [Extended] 🚀 Initializing features...
// [Extended] ✅ All features initialized

// Vérifier le status
//ac status

// Résultat attendu:
// [AltControl] Core: ACTIVE
// [AltControl] Extended: LOADED
```

### Test 3 : Tester les fonctionnalités

```lua
// Tester AutoEngage
//ac autoengage start

// Tester DistanceFollow
//ac dfollow combat Dexterbrown

// Tester les commandes
//ac cast "Cure" <me>
```

### Test 4 : Décharger Extended

```lua
// Décharger Extended
//ac unload_extended

// Résultat attendu:
// [Extended] 🛑 Shutting down features...
// [Extended] ✅ All features stopped
// [AltControl] ✅ Extended features unloaded

// Vérifier le status
//ac status

// Résultat attendu:
// [AltControl] Core: ACTIVE
// [AltControl] Extended: NOT LOADED
```

### Test 5 : Reload complet

```lua
// Recharger tout
//lua r altcontrol

// Attendre 1 seconde

// Recharger Extended
//ac load_extended
```

## 🐛 En cas de problème

**Si erreur au chargement :**
1. Double-clic sur `RESTORE_QUICK.ps1`
2. Dans FFXI : `//lua r altcontrol`

**Si Extended ne charge pas :**
- Vérifier les logs dans la console Windower
- Vérifier que `AltControlExtended.lua` est bien dans le dossier

**Si commandes ne fonctionnent pas :**
- Vérifier que Extended est chargé : `//ac status`
- Charger Extended : `//ac load_extended`

## ✅ Si tout fonctionne

Passer à l'étape suivante : Modifier le serveur Python pour gérer le load/unload automatique.
