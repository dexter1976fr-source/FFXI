# 🎮 FFXI ALT CONTROL - RÉCAPITULATIF COMPLET DU PROJET

**Date:** 19 Novembre 2025  
**Projet:** Système de contrôle multi-personnages pour Final Fantasy XI

---

## 📋 VUE D'ENSEMBLE

### Objectif du Projet
Créer une application web permettant de contrôler plusieurs personnages FFXI simultanément via une interface moderne, avec automatisation des actions répétitives.

### Architecture Globale
```
┌─────────────────┐
│   Interface Web │ (React + TypeScript)
│   (Port 3000)   │
└────────┬────────┘
         │ HTTP/WebSocket
┌────────▼────────┐
│ Serveur Python  │ (Flask + Socket)
│   (Port 5000)   │
└────────┬────────┘
         │ UDP Socket
┌────────▼────────┐
│ Windower Addons │ (Lua)
│  (Ports 5007+)  │
└────────┬────────┘
         │
┌────────▼────────┐
│   FFXI Client   │
└─────────────────┘
```

---

## 📁 STRUCTURE DES DOSSIERS

### Projet Principal
```
A:\Jeux\PlayOnline\Projet Python\FFXI_ALT_Control\
├── FFXI_ALT_Control.py          # Serveur Python principal
├── Web_App/                      # Application React
│   ├── src/
│   │   ├── components/          # Composants React
│   │   ├── services/            # Services API
│   │   └── data/                # Données statiques
│   └── dist/                    # Build production
├── data_json/                   # Données de jeu (spells, items, etc.)
├── docs/                        # Documentation
└── [backups]                    # Fichiers de sauvegarde
```

### Windower Addons
```
A:\Jeux\PlayOnline\Windower4\addons\AltControl\
├── AltControl.lua               # Addon principal
├── AutoCast.lua                 # Module AutoCast
├── AutoCast_BRD.lua            # Module BRD
├── AutoCast_SCH.lua            # Module SCH
└── [autres modules job]
```

---

## 🎯 FONCTIONNALITÉS PRINCIPALES

### ✅ Fonctionnalités Opérationnelles

#### 1. Gestion Multi-Personnages
- **Détection automatique** des ALTs connectés
- **Synchronisation temps réel** des données (HP, MP, TP, buffs, etc.)
- **Interface web** pour voir tous les ALTs simultanément
- **Envoi de commandes** individuelles ou groupées

#### 2. Système de Recast
- **Affichage temps réel** des recasts (abilities, spells, items)
- **Boutons intelligents** qui se désactivent pendant recast
- **Cooldowns visuels** avec compte à rebours
- **Blood Pacts** pour BST/SMN avec gestion des charges

#### 3. Macros Personnalisées
- **Création de macros** via interface web
- **Exécution sur ALTs** sélectionnés
- **Sauvegarde persistante** des macros
- **Catégorisation** par job/utilité

#### 4. AutoCast System (BRD/SCH)
- **BRD:** Gestion automatique des songs (Mages/Melee/Debuff)
- **SCH:** Gestion des Arts (Light/Dark) et Stratagems
- **Détection intelligente** des buffs manquants
- **Mouvements automatiques** (follow, positionnement)

#### 5. Follow System
- **Follow automatique** d'un personnage
- **Gestion des distances** (min/max)
- **Détection des mouvements** pour éviter cast pendant déplacement

---

## 🔧 COMPOSANTS TECHNIQUES

### Serveur Python (FFXI_ALT_Control.py)

#### Fonctions Principales
```python
# Gestion des connexions ALTs
handle_alt_data()           # Reçoit données des ALTs
send_command_to_alt()       # Envoie commandes aux ALTs

# Système BRD Intelligent
brd_intelligent_manager()   # Analyse buffs et envoie commandes

# API Flask
/alts                       # Liste des ALTs
/command                    # Envoie commande
/macro                      # Gestion macros
```

#### Variables Globales Importantes
```python
alts = {}                   # Données de tous les ALTs
last_logged_state = {}      # État précédent pour détection changements
brd_next_check = "mages"    # État du système BRD
```

### Windower Lua (AltControl.lua)

#### Commandes Disponibles
```lua
//ac start                  # Démarrer AutoCast
//ac stop                   # Arrêter AutoCast
//ac follow <nom>          # Suivre un personnage
//ac enable_auto_songs     # Activer auto-songs (BRD)
//ac disable_auto_songs    # Désactiver auto-songs
//ac cast_mage_songs       # Forcer cast songs mages
//ac cast_melee_songs      # Forcer cast songs melees
//ac enable_debuffs        # Activer debuffs (BRD)
//ac disable_debuffs       # Désactiver debuffs
```

#### Modules Job
- **AutoCast.lua:** Gestionnaire principal, délègue aux modules job
- **AutoCast_BRD.lua:** Gestion complète du Bard
- **AutoCast_SCH.lua:** Gestion du Scholar (Arts, Stratagems)

### Interface Web React

#### Composants Principaux
```typescript
AltController.tsx           # Contrôle d'un ALT individuel
AltAdminPanel.tsx          # Vue d'ensemble tous ALTs
CommandButton.tsx          # Bouton avec recast
backendService.ts          # Communication serveur
```

#### Données Statiques
```typescript
spellIds.ts                # IDs des sorts
recastIds.ts               # IDs des recasts
bloodPactRecastIds.ts      # IDs Blood Pacts
```

---

## 🎵 SYSTÈME BRD (État Actuel)

### Architecture
```
Serveur Python (Cerveau)
    ↓ Analyse buffs toutes les 10s
    ↓ Détecte buffs manquants
    ↓ Envoie commande
Windower Lua (Exécutant)
    ↓ Reçoit commande
    ↓ Gère mouvement + queue
    ↓ Cast les songs
```

