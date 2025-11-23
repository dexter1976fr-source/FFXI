# AltControl V2 - Architecture refactorisée

## 📁 Structure du projet

```
AltControlV2/
├── lua/                    # Addon Windower (à copier dans Windower4/addons/)
│   ├── AltControl.lua      # Point d'entrée
│   ├── libs/               # Bibliothèques core
│   ├── jobs/               # Modules par job
│   └── data/               # Données et configs
│
├── python/                 # Serveur Python
│   ├── server.py           # Serveur principal
│   ├── modules/            # Modules par job
│   └── core/               # Core du serveur
│
└── webapp/                 # Interface web React
    ├── src/
    │   ├── components/     # Composants React
    │   ├── services/       # Services (backend, websocket)
    │   └── App.tsx
    ├── package.json
    └── vite.config.ts
```

## 🎯 Objectifs de la V2

1. **Performance** : Delta updates, pas de lag
2. **Modularité** : Un fichier par job, facile à étendre
3. **Maintenabilité** : Code propre, bien commenté
4. **Stabilité** : Tests et rollback faciles

## 📝 Installation

### 1. Python Backend

```bash
cd python
pip install -r requirements.txt
python server.py
```

### 2. Web App

```bash
cd webapp
npm install
npm run dev
```

Ouvre http://localhost:3000

### 3. Lua Addon

Copier le dossier `lua/` vers `Windower4/addons/AltControl/`

Dans le jeu :
```
//lua load AltControl
```

Voir [INSTALLATION.md](INSTALLATION.md) et [NEXT_STEPS.md](NEXT_STEPS.md) pour plus de détails.

## 🔄 Migration depuis V1

Voir [V1_VS_V2.md](V1_VS_V2.md) pour la comparaison détaillée.

## 📚 Documentation

### 🚀 Démarrage
- 🎊 [FINAL_RECAP.md](FINAL_RECAP.md) - **Récapitulatif final** (commencer ici !)
- 📖 [SUMMARY.md](SUMMARY.md) - Résumé du projet
- ⚡ [QUICK_START.md](QUICK_START.md) - Démarrage en 5 minutes
- 📦 [INSTALLATION.md](INSTALLATION.md) - Installation détaillée

### 📖 Référence
- 📚 [INDEX.md](INDEX.md) - Index de toute la documentation
- 🏗️ [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture détaillée
- ⚖️ [V1_VS_V2.md](V1_VS_V2.md) - Comparaison V1 vs V2
- 📝 [CHANGELOG.md](CHANGELOG.md) - Historique des versions

### 📊 Planification
- 📊 [PROGRESS.md](PROGRESS.md) - Progression globale (25%)
- 📋 [TODO_COMPLET.md](TODO_COMPLET.md) - Tâches restantes
- 🔄 [FONCTIONNALITES_A_PORTER.md](FONCTIONNALITES_A_PORTER.md) - Migration V1→V2

### 🔧 Développement
- 🔀 [GIT_WORKFLOW.md](GIT_WORKFLOW.md) - Workflow Git
- 📁 [FILES_CREATED.md](FILES_CREATED.md) - Liste des fichiers
- 🧪 [NEXT_STEPS.md](NEXT_STEPS.md) - Tests et validation
