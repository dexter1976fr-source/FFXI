# Architecture BRD Correcte

## SERVEUR PYTHON = CERVEAU (décide TOUT)

### Loop principale (toutes les secondes):

1. **Trouver le BRD**
2. **Vérifier si quelqu'un est engagé** → Si non, ne rien faire
3. **Si en attente (waiting_for_queue_empty):**
   - Lire `queue_size` du BRD
   - Si `queue_size == 0` ET `is_casting == False` pendant 2 sec → Passer à la phase suivante
4. **Sinon, check toutes les 10 secondes:**
   - **Phase 1: Check mage**
     - Lire buffs du healer
     - Si manquant → Envoyer commandes:
       - `//ac queue_song "Song1" <me>`
       - `//ac queue_song "Song2" <me>`
       - `waiting_for_queue_empty = True`
       - `next_phase = "melee"`
   - **Phase 2: Check melee**
     - Lire buffs du melee
     - Si manquant → Envoyer commandes:
       - `//ac follow MeleeTarget`
       - `//ac queue_song "Song1" <me>`
       - `//ac queue_song "Song2" <me>`
       - `waiting_for_queue_empty = True`
       - `next_phase = "return_healer"`
   - **Phase 3: Retour healer**
     - Si `next_phase == "return_healer"`:
       - `//ac follow HealerTarget`
       - `next_phase = None`

## LUA = YEUX + BRAS (informe + exécute)

### Envoie au serveur (toutes les 0.5 sec):
```json
{
  "name": "BardName",
  "main_job": "BRD",
  "is_casting": true/false,
  "is_moving": true/false,
  "is_engaged": true/false,
  "queue_size": 2,  // Nombre de songs en queue
  "active_buffs": ["Ballad", "March", ...]
}
```

### Commandes reçues du serveur:
- `//ac follow <target>` → Follow quelqu'un
- `//ac queue_song "<song>" <target>` → Ajouter un song à la queue
- `//ac stop_follow` → Arrêter le follow

### Exécution automatique (dans update()):
- Si `queue_size > 0` ET `is_casting == False` ET `is_moving == False`:
  - Cast le prochain song de la queue
  - Retirer le song de la queue

## FLUX COMPLET

1. **Serveur:** Check buffs mage → Manquant
2. **Serveur → Lua:** `//ac queue_song "Ballad II" <me>`
3. **Serveur → Lua:** `//ac queue_song "Ballad III" <me>`
4. **Lua → Serveur:** `queue_size = 2`
5. **Lua:** Cast Ballad II automatiquement
6. **Lua → Serveur:** `is_casting = True, queue_size = 1`
7. **Lua:** Ballad II fini
8. **Lua → Serveur:** `is_casting = False, queue_size = 1`
9. **Lua:** Cast Ballad III automatiquement
10. **Lua → Serveur:** `is_casting = True, queue_size = 0`
11. **Lua:** Ballad III fini
12. **Lua → Serveur:** `is_casting = False, queue_size = 0`
13. **Serveur:** Détecte `queue_size == 0` pendant 2 sec → Passe à la phase suivante
