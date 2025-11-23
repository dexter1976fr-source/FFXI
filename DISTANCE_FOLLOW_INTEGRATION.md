# 🎯 DISTANCE FOLLOW - INTÉGRATION

## Ce qui a été fait

### 1. Addon DistanceFollow créé ✅
- **Emplacement:** `Windower4/addons/DistanceFollow/DistanceFollow.lua`
- **Fonction:** Maintenir une distance min/max du target
- **Avantage:** Ne bouge pas si le target bouge légèrement → Pas d'interruption de cast

### 2. Serveur Python modifié ✅
- Remplacé `//ac follow` par `//dfollow`
- **Healer:** `//dfollow {healer} 1 2` (distance 1-2 yalms)
- **Melee:** `//dfollow {melee} 1.5 2.5` (distance 1.5-2.5 yalms)

## Comment tester

### 1. Charger l'addon
Dans le jeu:
```
//lua load distancefollow
```

### 2. Lancer le système BRD
- Relancer le serveur Python
- Cliquer sur le bouton AutoCast
- Engager un mob

### 3. Résultat attendu
- ✅ BRD cast 2 mage songs sur le healer
- ✅ BRD suit le melee avec distance 1.5-2.5 yalms
- ✅ Si le melee bouge légèrement, le BRD ne bouge pas
- ✅ BRD cast 2 melee songs
- ✅ BRD retourne au healer avec distance 1-2 yalms
- ✅ Loop

## Commandes manuelles

Si besoin de tester manuellement:
```
//dfollow Dexterbrown 1.5 2.5
//dfollow stop
```

## Restauration version stable

Si problème, restaurer la version sans DistanceFollow:
```powershell
Copy-Item "BACKUP_21NOV_BRD_STABLE\*" -Destination "." -Force
```

Puis dans le serveur Python, remplacer `//dfollow` par `//ac follow`.

## Avantages de cette approche

1. **Séparation des responsabilités:** L'addon gère uniquement le follow
2. **Pas de modification du code stable:** Juste changement de commande
3. **Facile à désactiver:** `//lua unload distancefollow`
4. **Réutilisable:** Peut être utilisé pour d'autres jobs

## Configuration

Pour ajuster les distances, modifier dans le serveur Python:
- Healer: `//dfollow {healer} 1 2` → Changer 1 et 2
- Melee: `//dfollow {melee} 1.5 2.5` → Changer 1.5 et 2.5
