# 🎵 SongService - Guide de Test (Version 2.0 - Universelle)

## Architecture Pull-Based

**Concept :** Les clients demandent des songs au Bard au lieu que le Bard vérifie les buffs.

### Avantages
- ✅ Chaque perso check SES propres buffs (fiable)
- ✅ Pas besoin de PartyBuffs ou serveur Python pour la détection
- ✅ Queue FIFO pour gérer les requêtes
- ✅ Bard suit le healer quand pas de requête
- ✅ **NOUVEAU** : Configuration 100% universelle
- ✅ **NOUVEAU** : Auto-détection du rôle (BRD/CLIENT)
- ✅ **NOUVEAU** : Priorité automatique au healer

---

## Configuration Universelle

### Fichiers utilisés

**1. `data_json/party_roles.json`** - Définit qui est qui
```json
{
  "main_character": "Dexterbrown",
  "alt1": "Deedeebrown",  // ← Healer
  "alt2": "Debybrown"     // ← Bard
}
```

**2. `data_json/alt_configs.json`** - Existe déjà, utilisé pour détecter les alts

**3. Songs configurés automatiquement :**
- **Healer** : Mage's Ballad II + Army's Paeon IV
- **Main** : Valor Minuet IV + Sword Madrigal

**Important :** Plus besoin de configurer les songs manuellement ! Le système les assigne automatiquement selon le rôle.

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

**Sur le Bard (Debybrown) :**
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as BARD (job: BRD)
[SongService] Configured healer Deedeebrown with mage songs
[SongService] Configured main Dexterbrown with melee songs
[SongService] ✅ SongService initialized as BARD
[SongService] Role: BARD
[SongService] State: IDLE
```

**Sur les Clients (Dexterbrown, Deedeebrown) :**
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as CLIENT
[SongService] ✅ SongService initialized as CLIENT
[SongService] Role: CLIENT
```

### 4. Engage un mob avec le Main
```
// Sur Dexterbrown
/assist <p1>
/attack <bt>
```

### 5. Observer le comportement

**Bard (Debybrown) :**
- Hors combat → suit Main
- Combat + queue vide → **suit Healer** ✅
- Combat + requête → **traite le healer en PRIORITÉ**, puis les autres
- Retourne suivre le healer après chaque cast

**Clients (Dexterbrown, Deedeebrown) :**
- Hors combat → rien
- Combat → checkent buffs avec délai initial :
  - **Healer** : check à 5s, puis toutes les 30s
  - **Main** : check à 20s, puis toutes les 30s
- Buff manquant → envoient requête au Bard

### 6. Logs à surveiller

**Sur le Bard (Debybrown) :**
```
[SongService] Queued 2 songs for Deedeebrown
[SongService] PRIORITY: Moving to healer Deedeebrown first
[SongService] Arrived at Deedeebrown, starting cast sequence
[SongService] Casting: Mage's Ballad II for Deedeebrown (remaining: 1)
[SongService] Casting: Army's Paeon IV for Deedeebrown (remaining: 0)
[SongService] Finished casting for Deedeebrown
[SongService] Queued 2 songs for Dexterbrown
[SongService] Moving to Dexterbrown to cast songs
[SongService] Casting: Valor Minuet IV for Dexterbrown (remaining: 1)
[SongService] Casting: Sword Madrigal for Dexterbrown (remaining: 0)
[SongService] No songs to cast → STANDBY
```

**Sur les Clients :**
```
[SongService] Missing buffs: Mage's Ballad II, Army's Paeon IV → requesting ALL songs
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

## Améliorations Version 2.0

- [x] ✅ Priorité dans la queue (healer > DPS)
- [x] ✅ Détection automatique du Bard (par job BRD)
- [x] ✅ Configuration universelle (party_roles.json)
- [x] ✅ Auto-configuration des songs selon le rôle
- [ ] ⏳ Support multi-bards
- [ ] ⏳ Interface webapp pour voir la queue
- [ ] ⏳ Cooldown entre requêtes (éviter spam)

---

**Bon test ! 🎵**
