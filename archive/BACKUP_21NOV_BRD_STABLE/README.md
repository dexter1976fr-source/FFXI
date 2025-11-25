# 🎵 BACKUP BRD AUTOCAST STABLE - 21 NOVEMBRE 2025

## Version Stable

Cette version fonctionne correctement avec le cycle complet:
1. ✅ Cast 2 mage songs sur le healer
2. ✅ Follow melee + attendre arrêt mouvement
3. ✅ Cast 2 melee songs
4. ✅ Retour au healer
5. ✅ Loop

## Fichiers sauvegardés

- `FFXI_ALT_Control.py` - Serveur Python avec BRD Manager
- `AltControl.lua` - Addon principal Windower
- `AutoCast.lua` - Module AutoCast principal
- `AutoCast_BRD.lua` - Module BRD

## Comment restaurer

Si besoin de revenir à cette version:

```powershell
Copy-Item "BACKUP_21NOV_BRD_STABLE\FFXI_ALT_Control.py" -Destination "FFXI_ALT_Control.py" -Force
Copy-Item "BACKUP_21NOV_BRD_STABLE\AltControl.lua" -Destination "AltControl.lua" -Force
Copy-Item "BACKUP_21NOV_BRD_STABLE\AutoCast.lua" -Destination "AutoCast.lua" -Force
Copy-Item "BACKUP_21NOV_BRD_STABLE\AutoCast_BRD.lua" -Destination "AutoCast_BRD.lua" -Force

# Copier vers Windower
Copy-Item "AltControl.lua" -Destination "A:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua" -Force
Copy-Item "AutoCast.lua" -Destination "A:\Jeux\PlayOnline\Windower4\addons\AltControl\AutoCast.lua" -Force
Copy-Item "AutoCast_BRD.lua" -Destination "A:\Jeux\PlayOnline\Windower4\addons\AltControl\AutoCast_BRD.lua" -Force
```

## Prochaine étape

Intégration de la logique FastFollow pour gérer la distance de follow (2 yalms).

## Notes

- Le système vérifie les buffs en permanence
- Cast basé sur la présence/absence de buffs
- Attend que `is_moving = False` avant de caster sur le melee
- Pas de queue, cast direct un par un
