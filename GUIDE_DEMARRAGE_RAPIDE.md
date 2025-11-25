# 🚀 GUIDE DE DÉMARRAGE RAPIDE

## 📋 STRUCTURE DU PROJET (APRÈS NETTOYAGE)

```
FFXI_ALT_Control/
├── AltControl.lua              # Point d'entrée (7.6 KB)
├── AltControlExtended.lua      # Fonctionnalités (46.3 KB)
├── AutoCast.lua                # Loader modules (10 KB)
├── tools/
│   ├── SongService.lua         # BRD system (16.4 KB) ⭐
│   ├── AltPetOverlay.lua       # Pet overlay (10.7 KB)
│   ├── DistanceFollow.lua      # Follow system (9.3 KB)
│   ├── PartyBuffs.lua          # Buff detection (5.7 KB)
│   └── AutoEngage.lua          # Auto-engage (4.4 KB)
├── data_json/
│   └── autocast_config.json    # Configuration
├── Web_App/                    # Interface web
├── docs/                       # Documentation
└── archive/                    # Backups archivés
```

---

## ⚡ DÉMARRAGE RAPIDE

### 1. Lancer le serveur Python
```bash
python FFXI_ALT_Control.py
```

### 2. Dans FFXI, charger l'addon
```
//lua load altcontrol
```

### 3. Tester SongService (BRD)
```
//ac songservice status
//ac songservice start
```

---

## 🎵 SYSTÈME BRD - SONGSERVICE

### Architecture
- **Pull-based** : Les clients demandent des chants au BRD
- **Queue management** : File d'attente FIFO par target
- **Auto-detection** : Détecte automatiquement le rôle (CLIENT/BARD)

### Commandes
```
//ac songservice start      # Démarrer le service
//ac songservice stop       # Arrêter le service
//ac songservice status     # Voir l'état
//ac songservice debug      # Toggle debug
```

### Configuration
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

## 🔧 AUTRES SYSTÈMES

### DistanceFollow
```
//ac follow <target>        # Suivre une cible
//ac follow stop            # Arrêter de suivre
```

### AutoEngage
```
//ac engage on              # Activer auto-engage
//ac engage off             # Désactiver
```

### PartyBuffs
```
//ac buffs check            # Vérifier les buffs du party
```

---

## 🐛 DÉPANNAGE

### SongService ne démarre pas
1. Vérifier que le serveur Python tourne
2. Vérifier `autocast_config.json`
3. Regarder les logs : `//ac songservice debug`

### Conflits de mouvement
- SongService et DistanceFollow peuvent interférer
- Arrêter DistanceFollow pendant que BRD chante

### Restauration
- Backup complet sur autre DD
- Backups archivés dans `archive/`

---

## 📚 DOCUMENTATION COMPLÈTE

- `SONGSERVICE_TEST_GUIDE.md` - Tests détaillés BRD
- `AUTOCAST_IMPLEMENTATION.md` - Implémentation AutoCast
- `REFACTORING_ARCHITECTURE.md` - Architecture système
- `NETTOYAGE_COMPLET_25NOV.md` - Détails du nettoyage

---

## ✅ CHECKLIST POST-NETTOYAGE

- [ ] Serveur Python démarre sans erreur
- [ ] `//lua r altcontrol` charge sans erreur
- [ ] SongService détecte le rôle correctement
- [ ] Les chants sont castés correctement
- [ ] Pas de conflits entre systèmes

**Projet nettoyé et prêt ! 🎉**
