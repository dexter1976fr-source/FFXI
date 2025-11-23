# BRD - Cycle Automatique

## Objectif
Créer un BRD autonome qui gère automatiquement ses chansons en combat.

## Données Disponibles
✅ `party_engaged` - Quelqu'un en combat
✅ `active_buffs` - Buffs actifs sur chaque membre
✅ `is_moving` - Le BRD est en mouvement
✅ Système de follow (healer/tank)
✅ File d'attente de casts

## Cycle Automatique v1 (Simple)

### 1. Détection Combat
```
SI party_engaged == True:
    → Démarrer le cycle
SINON:
    → Rester près du healer (position par défaut)
```

### 2. Phase Mages (près du healer)
```
Position: Healer (0.5-2 yalms)
Chansons à caster:
- Mage's Ballad (MP regen)
- Victory March (Haste)

Vérifier si déjà actives sur les mages avant de caster
```

### 3. Phase Mêlées (près du tank)
```
Position: Tank/Mêlées (3-7 yalms)
Chansons à caster:
- Valor Minuet IV (Attack)
- Sword Madrigal (Accuracy)

Vérifier si déjà actives sur les mêlées avant de caster
```

### 4. Phase Debuffs (près du mob)
```
Position: Mob (15-20 yalms)
Commande: /assist <tank>
Debuffs à caster:
- Carnage Elegy (Slow)
- Fire Threnody (Fire resist down)

Vérifier si déjà actifs sur le mob avant de caster
```

### 5. Retour Position
```
Position: Healer (0.5-2 yalms)
Attendre que les chansons expirent (~2 minutes)
Recommencer le cycle
```

## Logique de Déplacement

### Changement de Follow Target
```lua
-- Vers le healer
brd.home_target_name = "NomHealer"

-- Vers le tank
brd.temp_target = windower.ffxi.get_mob_by_name("NomTank")
brd.return_to_home_after_cast = true

-- Vers le mob
-- Utiliser /assist <tank> puis se rapprocher
```

### Cast en Mouvement
```
Grâce à la file d'attente:
1. Envoyer la commande de cast pendant le déplacement
2. Le cast se met en queue
3. Dès que le BRD arrive et s'arrête → Cast automatique
```

## Détection des Buffs

### Sur les Membres de la Party
```python
# Déjà disponible dans alts[member_name]['active_buffs']
# Exemple: ['Haste', 'Protect V', 'Shell V']

# Vérifier si une chanson est active:
if 'Victory March' in member_buffs:
    # Déjà actif, skip
else:
    # Caster
```

### Sur les Trusts
```
Problème: Les trusts n'ont pas de buffs visibles
Solution: Les ignorer dans la vérification
```

### Sur les Mobs
```
TODO: Trouver comment détecter les debuffs sur un mob
Windower API: windower.ffxi.get_mob_by_target('t')
Vérifier si les debuffs sont accessibles
```

## Prochaines Étapes

1. ✅ Ajouter `party_engaged` au Lua
2. 🔲 Créer la logique de cycle dans AutoCast_BRD.lua
3. 🔲 Tester le cycle basique (sans vérification de buffs)
4. 🔲 Ajouter la vérification des buffs
5. 🔲 Ajouter les debuffs sur mobs
6. 🔲 Créer l'interface de config dans la Web App

## Notes

- **Durée des chansons:** ~120 secondes (2 minutes)
- **Nombre max de chansons:** 2-4 selon l'équipement
- **Priorité:** Mages > Mêlées > Debuffs
- **Sécurité:** Toujours retourner au healer entre les phases
