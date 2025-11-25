# 🎵 SongService - Guide de Test

## Architecture Pull-Based

**Concept :** Les clients demandent des songs au Bard au lieu que le Bard vérifie les buffs.

### Avantages
- ✅ Chaque perso check SES propres buffs (fiable)
- ✅ Pas besoin de PartyBuffs ou serveur Python pour la détection
- ✅ Queue FIFO pour gérer les requêtes
- ✅ Bard suit le healer quand pas de requête

---

## Configuration

**Fichier :** `Windower4/addons/AltControl/data/autocast_config.json`

```json
{
  "SongService": {
    "mainCharacter": "Dexterbrown",
    "healerCharacter": "Deedeebrown",
    "bardName": "Bardbrown",
    "clients": {
      "Dexterbrown": ["Valor Minuet IV", "Sword Madrigal"],
      "Deedeebrown": ["Mage's Ballad II", "Army's Paeon IV"]
    },
    "followDistance": 0.75
  }
}
```

**Important :** Adapter les noms et songs à ta config !

---

## Test Étape par Étape

### 1. Préparation
```
// Dans FFXI sur TOUS les alts
//lua r altcontrol
```

### 2. Démarrer SongService
**Via Webapp :**
- Clique sur le bouton "🎶 Songs: OFF" → devient "🎶 Songs: ON"
- Envoie `//send @all ac songservice start` à tous les alts

**Ou manuellement dans FFXI :**
```
//send @all ac songservice start
```

### 3. Vérifier le chargement
```
// Sur chaque alt
//ac songservice status
```

**Tu devrais voir :**
- **Bard :** `Role: BARD`, `State: IDLE`
- **Clients :** `Role: CLIENT`

### 4. Engage un mob avec le Main
```
// Sur Dexterbrown
/assist <p1>
/attack <bt>
```

### 5. Observer le comportement

**Bard (Bardbrown) :**
- Hors combat → suit Main
- Combat + queue vide → **suit Healer** ✅
- Combat + requête → va vers client, cast, retourne healer

**Clients (Dexterbrown, Deedeebrown) :**
- Hors combat → rien
- Combat → checkent buffs toutes les 30s
- Buff manquant → envoient `/tell Bardbrown //ac songrequest [nom]`

### 6. Logs à surveiller

**Sur le Bard :**
```
[SongService] Added request from Dexterbrown (queue: 1)
[SongService] Serving: Dexterbrown
[SongService] Casting 2 songs on Dexterbrown
  → Valor Minuet IV
  → Sword Madrigal
[SongService] Finished casting on Dexterbrown
[SongService] Returning to healer
[SongService] Queue empty → STANDBY (following healer)
```

**Sur les Clients :**
```
[SongService] Missing: Valor Minuet IV → requesting
```

### 7. Arrêter SongService
**Via Webapp :**
- Clique sur "🎶 Songs: ON" → devient "🎶 Songs: OFF"

**Ou manuellement :**
```
//send @all ac songservice stop
```

---

## Troubleshooting

### Le Bard ne reçoit pas les requêtes
- Vérifier que le nom du Bard dans la config est correct
- Vérifier que les `/tell` fonctionnent entre les persos

### Les clients ne détectent pas les buffs manquants
- Vérifier que les noms de songs dans la config sont exacts
- Vérifier le mapping `SONG_TO_BUFF` dans `SongService.lua`

### Le Bard ne suit pas le healer
- Vérifier `healerCharacter` dans la config
- Vérifier que le healer existe dans la party

### Erreur Lua au démarrage
- Vérifier que `tools/SongService.lua` est bien copié
- Vérifier que `AltControlExtended.lua` est à jour
- Relancer : `//lua r altcontrol`

---

## Commandes Utiles

```bash
# Démarrer
//send @all ac songservice start

# Arrêter
//send @all ac songservice stop

# Status (sur chaque alt)
//ac songservice status

# Forcer une requête (test)
//send Bardbrown ac songrequest Dexterbrown

# Recharger AltControl
//lua r altcontrol
```

---

## Différences avec BardCycle

| Feature | BardCycle | SongService |
|---------|-----------|-------------|
| Architecture | Push (Bard check) | Pull (Clients demandent) |
| Détection buffs | PartyBuffs (serveur) | Local (windower.ffxi) |
| Fiabilité | ❌ Problèmes serveur | ✅ Fiable |
| Queue | ❌ Non | ✅ FIFO |
| Follow healer | ❌ Non | ✅ Oui |
| Complexité | 🔴 Élevée | 🟢 Simple |

---

## Prochaines Améliorations

- [ ] Priorité dans la queue (healer > DPS)
- [ ] Cooldown entre requêtes (éviter spam)
- [ ] Détection automatique du Bard (pas besoin de config)
- [ ] Support multi-bards
- [ ] Interface webapp pour voir la queue

---

**Bon test ! 🎵**
