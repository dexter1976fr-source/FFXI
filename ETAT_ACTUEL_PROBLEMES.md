# ÉTAT ACTUEL - PROBLÈMES APRÈS SESSION SCH

**Date:** 21 Novembre 2025 - 19h
**Backup restauré:** BACKUP_21NOV_BRD_STABLE (09:01)

## ❌ CE QUI NE FONCTIONNE PLUS

### BRD
- ❌ **Cycles automatiques de songs** : Le BRD ne cast plus les songs automatiquement à l'engage
- ❌ **Bouton AutoCast** : Le bouton dans la web app ne démarre plus les cycles

### SCH  
- ❌ **Cast manuel depuis web app** : Les sorts cliqués dans la web app ne s'exécutent pas
- ❌ **Commandes manuelles** : Les commandes depuis la web app ne fonctionnent plus

### Général
- ❌ **Follow** : BRD et SCH restent collés au joueur principal sans moyen de les décoller

## ✅ CE QUI DEVRAIT FONCTIONNER (dans le backup)

Le backup BACKUP_21NOV_BRD_STABLE contenait :
- ✅ BRD AutoCast avec cycles de songs automatiques
- ✅ Détection engage/desengage
- ✅ Songs mages (desengage) et songs mêlée (engage)
- ✅ Web app fonctionnelle pour cast manuel

## 🔍 CAUSE PROBABLE

Pendant le développement du SCH AutoCast, des modifications ont été faites dans **AltControl.lua** pour gérer les commandes `send @sch` qui ont cassé le fonctionnement normal des commandes pour le BRD.

## 🛠️ SOLUTION

Il faut vérifier que **AltControl.lua** dans Windower est bien la version du backup et qu'elle gère correctement :
1. Les commandes normales (`/ma`, `//ac cast`) pour le BRD
2. Les commandes `send` pour le SCH (si on veut garder cette fonctionnalité)

## 📝 FICHIERS À VÉRIFIER

1. `A:/Jeux/PlayOnline/Windower4/addons/AltControl/AltControl.lua`
2. `A:/Jeux/PlayOnline/Windower4/addons/AltControl/AutoCast.lua`
3. `A:/Jeux/PlayOnline/Windower4/addons/AltControl/AutoCast_BRD.lua`
4. `FFXI_ALT_Control.py` (serveur Python)

## 🎯 PROCHAINES ÉTAPES

1. Vérifier que tous les fichiers du backup sont bien en place
2. Redémarrer complètement Windower (fermer FFXI et rouvrir)
3. Redémarrer le serveur Python
4. Tester le BRD AutoCast
5. Si ça ne fonctionne toujours pas, il y a un autre problème (config, données, etc.)
