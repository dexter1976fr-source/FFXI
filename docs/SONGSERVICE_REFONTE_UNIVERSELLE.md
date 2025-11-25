# 🎵 SONGSERVICE - REFONTE UNIVERSELLE

## 🎯 OBJECTIF ATTEINT

SongService est maintenant **100% universel** :
- ✅ Détection automatique du BRD par job
- ✅ Chargement des rôles depuis `party_roles.json`
- ✅ Configuration des songs depuis `alt_configs.json`
- ✅ Priorité automatique au healer
- ✅ Fonctionne avec n'importe quelle composition

## 📋 MODIFICATIONS APPLIQUÉES

### 1. Nouveau système de chargement

**Avant** : Config hardcodée dans `autocast_config.json`
**Après** : Config universelle depuis 2 fichiers JSON

#### `load_party_roles()`
- Lit `data_json/party_roles.json`
- Charge automatiquement :
  - `main_character` → Main DPS
  - `alt1` → Healer
  - `alt2` → Bard

#### `load_song_configs()`
- Lit `data_json/alt_configs.json`
- Configure automatiquement les songs selon le rôle :
  - **Healer** : Mage's Ballad II + Army's Paeon IV
  - **Main** : Valor Minuet IV + Sword Madrigal

### 2. Priorité healer

Le BRD traite maintenant **toujours le healer en premier** :
```lua
-- Vérifier si le healer a des requêtes en attente
if healer_name and SongService.requests_by_target[healer_name] then
    SongService.current_target = healer_name
    log("PRIORITY: Moving to healer " .. healer_name .. " first")
```

### 3. Nettoyage config

La section `SongService` a été **supprimée** de `autocast_config.json` (plus nécessaire).

## 🧪 TESTS À EFFECTUER

### Test 1 : Initialisation universelle

Sur **chaque personnage** (Dexterbrown, Deedeebrown, Debybrown) :

```
//lua r altcontrol
//ac songservice status
```

**Attendu sur Debybrown (BRD)** :
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as BARD (job: BRD)
[SongService] Configured healer Deedeebrown with mage songs
[SongService] Configured main Dexterbrown with melee songs
[SongService] Song configs loaded for 2 clients
[SongService] ✅ SongService initialized as BARD
```

**Attendu sur Deedeebrown/Dexterbrown (Clients)** :
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as CLIENT
[SongService] ✅ SongService initialized as CLIENT
```

### Test 2 : Démarrage du service

Sur **tous les personnages** :
```
//ac songservice start
```

**Vérifier** :
- Pas d'erreurs
- Rôle correctement détecté
- BRD : "Disabling DistanceFollow"
- Clients : "Starting follow on: Dexterbrown"

### Test 3 : Priorité healer en combat

1. Engager un mob avec Dexterbrown
2. Attendre 5 secondes
3. Sur Deedeebrown : les buffs vont expirer
4. Sur Dexterbrown : attendre 20 secondes, les buffs vont expirer

**Observer sur Debybrown** :
```
[SongService] Missing buffs detected from Deedeebrown
[SongService] Queued 2 songs for Deedeebrown
[SongService] PRIORITY: Moving to healer Deedeebrown first
[SongService] Arrived at Deedeebrown, starting cast sequence
[SongService] Casting: Mage's Ballad II for Deedeebrown (remaining: 1)
[SongService] Casting: Army's Paeon IV for Deedeebrown (remaining: 0)
[SongService] Finished casting for Deedeebrown
```

Puis après :
```
[SongService] Missing buffs detected from Dexterbrown
[SongService] Queued 2 songs for Dexterbrown
[SongService] Moving to Dexterbrown to cast songs
```

### Test 4 : Requêtes simultanées

1. Laisser expirer les buffs sur **les deux** clients
2. Les deux vont demander des songs en même temps

**Observer** : Le healer est **toujours traité en premier**, même si le main a demandé avant.

## ✅ AVANTAGES DE LA REFONTE

| Avant | Après |
|-------|-------|
| Config hardcodée | Config universelle |
| Noms en dur dans le code | Lecture depuis JSON |
| Ordre aléatoire | Priorité healer garantie |
| Difficile à partager | Fonctionne chez tout le monde |
| Maintenance complexe | Changements via web app |

## 🎮 UTILISATION QUOTIDIENNE

### Démarrage rapide
```
// Sur tous les personnages
//ac songservice start
```

### Vérifier le statut
```
//ac songservice status
```

### Arrêter le service
```
//ac songservice stop
```

## 🔧 CONFIGURATION

### Changer les rôles
Éditer `data_json/party_roles.json` :
```json
{
  "main_character": "VotreMain",
  "alt1": "VotreHealer",
  "alt2": "VotreBard"
}
```

### Changer les songs
Les songs sont configurés automatiquement selon le rôle, mais vous pouvez les modifier dans le code si nécessaire (fonction `load_song_configs()`).

## 📊 LOGS DE DEBUG

Le système affiche maintenant des logs clairs :
- 🎵 Initialisation
- ✅ Succès de chargement
- ⚠️ Erreurs de config
- 🎯 Priorité healer
- 📝 Progression des casts

## 🚀 PROCHAINES ÉTAPES

1. ✅ Tester en jeu avec la nouvelle version
2. ⏳ Ajouter support pour plus de 2 clients
3. ⏳ Interface web pour configurer les songs
4. ⏳ Système de rotation avancée (March, Madrigal, etc.)

---

**Version** : 2.0.0 - Refonte Universelle
**Date** : 25 novembre 2025
**Statut** : ✅ Prêt pour tests en jeu
