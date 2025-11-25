# 🎮 FFXI Alt Control

Système de contrôle multi-personnages pour Final Fantasy XI avec interface web.

---

## 🚀 Démarrage Rapide

### 1. Lancer le serveur
```bash
python FFXI_ALT_Control.py
```

### 2. Ouvrir la Web App
```
http://localhost:5000
```

### 3. Dans FFXI
```
//lua load altcontrol
```

---

## 🎵 Fonctionnalités Principales

### SongService (BRD)
Système automatique de gestion des songs pull-based
- Auto-détection CLIENT/BARD
- Queue FIFO par target
- Configuration JSON

**Commandes :**
```
//ac songservice start
//ac songservice stop
//ac songservice status
```

### DistanceFollow
Follow intelligent universel pour tous les jobs
```
//ac follow <target>
//ac stopfollow
```

### AltPetOverlay
Affichage et contrôle des pets (SMN/DRG/BST)
- Interface visuelle style XIVParty
- Contrôle direct des pets

### AutoEngage
Système d'assist automatique
```
//ac autoengage on
//ac autoengage off
```

---

## 📚 Documentation

- **[Guide de démarrage](START_HERE.md)** - Point d'entrée
- **[SongService Guide](SONGSERVICE_TEST_GUIDE.md)** - Guide complet BRD
- **[Roadmap](ROADMAP_PROCHAINES_ETAPES.md)** - Feuille de route

### Documentation technique
- `docs/AUTOCAST_SYSTEM.md` - Système AutoCast
- `docs/DISTANCEFOLLOW_GUIDE.md` - Guide DistanceFollow
- `docs/PETOVERLAY_GUIDE.md` - Guide PetOverlay

---

## ⚙️ Configuration

### SongService
Éditer `data_json/autocast_config.json` :
```json
{
  "songservice": {
    "enabled": true,
    "clients": {
      "Healer1": ["Ballad", "Minuet"],
      "Melee1": ["March", "Minuet"]
    }
  }
}
```

---

## 🏗️ Architecture

```
FFXI_ALT_Control/
├── FFXI_ALT_Control.py      # Serveur Python
├── AltControl.lua            # Core Lua
├── AltControlExtended.lua    # Extended features
├── tools/
│   ├── SongService.lua       # Système BRD
│   ├── DistanceFollow.lua    # Follow system
│   ├── AltPetOverlay.lua     # Pet overlay
│   └── PartyBuffs.lua        # Buff detection
├── Web_App/                  # Interface React
└── data_json/                # Configuration
```

---

## 🔧 Développement

### Build Web App
```bash
cd Web_App
npm install
npm run build
```

### Tests
```bash
# Dans FFXI
//lua r altcontrol
//ac songservice status
```

---

## 📝 Crédits

- **Windower** - Framework addon
- **React** - Interface web
- **Flask** - Serveur Python

---

## 📄 Licence

Projet personnel - Tous droits réservés

---

**Version :** 2.0.0 (Après nettoyage complet)  
**Date :** 25 novembre 2025  
**Statut :** ✅ Production Ready
