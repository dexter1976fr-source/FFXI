# 🔇 Optimisation des logs

## Problème
Les logs spammaient la console toutes les secondes avec les mêmes informations.

## Solution
N'afficher que les **changements d'état importants**.

## Changements détectés

### Serveur Python
- ✅ Changement de job
- ✅ Changement d'arme
- ✅ Engagement/Désengagement
- ✅ Pet invoqué/libéré
- ✅ Taille de la party change

### Web App (console navigateur)
- ✅ Activation Auto Engage
- ✅ Engagement détecté
- ✅ Désengagement détecté

## Résultat

**Avant:** 60+ logs par minute
**Après:** Uniquement les changements (2-5 logs par minute)

Console beaucoup plus lisible! 🎯
