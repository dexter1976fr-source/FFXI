# 🧪 TEST SONGSERVICE UNIVERSEL - Checklist

## ✅ PRÉ-REQUIS

- [ ] Projet nettoyé (version 2.0.0)
- [ ] `party_roles.json` contient les bons noms
- [ ] `alt_configs.json` existe avec les configs des alts
- [ ] Section `SongService` supprimée de `autocast_config.json`

## 🎯 TEST 1 : INITIALISATION

### Sur Debybrown (BRD)
```
//lua r altcontrol
//ac songservice status
```

**Attendu** :
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as BARD (job: BRD)
[SongService] Configured healer Deedeebrown with mage songs
[SongService] Configured main Dexterbrown with melee songs
[SongService] Song configs loaded for 2 clients
[SongService] ✅ SongService initialized as BARD
```

- [ ] Pas d'erreur "Config file not found"
- [ ] Pas d'erreur "SongService config not found"
- [ ] Rôle détecté : BARD
- [ ] 2 clients configurés

### Sur Deedeebrown (Healer)
```
//lua r altcontrol
//ac songservice status
```

**Attendu** :
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as CLIENT
[SongService] ✅ SongService initialized as CLIENT
```

- [ ] Rôle détecté : CLIENT
- [ ] Pas d'erreur

### Sur Dexterbrown (Main)
```
//lua r altcontrol
//ac songservice status
```

**Attendu** :
```
[SongService] 🎵 Universal SongService initializing...
[SongService] Party roles loaded: Main=Dexterbrown, Healer=Deedeebrown, Bard=Debybrown
[SongService] AUTO-DETECTED as CLIENT
[SongService] ✅ SongService initialized as CLIENT
```

- [ ] Rôle détecté : CLIENT
- [ ] Pas d'erreur

## 🎯 TEST 2 : DÉMARRAGE

### Sur tous les personnages
```
//ac songservice start
```

**Vérifier** :
- [ ] Debybrown : "Disabling DistanceFollow"
- [ ] Deedeebrown : "Starting follow on: Dexterbrown"
- [ ] Dexterbrown : "Starting follow on: Dexterbrown"
- [ ] Aucune erreur

## 🎯 TEST 3 : PRIORITÉ HEALER

### Scénario
1. Engager un mob avec Dexterbrown
2. Attendre 5 secondes (Deedeebrown va demander des songs)
3. Attendre 20 secondes (Dexterbrown va demander des songs)

### Observer sur Debybrown

**Après 5 secondes** :
```
[SongService] Missing buffs: Mage's Ballad II, Army's Paeon IV → requesting ALL songs
[SongService] Queued 2 songs for Deedeebrown
[SongService] PRIORITY: Moving to healer Deedeebrown first
[SongService] Arrived at Deedeebrown, starting cast sequence
[SongService] Casting: Mage's Ballad II for Deedeebrown (remaining: 1)
[SongService] Casting: Army's Paeon IV for Deedeebrown (remaining: 0)
[SongService] Finished casting for Deedeebrown
```

- [ ] Healer traité en premier
- [ ] 2 songs castés
- [ ] Pas d'erreur de mouvement

**Après 20 secondes** :
```
[SongService] Missing buffs: Valor Minuet IV, Sword Madrigal → requesting ALL songs
[SongService] Queued 2 songs for Dexterbrown
[SongService] Moving to Dexterbrown to cast songs
[SongService] Arrived at Dexterbrown, starting cast sequence
[SongService] Casting: Valor Minuet IV for Dexterbrown (remaining: 1)
[SongService] Casting: Sword Madrigal for Dexterbrown (remaining: 0)
[SongService] Finished casting for Dexterbrown
```

- [ ] Main traité après le healer
- [ ] 2 songs castés
- [ ] Pas d'erreur

## 🎯 TEST 4 : REQUÊTES SIMULTANÉES

### Scénario
1. Laisser expirer tous les buffs sur les 2 clients
2. Les deux vont demander en même temps

### Observer
- [ ] Le healer est **toujours** traité en premier
- [ ] Pas de conflit
- [ ] Tous les songs sont castés

## 🎯 TEST 5 : RECAST AUTOMATIQUE

### Scénario
1. Rester en combat pendant 3-4 minutes
2. Les buffs vont expirer naturellement

### Observer
- [ ] Healer demande des songs toutes les ~30s (après 5s initial)
- [ ] Main demande des songs toutes les ~30s (après 20s initial)
- [ ] BRD recast automatiquement
- [ ] Priorité healer maintenue

## 📊 RÉSULTATS

### ✅ Succès
- Initialisation universelle fonctionne
- Détection automatique du rôle
- Priorité healer respectée
- Recast automatique opérationnel

### ❌ Problèmes rencontrés
_(Noter ici les problèmes)_

### 📝 Notes
_(Observations supplémentaires)_

---

## 🎉 VALIDATION FINALE

- [ ] Tous les tests passent
- [ ] Aucune erreur dans les logs
- [ ] Système stable pendant 5+ minutes de combat
- [ ] Priorité healer toujours respectée

**Date du test** : _____________
**Testeur** : _____________
**Statut** : ⏳ En attente / ✅ Validé / ❌ Échec
