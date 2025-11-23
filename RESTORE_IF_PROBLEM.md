# 🚨 RESTAURATION D'URGENCE

## Si le split AltControl ne fonctionne pas

### Option 1 : Restauration via backup (RAPIDE - 2 clics)

```powershell
# Copier-coller cette commande dans PowerShell:
$backup = Get-ChildItem -Directory | Where-Object { $_.Name -like "BACKUP_BEFORE_SPLIT_*" } | Select-Object -First 1 -ExpandProperty Name
Copy-Item "$backup\AltControl.lua" "AltControl.lua" -Force
Copy-Item "$backup\AltControl_Windower.lua" "A:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua" -Force
Copy-Item "$backup\FFXI_ALT_Control.py" "FFXI_ALT_Control.py" -Force
Write-Host "✅ Restauration terminée!"
```

### Option 2 : Restauration via Git

```powershell
# Revenir au tag stable
git checkout STABLE_BEFORE_SPLIT

# Ou revenir au dernier commit
git reset --hard HEAD~1
```

### Option 3 : Restauration manuelle

1. Aller dans le dossier `BACKUP_BEFORE_SPLIT_XXXXXXXX_XXXXXX`
2. Copier `AltControl.lua` vers la racine du projet
3. Copier `AltControl_Windower.lua` vers `A:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua`
4. Copier `FFXI_ALT_Control.py` vers la racine du projet

### Vérification après restauration

```powershell
# Dans le jeu FFXI:
//lua r altcontrol

# Vérifier que tout fonctionne:
//ac status
```

### Si ça ne marche toujours pas

1. Fermer FFXI complètement
2. Relancer FFXI
3. Vérifier que AltControl se charge : `//lua l altcontrol`

---

## Fichiers de backup disponibles

- **Dossier backup** : `BACKUP_BEFORE_SPLIT_XXXXXXXX_XXXXXX/`
- **Tag Git** : `STABLE_BEFORE_SPLIT`
- **Commit Git** : Dernier commit avant le split

---

## En cas de problème persistant

Contacte-moi avec :
1. Le message d'erreur exact
2. Ce que tu as essayé
3. Les logs de la console Windower
