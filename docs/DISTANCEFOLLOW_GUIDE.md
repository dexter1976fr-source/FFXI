# DistanceFollow - Guide d'utilisation

## Description

DistanceFollow est un système de suivi intelligent qui ajuste automatiquement la distance de suivi en fonction du mode de combat.

**Avantages par rapport au `/follow` du jeu :**
- Distance configurable (min/max)
- Adaptation automatique selon AutoEngage
- Pas de perte de target lors des changements de cible
- Mouvement fluide et précis

## Modes de fonctionnement

### Mode Combat (AutoEngage ON)
- **Distance min:** 0.5 yalms
- **Distance max:** 1.0 yalm
- Permet de rester à portée de mêlée pour attaquer

### Mode Suivi (AutoEngage OFF)
- **Distance min:** 10 yalms
- **Distance max:** 18 yalms
- Distance de sécurité pour suivre avec plus de manœuvre

## Commandes

### Démarrer le suivi
```
//ac dfollow [nom_cible] [mode]
```

**Exemples :**
```
//ac dfollow Dexterbrown          # Mode suivi (10-18 yalms)
//ac dfollow <p1>                  # Suivre le leader (10-18 yalms)
//ac dfollow Dexterbrown combat   # Mode combat (0.5-1 yalm)
```

### Arrêter le suivi
```
//ac dfollow stop
```

### Configurer les distances
```
//ac dfollow config [combat_min] [combat_max] [follow_min] [follow_max]
```

**Exemple :**
```
//ac dfollow config 0.5 1.0 15 20
```

### Voir la configuration actuelle
```
//ac dfollow config
```

## Intégration avec AutoEngage

Le système change automatiquement de mode quand AutoEngage est activé/désactivé :

1. **Démarrer DistanceFollow en mode suivi :**
   ```
   //ac dfollow Dexterbrown
   ```

2. **Activer AutoEngage :**
   ```
   //ac autoengage start
   ```
   → DistanceFollow passe automatiquement en mode combat (0.5-1 yalm)

3. **Désactiver AutoEngage :**
   ```
   //ac autoengage stop
   ```
   → DistanceFollow repasse en mode suivi (10-18 yalms)

## Cas d'usage : SMN

**Problème avec `/follow` :**
- Le SMN suit le tank
- AutoEngage engage → le SMN change de target
- Le SMN attaque puis reprend son ancien target (le tank)
- Le `/follow` se casse

**Solution avec DistanceFollow :**
1. Démarrer le suivi :
   ```
   //ac dfollow Dexterbrown
   ```

2. Activer AutoEngage :
   ```
   //ac autoengage start
   ```

3. Le SMN :
   - Suit le tank à 10-18 yalms (mode suivi)
   - Quand AutoEngage engage, passe à 0.5-1 yalm (mode combat)
   - Attaque la cible
   - Reprend automatiquement la bonne distance après le combat

## Configuration avancée

### Distances personnalisées par job

**Mêlée (MNK, WAR, etc.) :**
```
//ac dfollow config 0.5 1.0 10 18
```

**Ranged (RNG, COR) :**
```
//ac dfollow config 5 8 15 20
```

**Mages (WHM, BLM, etc.) :**
```
//ac dfollow config 10 15 18 25
```

## Notes techniques

- Le système utilise `prerender` pour un mouvement fluide (appelé chaque frame)
- Les distances sont calculées au carré pour optimiser les performances
- Le mouvement s'arrête automatiquement pendant les casts (status == 4)
- Distance max de poursuite : 50 yalms (évite de courir trop loin)

## Troubleshooting

**Le personnage ne bouge pas :**
- Vérifier que DistanceFollow est actif : `//ac status`
- Vérifier que la cible existe et est à portée
- Vérifier que le personnage n'est pas en cast

**Le personnage recule constamment :**
- La distance min est trop grande
- Réduire la distance min : `//ac dfollow config 0.3 1.0 13 18`

**Le personnage ne suit pas assez près :**
- La distance max est trop grande
- Réduire la distance max : `//ac dfollow config 0.5 0.8 13 18`
