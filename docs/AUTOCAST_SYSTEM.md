# 🎵 Système AutoCast

## Vue d'ensemble

Le système AutoCast permet l'automatisation intelligente des sorts et abilities par job. Il gère:
- **Positionnement dynamique** (se rapproche/éloigne selon le sort)
- **Cast automatique** des sorts prioritaires
- **Pause intelligente** pendant les casts
- **Retour à la position de base** après action

## Architecture

```
📁 Windower4/addons/AltControl/
├── AltControl.lua          (serveur principal - modifié)
├── AutoCast.lua            (module principal)
└── AutoCast_BRD.lua        (logique BRD)
    AutoCast_WHM.lua        (futur)
    AutoCast_RDM.lua        (futur)
    ...
```

## Phase 1: BRD (Bard)

### Fonctionnalités

✅ **Positionnement Intelligent**
- Home position: Près du healer (12-18 yalms)
- Melee position: Près du tank (3-7 yalms) pour buffs mêlée
- Mob position: Près du battle target (15-20 yalms) pour debuffs

✅ **Détection de Cast**
- FREEZE le mouvement pendant le cast
- Reprend le mouvement après le cast
- Retour automatique à la home position

✅ **Classification des Chansons**
- **Melee songs**: Minuet, Madrigal, Prelude → Nécessite d'être près du tank
- **Support songs**: March, Ballad, Paeon → Peut être casté depuis le heal
- **Debuff songs**: Elegy, Requiem, Threnody → Nécessite d'être près du mob

### Configuration

```typescript
{
  enabled: true,
  max_songs: 2,  // 2-4 selon équipement
  priority_songs: [
    "Valor Minuet IV",
    "Victory March",
    "Sword Madrigal",
    "Blade Madrigal"
  ],
  distances: {
    home: { min: 12, max: 18 },   // Healer
    melee: { min: 3, max: 7 },    // Tank
    mob: { min: 15, max: 20 }     // Battle Target
  },
  home_role: "healer",
  auto_songs: true,
  auto_movement: true
}
```

## Utilisation

### Dans FFXI

```lua
-- Charger AutoCast
//lua i AltControl load_autocast()

-- Démarrer avec config par défaut
//lua i AltControl start_autocast()

-- Arrêter
//lua i AltControl stop_autocast()
```

### Dans la WebApp

1. Ouvrir le contrôle du BRD
2. Cliquer sur le bouton **"🎵 Auto: OFF"**
3. Le système démarre automatiquement
4. Le BRD va:
   - Se positionner près du healer
   - Caster les chansons prioritaires quand quelqu'un engage
   - Se déplacer vers le tank pour les buffs mêlée
   - Retourner au healer après chaque cast

## Développement Futur

### Phase 2: WHM (White Mage)
- Auto Cure (HP% threshold)
- Auto Raise
- Auto Regen/Refresh
- Priorités configurables

### Phase 3: RDM (Red Mage)
- Refresh rotation
- Haste sur mêlée
- Cure backup
- Debuffs intelligents

### Phase 4: SCH (Scholar)
- Arts management automatique
- Accession buffs
- Helix rotation
- Stratagem usage

## Debugging

### Logs dans FFXI

```
[AutoCast] ✅ Started for BRD
[BRD AutoCast] 🎵 Initialized
[BRD AutoCast] 🎵 Casting Valor Minuet IV on <me>
[BRD AutoCast] ⏸️ Movement paused for cast
[BRD AutoCast] ✅ Cast finished
[BRD AutoCast] 🏠 Returning to home position
```

### Logs dans la Console Web (F12)

```javascript
[AutoCast] Starting for Mycharacter (BRD)
[AutoCast] Config: {...}
```

## Troubleshooting

**Le BRD ne bouge pas:**
- Vérifier que `auto_movement: true` dans la config
- Vérifier qu'il y a un healer dans la party
- Vérifier les logs: `[BRD AutoCast]`

**Les chansons ne se castent pas:**
- Vérifier que `auto_songs: true` dans la config
- Vérifier que quelqu'un est engagé en combat
- Vérifier les recasts des chansons

**Le BRD reste bloqué:**
- Arrêter AutoCast: `//lua i AltControl stop_autocast()`
- Recharger l'addon: `//lua r AltControl`

## Notes Techniques

### Détection de Cast

Le système utilise les événements Windower `action`:
- `category = 8`: Début de cast (SPELL_BEGIN)
- `category = 4`: Fin de cast (SPELL_FINISH)
- `category = 8` + `param = 28787`: Cast interrompu

### Calcul de Distance

```lua
function distance_to(target)
    local dx = target.x - player.x
    local dy = target.y - player.y
    return math.sqrt(dx*dx + dy*dy)
end
```

### Mouvement Directionnel

```lua
windower.ffxi.run(dx/dist, dy/dist)  -- Vecteur normalisé
windower.ffxi.run(false)             -- Arrêter
```

## Contribution

Pour ajouter un nouveau job:

1. Créer `AutoCast_JOB.lua`
2. Implémenter les fonctions:
   - `init()`: Initialisation
   - `update(config, player)`: Logique principale
   - `on_action(action, player)`: Événements
   - `cleanup()`: Nettoyage
3. Ajouter la config dans la WebApp
4. Tester!

---

**Version**: 1.0.0  
**Date**: 18 novembre 2025  
**Auteur**: FFXI ALT Control Team
