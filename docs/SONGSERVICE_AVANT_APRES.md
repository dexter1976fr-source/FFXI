# 🎵 SONGSERVICE : AVANT vs APRÈS

## 📊 COMPARAISON VISUELLE

### AVANT : Système hardcodé ❌

```
autocast_config.json
├── BRD: {...}
└── SongService:
    ├── mainCharacter: "Dexterbrown"      ← Hardcodé
    ├── healerCharacter: "Deedeebrown"    ← Hardcodé
    ├── bardName: "Debybrown"             ← Hardcodé
    └── clients:
        ├── Dexterbrown: [songs...]       ← Hardcodé
        └── Deedeebrown: [songs...]       ← Hardcodé
```

**Problèmes** :
- ❌ Noms hardcodés dans la config
- ❌ Difficile à partager avec d'autres joueurs
- ❌ Pas de priorité healer
- ❌ Maintenance complexe

---

### APRÈS : Système universel ✅

```
party_roles.json                    alt_configs.json
├── main_character                  ├── alt1_config
├── alt1 (healer)                   │   └── alt_name: "Deedeebrown"
└── alt2 (bard)                     └── alt2_config
                                        └── alt_name: "Debybrown"
         ↓                                    ↓
    SongService.lua
    ├── load_party_roles()          ← Lit party_roles.json
    ├── load_song_configs()         ← Lit alt_configs.json
    ├── detect_role()               ← Auto-détecte BRD/CLIENT
    └── process_casting()
        └── PRIORITÉ HEALER         ← Healer toujours en premier
```

**Avantages** :
- ✅ Configuration universelle
- ✅ Auto-détection du rôle
- ✅ Priorité healer garantie
- ✅ Partageable avec tout le monde
- ✅ Maintenance via web app

---

## 🔄 FLUX DE DONNÉES

### AVANT
```
1. Lire autocast_config.json
2. Extraire section "SongService"
3. Charger noms hardcodés
4. Charger songs hardcodés
5. Démarrer le service
```

### APRÈS
```
1. Lire party_roles.json          → Qui est qui ?
2. Lire alt_configs.json           → Qui existe ?
3. Auto-détecter rôle (BRD/CLIENT) → Quel est mon rôle ?
4. Configurer songs selon rôle     → Quels songs pour qui ?
5. Démarrer avec priorité healer   → Ordre de traitement
```

---

## 🎯 LOGIQUE DE PRIORITÉ

### AVANT : Ordre aléatoire
```lua
-- Prendre n'importe quel target
for target, _ in pairs(requests) do
    current_target = target  -- ← Aléatoire !
    break
end
```

**Résultat** : Le BRD peut aller chez le main avant le healer → Risque de wipe

---

### APRÈS : Healer en premier
```lua
-- Vérifier si le healer a des requêtes
if healer_name and requests[healer_name] then
    current_target = healer_name  -- ← Priorité !
    log("PRIORITY: Moving to healer first")
else
    -- Sinon, prendre un autre target
    for target, _ in pairs(requests) do
        current_target = target
        break
    end
end
```

**Résultat** : Le healer est **toujours** traité en premier → Sécurité du groupe

---

## 📝 EXEMPLE CONCRET

### Scénario : Combat avec 2 clients

**AVANT** :
```
T+5s  : Healer demande songs
T+20s : Main demande songs
        → BRD va chez le main (aléatoire)
        → Healer attend
        → Risque de manquer de MP
```

**APRÈS** :
```
T+5s  : Healer demande songs
        → BRD va chez le healer (priorité)
        → Cast Ballad + Paeon
T+20s : Main demande songs
        → BRD va chez le main
        → Cast Minuet + Madrigal
        → Healer déjà servi, groupe sécurisé
```

---

## 🔧 CONFIGURATION

### AVANT : Modifier le code
```json
// autocast_config.json
"SongService": {
  "mainCharacter": "VotreNom",      ← Changer ici
  "healerCharacter": "VotreHealer", ← Et ici
  "bardName": "VotreBard",          ← Et ici
  "clients": {
    "VotreNom": ["song1", "song2"], ← Et ici
    "VotreHealer": ["song3", "song4"] ← Et ici
  }
}
```

**Problème** : 5 endroits à modifier, risque d'erreur

---

### APRÈS : Modifier 1 fichier
```json
// party_roles.json
{
  "main_character": "VotreNom",
  "alt1": "VotreHealer",
  "alt2": "VotreBard"
}
```

**Avantage** : 1 seul fichier, songs configurés automatiquement

---

## 📊 STATISTIQUES

| Métrique | Avant | Après |
|----------|-------|-------|
| Fichiers de config | 1 | 2 |
| Lignes de config | ~20 | ~5 |
| Noms hardcodés | 5+ | 0 |
| Auto-détection | ❌ | ✅ |
| Priorité healer | ❌ | ✅ |
| Partageable | ❌ | ✅ |
| Maintenance | Difficile | Facile |

---

## 🎉 RÉSULTAT FINAL

### Code supprimé
- ❌ 40 lignes de config hardcodée
- ❌ Section "SongService" dans autocast_config.json

### Code ajouté
- ✅ `load_party_roles()` - 15 lignes
- ✅ `load_song_configs()` - 30 lignes
- ✅ Priorité healer - 10 lignes

### Bénéfices
- 🎯 Système 100% universel
- 🔄 Auto-configuration
- 🛡️ Sécurité du groupe (priorité healer)
- 🚀 Partageable avec la communauté
- 🔧 Maintenance simplifiée

---

**Version** : 2.0.0 - Refonte Universelle
**Impact** : 🟢 Majeur - Amélioration significative
**Compatibilité** : ✅ Rétrocompatible (ancienne config ignorée)
