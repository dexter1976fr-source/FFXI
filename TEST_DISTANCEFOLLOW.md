# Test DistanceFollow - Procédure de validation

## Objectif
Valider l'intégration de DistanceFollow avec AutoEngage et la webapp.

## Prérequis
- AltControl chargé sur tous les personnages
- Webapp connectée
- Au moins 2 personnages (1 tank + 1 DPS/support)

## Test 1 : Follow basique via webapp

### Étapes
1. Ouvrir la webapp sur le personnage secondaire (ex: SMN)
2. Cliquer sur le bouton **"Follow: OFF"**
3. Le bouton doit passer à **"Follow: ON"**

### Résultat attendu
- Console Windower : `[DistanceFollow] Following: [nom_leader] (mode: follow)`
- Console Windower : `[DistanceFollow] Distance: 10 - 18 yalms`
- Le personnage suit le leader à distance (10-18 yalms)

### Validation
- [ ] Le personnage suit le leader
- [ ] La distance reste entre 13-18 yalms
- [ ] Le mouvement est fluide (pas de saccades)

## Test 2 : Arrêt du follow via webapp

### Étapes
1. Avec le follow actif, cliquer sur **"Follow: ON"**
2. Le bouton doit repasser à **"Follow: OFF"**

### Résultat attendu
- Console Windower : `[DistanceFollow] Stopped`
- Le personnage arrête de suivre

### Validation
- [ ] Le personnage s'arrête immédiatement
- [ ] Pas de mouvement résiduel

## Test 3 : AutoEngage + DistanceFollow (mode combat)

### Étapes
1. Activer le follow : cliquer sur **"Follow: OFF"** → **"Follow: ON"**
2. Activer AutoEngage : cliquer sur **"⚔️ Engage: OFF"** → **"⚔️ Engage: ON"**
3. Avec le tank, engager un mob

### Résultat attendu
- Console Windower : `[DistanceFollow] Mode switched to: combat`
- Le personnage se rapproche du tank (0.5-1 yalm)
- Le personnage engage automatiquement la cible du tank
- Après le combat, le personnage reprend la distance de suivi (13-18 yalms)

### Validation
- [ ] Distance passe à 0.5-1 yalm en combat
- [ ] Le personnage engage automatiquement
- [ ] Distance repasse à 13-18 yalms après combat
- [ ] Pas de perte de follow lors des changements de cible

## Test 4 : Désactivation AutoEngage (retour mode suivi)

### Étapes
1. Avec AutoEngage actif, cliquer sur **"⚔️ Engage: ON"** → **"⚔️ Engage: OFF"**

### Résultat attendu
- Console Windower : `[DistanceFollow] Mode switched to: follow`
- Le personnage reprend la distance de suivi (13-18 yalms)

### Validation
- [ ] Distance repasse à 13-18 yalms
- [ ] Le personnage ne s'engage plus automatiquement

## Test 5 : Commandes manuelles (console)

### Étapes
1. Dans la console Windower : `//ac dfollow Dexterbrown`
2. Vérifier le suivi
3. Dans la console : `//ac dfollow config`
4. Vérifier l'affichage de la config
5. Dans la console : `//ac dfollow stop`

### Résultat attendu
```
[DistanceFollow] Following: Dexterbrown (mode: follow)
[DistanceFollow] Distance: 13 - 18 yalms

[DistanceFollow] Current config:
  Combat: 0.5 - 1.0
  Follow: 13 - 18

[DistanceFollow] Stopped
```

### Validation
- [ ] Commandes fonctionnent correctement
- [ ] Config s'affiche correctement
- [ ] Stop fonctionne

## Test 6 : Configuration personnalisée

### Étapes
1. Dans la console : `//ac dfollow config 0.3 0.8 15 20`
2. Activer le follow : `//ac dfollow Dexterbrown`
3. Vérifier les nouvelles distances

### Résultat attendu
```
[DistanceFollow] Config updated:
  Combat: 0.3 - 0.8
  Follow: 15 - 20
```

### Validation
- [ ] Nouvelles distances appliquées
- [ ] Le personnage suit à 15-20 yalms
- [ ] En combat, distance passe à 0.3-0.8 yalm

## Test 7 : Cas SMN (problème original)

### Contexte
Le `/follow` du jeu se cassait quand le SMN changeait de target avec AutoEngage.

### Étapes
1. SMN : Activer Follow + AutoEngage via webapp
2. Tank : Engager un mob
3. SMN : Engage automatiquement
4. Tank : Changer de cible (engager un 2ème mob)
5. SMN : Doit changer de cible et continuer à suivre

### Résultat attendu
- Le SMN suit le tank en permanence
- Le SMN change de cible automatiquement
- Le follow ne se casse jamais
- Distance s'adapte automatiquement (combat/suivi)

### Validation
- [ ] Follow reste actif pendant tout le combat
- [ ] Changements de cible n'affectent pas le follow
- [ ] Distance s'adapte correctement
- [ ] Pas de commande manuelle nécessaire

## Test 8 : Cast en cours (ne doit pas bouger)

### Étapes
1. Activer le follow
2. Commencer à caster un sort long (ex: Cure III)
3. Le tank bouge pendant le cast

### Résultat attendu
- Le personnage ne bouge pas pendant le cast
- Après le cast, le personnage reprend le suivi

### Validation
- [ ] Pas de mouvement pendant le cast
- [ ] Cast n'est pas interrompu
- [ ] Suivi reprend après le cast

## Problèmes connus et solutions

### Le personnage ne suit pas
**Cause :** Module non chargé
**Solution :** `//ac dfollow Dexterbrown` (charge automatiquement le module)

### Le personnage recule constamment
**Cause :** Distance min trop grande
**Solution :** `//ac dfollow config 0.3 1.0 13 18`

### Le follow se casse après un combat
**Cause :** Ancien système `/follow` encore actif
**Solution :** 
1. `//ac dfollow stop`
2. Désactiver le `/follow` du jeu
3. `//ac dfollow <p1>`

### Distance ne change pas avec AutoEngage
**Cause :** Callback non connecté
**Solution :** Recharger AltControl : `//lua r altcontrol`

## Checklist finale

- [ ] Follow basique fonctionne
- [ ] Stop fonctionne
- [ ] AutoEngage change la distance automatiquement
- [ ] Pas de perte de follow lors des combats
- [ ] Commandes manuelles fonctionnent
- [ ] Configuration personnalisée fonctionne
- [ ] Cast n'interrompt pas le suivi
- [ ] Cas SMN résolu (pas de perte de follow)

## Notes de performance

- DistanceFollow utilise `prerender` (appelé chaque frame)
- Calculs optimisés (distance au carré)
- Pas d'impact notable sur les FPS
- Mouvement plus fluide que `/follow` du jeu

## Prochaines étapes si tout fonctionne

1. Tester sur différents jobs (MNK, RNG, WHM, etc.)
2. Ajuster les distances par défaut si nécessaire
3. Ajouter des presets de distance par job dans la webapp
4. Documenter les cas d'usage avancés
