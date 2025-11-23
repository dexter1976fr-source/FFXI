# 📦 Installation AltControl V2

## 🎯 Prérequis

- FFXI avec Windower 4
- Python 3.8+
- Navigateur web moderne

## 📋 Installation

### 1. Installer les dépendances Python

```bash
cd AltControlV2/python
pip install -r requirements.txt
```

### 2. Copier les fichiers Lua vers Windower

```bash
# Copier tout le contenu de lua/ vers Windower4/addons/AltControl/
cp -r AltControlV2/lua/* "A:/Jeux/PlayOnline/Windower4/addons/AltControl/"
```

**OU** manuellement :
- Copier `AltControlV2/lua/` → `Windower4/addons/AltControl/`

### 3. Démarrer le serveur Python

```bash
cd AltControlV2/python
python server.py
```

### 4. Dans le jeu

```
//lua load AltControl
```

## 🔄 Migration depuis V1

### Sauvegarde

Avant de migrer, assure-toi d'avoir une sauvegarde :
- Dossier `Windower4/addons/AltControl/` copié ailleurs
- Fichier `FFXI_ALT_Control.py` sauvegardé

### Étapes

1. **Arrêter l'ancien système**
   ```
   //lua unload AltControl
   ```
   Arrêter le serveur Python V1

2. **Installer V2** (voir ci-dessus)

3. **Tester**
   - Charger l'addon : `//lua load AltControl`
   - Vérifier la connexion : `//ac status`
   - Tester les commandes de base : `//ac assist`, `//ac attack`

4. **Si problème**
   - Restaurer la sauvegarde
   - Signaler le bug

## 🧪 Tests

### Test 1 : Connexion serveur

```
//ac status
```

Devrait afficher :
```
[AltControl] Status:
  Serveur: Actif
  Job: BRD (ou ton job)
  Module: Chargé
```

### Test 2 : Commandes de base

```
//ac assist
//ac attack
//ac follow
```

### Test 3 : AutoCast (si BRD ou SCH)

```
//ac start
//ac stop
```

## ❓ Troubleshooting

### "Serveur Python inactif"

- Vérifier que `python server.py` tourne
- Vérifier le port 5007 n'est pas utilisé
- Vérifier le firewall

### "Module non chargé"

- Vérifier que le fichier `jobs/BRD.lua` (ou SCH.lua) existe
- Vérifier les erreurs dans le chat Windower

### "Pas de module pour ce job"

- Normal si ton job n'a pas de module AutoCast
- Les commandes de base fonctionnent quand même

## 📝 Configuration

### Éditer les configs job

Les fichiers de config sont dans `Windower4/addons/AltControl/jobs/`

Exemple pour BRD :
```lua
-- Éditer jobs/BRD.lua
BRD.config = {
    mage_songs = {"Mage's Ballad II", "Mage's Ballad III"},
    melee_songs = {"Blade Madrigal", "Sword Madrigal"},
    -- ...
}
```

Après modification :
```
//lua reload AltControl
```

## 🆘 Support

Si problème, revenir à V1 :
1. Arrêter V2
2. Restaurer la sauvegarde
3. Redémarrer V1
