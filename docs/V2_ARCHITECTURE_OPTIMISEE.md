# 🎯 Architecture V2 Optimisée - Réflexions Post-Analyse

## 💡 Principes Fondamentaux

### 1. Communication Unidirectionnelle
**Web App → Lua** (commandes uniquement)  
**Pas de** Lua → Web App (données temps réel)

### 2. Overlay In-Game
**XIVParty style** : Affichage des infos dans le jeu  
**Pas de** polling réseau constant

### 3. Data Source Unique
**jobs.json** = Base de données centrale  
Toutes les abilities, sorts, items référencés

---

## 🏗️ Architecture Optimisée

```
┌─────────────────────────────────────────────────────┐
│  Web App (Tablette/PC)                              │
│  - Interface de contrôle                            │
│  - Envoie commandes uniquement                      │
│  - PAS de données temps réel                        │
└──────────────┬──────────────────────────────────────┘
               │ HTTP/IPC (One-way: commandes)
┌──────────────▼──────────────────────────────────────┐
│  Python Bridge (Minimal)                            │
│  - Reçoit commandes Web App                         │
│  - Transfert vers Windower                          │
│  - PAS de logique métier                            │
└──────────────┬──────────────────────────────────────┘
               │ IPC
┌──────────────▼──────────────────────────────────────┐
│  Lua Core (Cerveau)                                 │
│  - Toute la logique                                 │
│  - Validation complète                              │
│  - Auto-modes                                       │
│  - Envoie données vers Overlay                      │
└──────────────┬──────────────────────────────────────┘
               │ IPC Local
┌──────────────▼──────────────────────────────────────┐
│  Overlay In-Game (XIVParty style)                   │
│  - Affiche HP/MP/TP des alts                        │
│  - Affiche pet status                               │
│  - Affiche buffs                                    │
│  - Affiche auto-modes status                        │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Flux de Données Optimisé

### ✅ Ce qui DOIT se passer

```
1. Web App → Python → Lua
   "Cast Cure IV on <t>"
   
2. Lua → Overlay
   {hp: 1250, mp: 450, pet_hp: 800}
   
3. Overlay → Affichage in-game
   [BRD] HP: 1250/1500 MP: 450/600
   [Pet] HP: 800/1000
```

### ❌ Ce qui NE DOIT PAS se passer

```
1. Lua → Python → Web App
   Polling constant des HP/MP
   = Latence réseau inutile
   
2. Web App affiche données temps réel
   = Trop de requêtes réseau
   = Lag
```

---

## 🎮 Overlay In-Game (Inspiré XIVParty)

### Fonctionnalités

```lua
-- Overlay.lua (Windower addon)

local overlay = {
    enabled = true,
    position = {x = 10, y = 10},
    characters = {}
}

-- Reçoit données des autres Lua via IPC
windower.register_event('ipc message', function(msg)
    if msg:startswith('overlay_update_') then
        local data = parse_overlay_data(msg)
        overlay.characters[data.name] = data
        update_display()
    end
end)

-- Affichage
function update_display()
    local text = ""
    
    for name, data in pairs(overlay.characters) do
        text = text .. string.format(
            "[%s] HP:%d/%d MP:%d/%d TP:%d\n",
            name, data.hp, data.max_hp, 
            data.mp, data.max_mp, data.tp
        )
        
        -- Pet info si existe
        if data.pet then
            text = text .. string.format(
                "  [Pet] HP:%d/%d\n",
                data.pet.hp, data.pet.max_hp
            )
        end
        
        -- Auto-modes actifs
        if data.auto_modes then
            text = text .. "  Auto: "
            for mode, active in pairs(data.auto_modes) do
                if active then
                    text = text .. mode .. " "
                end
            end
            text = text .. "\n"
        end
    end
    
    windower.text.set_text('overlay_display', text)
end
```

### Avantages

1. **Pas de latence réseau** : Tout en local (IPC Windower)
2. **Temps réel** : Mise à jour instantanée
3. **Léger** : Pas de HTTP/polling
4. **Visible in-game** : Pas besoin de regarder tablette
5. **Customizable** : Position, couleurs, taille

---

## 📚 jobs.json - Base de Données Centrale

### Structure Optimisée

```json
{
  "jobs": {
    "BRD": {
      "name": "Bard",
      "abilities": [
        {
          "id": 48,
          "name": "Soul Voice",
          "type": "JA",
          "recast_id": 48,
          "targets": "Self"
        }
      ],
      "spells": [
        {
          "id": 386,
          "name": "Valor Minuet IV",
          "type": "BardSong",
          "element": "Wind",
          "targets": "Party",
          "mp_cost": 39,
          "cast_time": 3.0,
          "recast": 3.0
        }
      ],
      "auto_modes": {
        "auto_songs": {
          "enabled": false,
          "rotation": [
            "Valor Minuet IV",
            "Valor Minuet V",
            "Victory March",
            "Advancing March"
          ],
          "delay": 3.0,
          "stability_required": 2.0
        }
      }
    },
    "WHM": {
      "name": "White Mage",
      "spells": [
        {
          "id": 7,
          "name": "Cure IV",
          "type": "WhiteMagic",
          "element": "Light",
          "targets": "Single",
          "mp_cost": 88,
          "cast_time": 2.0,
          "recast": 2.0
        }
      ],
      "auto_modes": {
        "auto_heal": {
          "enabled": false,
          "threshold": 75,
          "priority": ["tank", "healer", "dd"],
          "mp_management": {
            "critical": 20,
            "low": 50,
            "normal": 100
          }
        }
      }
    }
  }
}
```

### Utilisation

```lua
-- Charger jobs.json au démarrage
local jobs_data = require('jobs_data')

