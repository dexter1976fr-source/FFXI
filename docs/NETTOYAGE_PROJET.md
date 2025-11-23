# 🧹 Nettoyage du projet - 18 novembre 2025

## ✅ Actions effectuées

### 1. Création de la structure organisée

```
FFXI_ALT_Control/
├── 📂 docs/              # Documentation (15+ fichiers .md)
├── 📂 scripts/           # Scripts utilitaires (12 fichiers .py)
├── 📂 data_json/         # Données JSON utilisées
│   ├── jobs.json         # ✅ Fichier unifié (utilisé)
│   ├── ws.json           # ✅ Weapon Skills (utilisé)
│   ├── item_types.json   # ✅ Types d'armes (utilisé)
│   └── backup/           # Backups de sécurité
├── 📂 Web_App/           # Application web
├── 📂 _archive/          # Fichiers obsolètes (à supprimer)
├── FFXI_ALT_Control.py   # Serveur principal
├── AltControl.lua        # Addon Windower
└── README.md             # Documentation
```

### 2. Fichiers déplacés dans _archive/

#### Copies et backups
- `FFXI_ALT_Control - Copie (2).py`
- `FFXI_ALT_Control - Copie (3).py`
- `FFXI_ALT_Control - Copie.py`
- `AltControl_BACKUP_BEFORE_TP_FIX.lua`
- `AltControl_FIXED.lua`

#### Dossiers obsolètes
- `Web_App - Copie/`
- `Web_App_save du 1311/`
- `data/` (ancien format JSON)

#### Fichiers temporaires
- `ability_ids_data.txt`
- `windower_abilities.txt`
- `last_alt_dir.txt`
- `last_data_dir.txt`
- `Projet Python.txt`

#### Anciens serveurs
- `serverlua.py`
- `serveur.py`

#### Anciens convertisseurs
- `convertisseur - 2.py`
- `convertisseur.py`

#### JSON individuels obsolètes
- `blm.json`, `blu.json`, `brd.json`, `bst.json`
- `dnc.json`, `drk.json`, `geo.json`, `pld.json`
- `rdm.json`, `run.json`, `sch.json`, `smn.json`
- `whm.json`
- `smn_blood_pacts_correct.json`

**Total: ~30 fichiers et 3 dossiers archivés**

### 3. Fichiers organisés

#### Documentation (docs/)
- Tous les fichiers `.md` (guides, résumés, documentation technique)

#### Scripts (scripts/)
- `extract_*.py` - Extraction de données
- `generate_*.py` - Génération de fichiers
- `fix_*.py` - Scripts de correction
- `verify_*.py` - Scripts de vérification
- `test_*.py` - Scripts de test
- `convert_jobs_gui.py` - Convertisseur GUI
- `check_network.py` - Test réseau

### 4. Fichiers conservés (essentiels)

#### Racine
- ✅ `FFXI_ALT_Control.py` - Serveur principal
- ✅ `AltControl.lua` - Addon Windower
- ✅ `deploy_lua.ps1` - Script de déploiement
- ✅ `alt_data_path.txt` - Configuration
- ✅ `README.md` - Documentation principale

#### data_json/
- ✅ `jobs.json` - Données unifiées (UTILISÉ)
- ✅ `ws.json` - Weapon Skills (UTILISÉ)
- ✅ `item_types.json` - Types d'armes (UTILISÉ)
- ✅ `backup/jobs.json.backup` - Backup de sécurité

## 🧪 Vérification

### Fichiers utilisés par le serveur Python

```python
# FFXI_ALT_Control.py charge uniquement:
DIR_JSON = "data_json"
- item_types.json  ✅
- jobs.json        ✅
- ws.json          ✅
```

Tous les autres fichiers JSON sont obsolètes et ont été archivés.

## 📋 Prochaines étapes

### 1. Tester l'application
```bash
python FFXI_ALT_Control.py
```
- Vérifier que le serveur démarre
- Vérifier que la Web App fonctionne
- Tester l'Auto Engage

### 2. Si tout fonctionne
```powershell
Remove-Item "_archive" -Recurse -Force
```

### 3. Si quelque chose manque
- Récupérer le fichier dans `_archive/`
- Le remettre à sa place
- Signaler le problème

## 📊 Statistiques

- **Avant**: ~60 fichiers dans la racine
- **Après**: 5 fichiers dans la racine
- **Archivés**: ~30 fichiers + 3 dossiers
- **Gain de clarté**: 🎯 Énorme!

## ✅ Avantages

1. **Structure claire** - Facile de trouver ce qu'on cherche
2. **Séparation des responsabilités** - Code / Docs / Scripts / Data
3. **Maintenance facilitée** - Plus facile d'ajouter de nouvelles fonctionnalités
4. **Backup sécurisé** - Tout est dans `_archive/` si besoin
5. **Documentation à jour** - README.md complet

## 🎯 Résultat

Le projet est maintenant **propre, organisé et maintenable**. Prêt pour continuer le développement des nouvelles fonctionnalités (Auto Heal, système de buffs, etc.).

---

**Date**: 18 novembre 2025
**Fichiers archivés**: ~30
**Structure**: ✅ Optimale