### Phases BRD
1. **idle** - Repos, suit le healer
2. **cast_mages** - Cast Ballad III + Victory March
3. **cast_melees** - Cast Minuet V + Madrigal
4. **cast_debuff** - Cast Requiem VII (désactivé)

### Détection des Buffs
```python
# Serveur vérifie:
healer_buffs = ["Ballad", "March"]
melee_buffs = ["Minuet", "Madrigal"]

# Si manquant → Envoie commande
send_command("//ac cast_mage_songs")
```

### Problèmes Actuels
- ❌ BRD cast parfois sur mauvaise cible
- ❌ Se mélange entre phases mages/melees
- ⚠️ Timing parfois trop court (1 song au lieu de 2)

### Backups Importants
- `AutoCast_BRD_WORKING_MAGE_MELEE.lua` - Version STABLE
- `AutoCast_BRD_BEFORE_SMART_LOGIC.lua` - Avant logique intelligente
- `FFXI_ALT_Control_BACKUP_BEFORE_BRD_LOGIC.py` - Serveur avant BRD

---

## 📊 DONNÉES DE JEU

### Fichiers JSON (data_json/)
```
jobs.json                  # Données des jobs
spell_requirements.json    # Prérequis des sorts
items.json                 # Items du jeu
weaponskills.json         # Weapon Skills
```

### Scripts Python Utilitaires
```python
rebuild_brd_from_windower.py    # Reconstruit données BRD
update_sch_from_windower.py     # Met à jour données SCH
fix_sch_spells.py               # Corrige sorts SCH
```

---

## 🚀 DÉMARRAGE DU SYSTÈME

### 1. Lancer le Serveur Python
```
python FFXI_ALT_Control.py
```
- Interface GUI s'ouvre
- Cliquer "Start Server"
- Serveur écoute sur port 5000

### 2. Lancer Windower
```
//lua load altcontrol
```
- Addon se connecte au serveur
- Envoie données toutes les secondes

### 3. Ouvrir Interface Web
```
http://localhost:3000
```
- Voir tous les ALTs
- Contrôler individuellement
- Créer/exécuter macros

---

## 🔄 WORKFLOW TYPIQUE

### Utilisation Normale
1. Lancer serveur Python
2. Lancer FFXI + Windower sur chaque ALT
3. Charger addon `//lua load altcontrol`
4. Ouvrir interface web
5. Activer AutoCast si besoin (BRD/SCH)
6. Utiliser boutons/macros pour contrôler

### Développement
1. Modifier code (Lua ou Python)
2. **Lua:** `//lua r altcontrol` pour recharger
3. **Python:** Restart serveur via GUI
4. **React:** `npm run build` puis refresh navigateur

---

## 🐛 PROBLÈMES CONNUS

### BRD System
- Cast sur mauvaise cible (mélange mages/melees)
- Timing parfois insuffisant
- Pas de vérification position avant cast

### Général
- Parfois perte de connexion UDP (relancer addon)
- Recast pas toujours synchronisé immédiatement
- Interface web peut se désynchroniser (refresh)

---

## 📝 TODO / AMÉLIORATIONS FUTURES

### Priorité Haute
1. **Corriger BRD:** Forcer position avant cast
2. **Ajouter debuffs BRD:** Système intelligent
3. **Améliorer SCH:** Gestion automatique Stratagems

### Priorité Moyenne
4. **Autres jobs:** WHM, RDM, GEO auto-heal/buff
5. **Combat assist:** Auto-attack, auto-WS
6. **Inventory management:** Voir/gérer inventaire

### Priorité Basse
7. **Multi-boxing avancé:** Formations, stratégies
8. **Logs/Analytics:** Statistiques de combat
9. **Mobile app:** Contrôle depuis téléphone

---

## 💾 FICHIERS CRITIQUES À NE PAS PERDRE

### Backups Essentiels
```
AutoCast_BRD_WORKING_MAGE_MELEE.lua
FFXI_ALT_Control_BACKUP_BEFORE_BRD_LOGIC.py
data_json/                  # Toutes les données de jeu
Web_App/dist/              # Build production web
```

### Configuration
```
.kiro/                     # Config Kiro (si utilisé)
Web_App/package.json       # Dépendances React
```

---

## 🎓 CONNAISSANCES TECHNIQUES

### Lua Windower
- `windower.ffxi.get_player()` - Données joueur
- `windower.ffxi.get_party()` - Données party
- `windower.ffxi.get_mob_by_name()` - Trouver mob
- `windower.send_command()` - Exécuter commande
- `windower.ffxi.run()` - Contrôler mouvement

### Python Flask
- `@app.route()` - Définir endpoint API
- `request.json` - Recevoir données POST
- `jsonify()` - Retourner JSON
- `socket.socket()` - Communication UDP

### React TypeScript
- `useState()` - État local
- `useEffect()` - Effets de bord
- `fetch()` - Appels API
- `setInterval()` - Polling données

---

## 📞 PORTS UTILISÉS

```
3000  - Interface Web React
5000  - Serveur Flask (API)
5007+ - Communication UDP ALTs (5007, 5008, 5009...)
```

---

## 🎯 OBJECTIFS ATTEINTS

✅ Système multi-ALT fonctionnel  
✅ Interface web moderne et réactive  
✅ Recast system temps réel  
✅ AutoCast BRD/SCH de base  
✅ Follow system  
✅ Macros personnalisées  
✅ Détection intelligente buffs  

---

## 🚧 EN COURS / À FINALISER

🔄 BRD intelligent (problème de positionnement)  
🔄 Debuffs BRD automatiques  
🔄 SCH Stratagems intelligents  

---

**Projet créé avec passion pour FFXI! 🎮**  
**Bon courage pour la suite du développement! 🚀**