-- Accéder aux données
local brd_songs = jobs_data.jobs.BRD.spells
local whm_heals = jobs_data.jobs.WHM.spells

-- Validation
function can_cast_spell(spell_name)
    local spell = find_spell(spell_name)
    if not spell then return false, "Spell not found" end
    
    if player.mp < spell.mp_cost then
        return false, "Not enough MP"
    end
    
    -- etc.
    return true, "OK"
end
```

---

## 🔧 Optimisations Identifiées

### 1. Réduire Trafic Réseau

**Avant (V1) :**
```
Web App ←→ Python ←→ Lua
  ↓         ↓         ↓
Poll HP   Forward   Send HP
Poll MP   Forward   Send MP
Poll TP   Forward   Send TP
= 60 requêtes/seconde !
```

**Après (V2) :**
```
Web App → Python → Lua
  ↓         ↓       ↓
Command  Forward  Execute

Lua → Overlay (IPC local)
  ↓       ↓
Data   Display
= 0 requêtes réseau pour affichage !
```

### 2. Centraliser Données

**jobs.json** contient TOUT :
- ✅ Spells IDs
- ✅ Abilities IDs
- ✅ Recast IDs
- ✅ MP costs
- ✅ Cast times
- ✅ Targets
- ✅ Auto-modes configs

**Avantages :**
- Une seule source de vérité
- Facile à maintenir
- Facile à étendre
- Pas de duplication

### 3. Overlay > Web App pour Monitoring

**Pourquoi :**
- Pas de latence réseau
- Visible pendant le jeu
- Mise à jour temps réel
- Léger (IPC local)

**Web App reste pour :**
- Contrôle (commandes)
- Configuration (settings)
- Inventory management
- Pas pour monitoring temps réel

---

## 🎯 Rôles Clarifiés

### Web App (React)
```typescript
// UNIQUEMENT pour :
- Envoyer commandes
- Configurer auto-modes
- Gérer inventory
- Interface utilisateur

// PAS pour :
- Afficher HP/MP temps réel
- Monitoring combat
- Afficher pet status
```

### Python Bridge
```python
# UNIQUEMENT pour :
- Recevoir commandes HTTP
- Transférer vers Windower IPC
- Rien d'autre !

# PAS pour :
- Logique métier
- Validation
- Polling données
```

### Lua Core
```lua
-- TOUT :
- Logique métier
- Validation
- Auto-modes
- État global
- Envoyer données overlay

-- Communication :
- Recevoir commandes (IPC)
- Envoyer données overlay (IPC local)
```

### Overlay (Lua addon séparé)
```lua
-- UNIQUEMENT pour :
- Recevoir données (IPC)
- Afficher in-game
- Customisation visuelle

-- PAS pour :
- Logique métier
- Validation
- Commandes
```

---

## 📁 Structure Fichiers Optimisée

```
FFXI_Alt_Control/
├── Web_App/                    # React (commandes uniquement)
│   ├── src/
│   │   ├── components/
│   │   │   ├── CommandPanel.tsx
│   │   │   ├── ConfigPanel.tsx
│   │   │   └── InventoryPanel.tsx
│   │   └── services/
│   │       └── commandService.ts  # Envoie commandes
│   └── package.json
│
├── Python/
│   └── bridge.py               # Transfert simple
│
├── Windower4/addons/
│   ├── AltControl/             # Core Lua
│   │   ├── AltControl.lua      # Main
│   │   ├── Core.lua            # Events & État
│   │   ├── Queue.lua           # Queue commandes
│   │   ├── Validation.lua      # Validation
│   │   └── jobs/
│   │       ├── BRD.lua
│   │       ├── WHM.lua
│   │       └── ...
│   │
│   └── AltOverlay/             # Overlay séparé
│       └── AltOverlay.lua      # Affichage in-game
│
└── data/
    └── jobs.json               # Base de données
```

---

## 🚀 Prochaines Étapes

### Phase 1 : Analyser XIVParty
- [ ] Étudier XIVParty.lua
- [ ] Comprendre leur overlay
- [ ] Adapter pour nos besoins

### Phase 2 : Créer Overlay
- [ ] AltOverlay.lua basique
- [ ] Affichage HP/MP/TP
- [ ] Affichage pet
- [ ] Customisation position

### Phase 3 : Optimiser Communication
- [ ] Web App → commandes uniquement
- [ ] Lua → Overlay (IPC local)
- [ ] Supprimer polling réseau

### Phase 4 : Centraliser jobs.json
- [ ] Compléter toutes les données
- [ ] Parser en Lua
- [ ] Utiliser partout

---

## 💡 Insights Clés

1. **Overlay > Web App** pour monitoring temps réel
2. **IPC local > HTTP** pour données fréquentes
3. **jobs.json** = source unique de vérité
4. **Web App** = contrôle, pas monitoring
5. **Lua** = cerveau complet

---

**Date:** 23 novembre 2024  
**Version:** 1.0 - Architecture optimisée post-réflexion  
**Status:** Design en cours
