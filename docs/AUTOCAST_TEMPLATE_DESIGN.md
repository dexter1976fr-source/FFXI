# 🎯 AutoCast Template - Design Document

## 📋 Philosophie

**UN seul fichier Lua template** contenant TOUTES les fonctions possibles pour TOUS les jobs.

Pour créer un addon job-spécifique :
1. Copier `AutoCast_TEMPLATE.lua`
2. Renommer en `AutoCast_[JOB].lua`
3. Configurer la section CONFIG
4. Supprimer les fonctions non-utilisées

---

## 🏗️ Architecture Globale

```
┌─────────────────────────────────────────┐
│         React Web App (Tablette)        │
│  - Boutons ON/OFF simples               │
│  - Commandes manuelles instantanées     │
└──────────────┬──────────────────────────┘
               │ HTTP
┌──────────────▼──────────────────────────┐
│         Python Bridge (Stupide)         │
│  - Transfert brut des commandes         │
│  - Aucune logique métier                │
└──────────────┬──────────────────────────┘
               │ IPC
┌──────────────▼──────────────────────────┐
│      Lua Addon (CERVEAU COMPLET)        │
│  - Queue de commandes robuste           │
│  - Toute la logique métier              │
│  - Auto-modes intelligents              │
│  - Gestion timing et priorités          │
└─────────────────────────────────────────┘
```

---

## 🎮 Fonctions Universelles (Tous Jobs)

### 1. System Core
```lua
-- Queue de commandes (résout problème latence réseau)
command_queue = {}
function queue_command(cmd)
function process_queue()

-- État global
state = {
    enabled = false,
    auto_engage = false,
    auto_buff = false,
    auto_heal = false,
    busy = false
}

-- Commandes de base
function handle_command(cmd)
function toggle_mode(mode)
function get_status()
```

### 2. Auto-Engage (DD, Tank, Pet Jobs)
```lua
auto_engage = {
    enabled = false,
    range = 20,
    ignore_list = {}
}

function auto_engage_check()
function find_valid_target()
function should_engage(mob)
```

### 3. Auto-Buff (Tous jobs avec buffs)
```lua
auto_buff = {
    enabled = false,
    spells = {},
    cycle_index = 1,
    last_cast = 0
}

function auto_buff_check()
function get_next_buff()
function is_buff_needed(spell)
```

### 4. Auto-Heal (WHM, RDM, SCH, etc.)
```lua
auto_heal = {
    enabled = false,
    threshold = 75,
    priority = {"player", "party"}
}

function auto_heal_check()
function find_heal_target()
function select_heal_spell(target)
```

### 5. Auto-Debuff (RDM, BLM, etc.)
```lua
auto_debuff = {
    enabled = false,
    spells = {},
    target_mode = "current"
}

function auto_debuff_check()
function should_debuff(target)
```

---

## 🎭 Fonctions Spécifiques par Job

### BRD - Auto Songs
```lua
brd_config = {
    songs = {
        "Valor Minuet IV",
        "Valor Minuet V",
        "Victory March",
        "Advancing March"
    },
    cycle_delay = 2,
    party_mode = true
}

function brd_auto_songs()
function brd_get_next_song()
```

### WHM - Auto Cure
```lua
whm_config = {
    cure_thresholds = {
        ["Cure VI"] = 50,
        ["Cure V"] = 60,
        ["Cure IV"] = 75
    },
    auto_regen = true,
    auto_protect = true
}

function whm_auto_cure()
function whm_select_cure(hp_percent)
```

### SMN - Auto Blood Pact
```lua
smn_config = {
    avatar = "Carbuncle",
    auto_assault = true,
    bp_rotation = {},
    perpetuation_mode = "auto"
}

function smn_auto_bp()
function smn_maintain_avatar()
```

### GEO - Auto Bubbles
```lua
geo_config = {
    indi_spell = "Indi-Fury",
    geo_spell = "Geo-Frailty",
    auto_entrust = false
}

function geo_maintain_bubbles()
```

### COR - Auto Rolls
```lua
cor_config = {
    rolls = {
        "Samurai Roll",
        "Chaos Roll"
    },
    lucky_number = 11,
    auto_reroll = true
}

function cor_auto_rolls()
function cor_should_reroll()
```

