# 🎵 FIX - Système de Queue BRD

## Problème Identifié

Le BRD se déplace entre healer et melee mais **ne cast rien**!

### Cause Racine

Le système de **queue (pending_cast)** ne fonctionnait pas correctement:

1. `force_cast_mages()` est appelé → `cycle_phase = "mages"`, `cycle_song_index = 1`
2. `update_songs()` essaie de caster le song 1
3. Si `is_moving = true` → le song va en **queue**
4. ❌ **MAIS** `cycle_song_index` était incrémenté à 2 immédiatement!
5. Au prochain appel, il essaie de caster le song 2
6. ❌ Le song 2 **écrase** le song 1 dans la queue (une seule queue!)
7. ❌ Résultat: **aucun song n'est casté**

## Solution Appliquée

### 1. Ne pas incrémenter l'index si le cast va en queue

**AVANT (ligne 290-295):**
```lua
if not brd.pending_cast then
    brd.cast_song(song, '<me>')
    brd.cycle_song_index = brd.cycle_song_index + 1  ← Toujours incrémenté!
    brd.cycle_last_cast = os.clock()
end
```

**APRÈS:**
```lua
-- N'incrémenter l'index QUE si le cast réussit (pas en queue)
if not brd.pending_cast and not brd.is_moving then
    brd.cast_song(song, '<me>')
    brd.cycle_song_index = brd.cycle_song_index + 1  ← Incrémenté seulement si cast réussi
    brd.cycle_last_cast = os.clock()
elseif brd.is_moving and not brd.pending_cast then
    -- En mouvement, mettre en queue
    brd.cast_song(song, '<me>')
    -- NE PAS incrémenter l'index, attendre que le cast soit exécuté
    print('[BRD AutoCast] ⏳ Waiting for movement to stop...')
end
```

### 2. Incrémenter l'index quand le cast en queue est exécuté

**AVANT (ligne 203-210):**
```lua
if not brd.is_moving and brd.pending_cast then
    local cast = brd.pending_cast
    brd.pending_cast = nil
    
    windower.send_command('input /ma "'..cast.song..'" '..cast.target)
    brd.song_timers[cast.song] = os.clock()
    print('[BRD AutoCast] ✅ Casting queued: '..cast.song)
    -- ❌ Index pas incrémenté!
end
```

**APRÈS:**
```lua
if not brd.is_moving and brd.pending_cast then
    local cast = brd.pending_cast
    brd.pending_cast = nil
    
    windower.send_command('input /ma "'..cast.song..'" '..cast.target)
    brd.song_timers[cast.song] = os.clock()
    print('[BRD AutoCast] ✅ Casting queued: '..cast.song)
    
    -- ✅ Incrémenter l'index après avoir casté le sort en queue
    brd.cycle_song_index = brd.cycle_song_index + 1
    brd.cycle_last_cast = os.clock()
end
```

## Flux Corrigé

### Scénario: Cast Mage Songs

1. Serveur Python envoie: `//ac cast_mage_songs`
2. `force_cast_mages()` → `cycle_phase = "mages"`, `cycle_song_index = 1`
3. `update_songs()` appelé (0.1s plus tard)
4. BRD est en mouvement? 
   - **OUI** → `cast_song()` met le song 1 en queue, **index reste à 1**
   - **NON** → `cast_song()` cast immédiatement, **index passe à 2**
5. BRD s'arrête → `update_movement()` détecte `pending_cast`
6. Cast le song en queue → **index passe à 2**
7. `update_songs()` appelé (0.1s plus tard)
8. BRD cast le song 2 → **index passe à 3**
9. Tous les songs castés → passe en phase "melee"

## Logs Attendus

### Avant (cassé)
```
[BRD AutoCast] 🎵 FORCE cast mages
[BRD AutoCast] 📋 Queued: Mage's Ballad II
[BRD AutoCast] 📋 Queued: Mage's Ballad III  ← Écrase le premier!
[BRD AutoCast] ✅ Casting queued: Mage's Ballad III  ← Un seul cast!
[BRD AutoCast] 🎵 Phase MELEE  ← Passe à melee trop tôt!
```

### Après (corrigé)
```
[BRD AutoCast] 🎵 FORCE cast mages
[BRD AutoCast] ⏳ Waiting for movement to stop...
[BRD AutoCast] ✅ Casting queued: Mage's Ballad II  ← Cast 1
[BRD AutoCast] 🎵 Casting Mage's Ballad III  ← Cast 2
[BRD AutoCast] 🎵 Phase MELEE  ← Passe à melee après les 2 casts
```

## Fichiers Modifiés

- ✅ `AutoCast_BRD.lua` (lignes 203-210, 290-310, 320-340)
- ✅ Copié dans Windower

## Test

Dans le jeu:
```
//lua r altcontrol
//ac start
//ac cast_mage_songs
```

**Attendu:**
- Le BRD cast les 2 songs mages
- Puis passe en phase melee
- Cast les 2 songs melees
- Retourne en idle

Si ça marche → **PROBLÈME RÉSOLU!** 🎵
