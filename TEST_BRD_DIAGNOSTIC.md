# 🎵 DIAGNOSTIC BRD - ÉTAPES DE TEST

## Problème Actuel
Le système BRD ne fonctionne plus après l'intégration du panel de contrôle.

## Corrections Appliquées

### 1. ✅ Correction Syntaxe Lua (AutoCast_BRD.lua ligne 283)
**Avant:**
```lua
-- if brd.cycle_phase == "idle" then
--     ...
elseif brd.cycle_phase == "mages" then  ← ERREUR: elseif sans if!
```

**Après:**
```lua
if brd.cycle_phase == "idle" then
    return  -- Attendre force_cast_mages/melees
elseif brd.cycle_phase == "mages" then  ← OK!
```

## Tests à Effectuer (Dans l'Ordre)

### Test 1: Vérifier que l'addon se charge
```
//lua l altcontrol
```
**Attendu:** Aucune erreur Lua

### Test 2: Démarrer AutoCast
```
//ac start
```
**Attendu:**
```
[AltControl] Starting AutoCast...
[AutoCast] 🐛 start() called
[AutoCast] 🐛 Player found: [Nom] (BRD)
[AutoCast] 🐛 Loading job module for BRD
[AutoCast] ✅ Loaded module for BRD
[BRD AutoCast] 🎵 Initialized
[AutoCast] 📖 Loading BRD config from file...
[AutoCast] 🐛 Setting active = true
[AutoCast] ✅ Started for BRD
[AltControl] ✅ AutoCast started
```

### Test 3: Vérifier le status
```
//ac status
```
**Attendu:**
```
[AltControl] AutoCast is ACTIVE
```

### Test 4: Tester force_cast_mages manuellement
```
//ac cast_mage_songs
```
**Attendu:**
```
[AltControl] 📥 Received cast_mage_songs command
[AltControl] ✅ Calling autocast.force_cast_mages()
[BRD AutoCast] 🎵 FORCE cast mages
[BRD AutoCast] 🎵 Casting Mage's Ballad III
[BRD AutoCast] 🎵 Casting Victory March
```

### Test 5: Vérifier que le serveur Python envoie les commandes
**Dans les logs Python:**
```
[BRD Manager] [Healer] buffs: [...] | Need: {'Ballad', 'March'} | Missing: ['Ballad']
[BRD Manager] [Healer] missing mage buffs (['Ballad']), casting [...]
[COMMAND] '//ac cast_mage_songs' → [BRD] (127.0.0.1:5XXX)
```

## Problèmes Possibles

### Si Test 1 échoue
- Erreur de syntaxe Lua
- Vérifier AutoCast_BRD.lua ligne 283-290

### Si Test 2 échoue
- AutoCast.lua ou AutoCast_BRD.lua introuvable
- Vérifier que les fichiers sont dans: `Windower4/addons/AltControl/`

### Si Test 3 dit "INACTIVE"
- AutoCast.start() a retourné false
- Vérifier les logs du Test 2 pour voir où ça bloque

### Si Test 4 ne cast rien
- Vérifier que `brd.cycle_phase` passe bien à "mages"
- Vérifier que `update_songs()` est appelé dans la boucle

### Si Test 5 ne voit pas les commandes
- Serveur Python pas démarré
- BRD Manager thread pas lancé
- Config autocast_config.json manquante

## Fichiers Modifiés
- ✅ `AutoCast_BRD.lua` - Correction syntaxe ligne 283

## Prochaines Étapes
1. Tester dans le jeu avec un BRD
2. Vérifier chaque test dans l'ordre
3. Noter quel test échoue
4. Appliquer la correction correspondante