### RUN - Auto Runes
```lua
run_config = {
    runes = {"Ignis", "Gelus", "Flabra"},
    auto_refresh = true,
    wards = {}
}

function run_maintain_runes()
```

### PUP - Auto Maneuvers
```lua
pup_config = {
    maneuvers = {},
    auto_deploy = true,
    auto_repair = 50
}

function pup_auto_maneuvers()
```

### DNC - Auto Steps/Flourishes
```lua
dnc_config = {
    steps = {"Box Step", "Stutter Step"},
    auto_samba = true,
    auto_waltz = 75
}

function dnc_auto_steps()
```

### BST - Auto Pet Commands
```lua
bst_config = {
    pet_food = "Pet Food Zeta",
    auto_reward = 50,
    auto_ready = true
}

function bst_maintain_pet()
```

---

## ⚙️ Section CONFIG (À personnaliser)

```lua
-- ============================================
-- CONFIGURATION JOB-SPÉCIFIQUE
-- ============================================
local CONFIG = {
    -- Nom du job
    job = "TEMPLATE",
    
    -- Fonctions actives (mettre false pour désactiver)
    features = {
        auto_engage = false,
        auto_buff = false,
        auto_heal = false,
        auto_debuff = false,
        -- Job-specific
        brd_songs = false,
        whm_cure = false,
        smn_bp = false,
        geo_bubbles = false,
        cor_rolls = false,
        run_runes = false,
        pup_maneuvers = false,
        dnc_steps = false,
        bst_pet = false
    },
    
    -- Paramètres généraux
    queue_delay = 0.5,
    busy_timeout = 3.0,
    debug = false
}
```

---

## 📝 Workflow de Création

### Exemple : Créer AutoCast_BRD.lua

1. **Copier le template**
```bash
copy AutoCast_TEMPLATE.lua AutoCast_BRD.lua
```

2. **Configurer**
```lua
local CONFIG = {
    job = "BRD",
    features = {
        auto_engage = false,  -- BRD n'engage pas
        auto_buff = false,    -- Pas de self-buff
        brd_songs = true,     -- ✅ Activer songs
        -- Tout le reste = false
    }
}
```

3. **Supprimer le code inutile**
- Garder : Core system, Queue, BRD functions
- Supprimer : WHM, SMN, GEO, etc.

4. **Personnaliser les songs**
```lua
brd_config = {
    songs = {
        "Valor Minuet IV",
        "Valor Minuet V",
        "Victory March",
        "Advancing March"
    }
}
```

5. **Tester**
```
//lua load AutoCast_BRD
//autocast songs on
```

---

## 🎯 Avantages de cette Approche

### ✅ Pour le développement
- Un seul fichier à maintenir (le template)
- Copier/coller = création rapide
- Structure identique pour tous les jobs

### ✅ Pour l'utilisateur
- Commandes uniformes : `//autocast [feature] on/off`
- Comportement prévisible
- Facile à débugger

### ✅ Pour l'évolution
- Ajouter une fonction = l'ajouter au template
- Tous les jobs en bénéficient
- Pas de duplication de code

---

## 🚀 Prochaines Étapes

1. ✅ Écrire ce document (FAIT)
2. ⏳ Créer `AutoCast_TEMPLATE.lua` complet
3. ⏳ Tester avec BRD (job complexe)
4. ⏳ Créer guide utilisateur
5. ⏳ Adapter pour autres jobs

---

## 💡 Notes Importantes

### Latence Réseau
La queue résout le problème tablette vs localhost :
```lua
-- Commande arrive → mise en queue → exécution fiable
-- Pas de perte même avec latence WiFi
```

### Commandes Manuelles
Restent dans React pour actions instantanées :
- Cast direct : "Cure V <t>"
- Changement target : "/target <name>"
- Actions urgentes

### État Persistant
Les modes restent actifs même après déconnexion :
```lua
-- Auto-songs ON → reste ON jusqu'à OFF explicite
-- Pas besoin de réactiver à chaque fois
```

---

**Date:** 22 novembre 2024  
**Auteur:** Dexter  
**Version:** 1.0 - Design Initial
