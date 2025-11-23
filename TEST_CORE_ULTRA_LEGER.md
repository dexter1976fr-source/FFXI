# TEST CORE ULTRA LÉGER - TCP dans Extended

## 🎯 Objectif
Le Core ne fait plus RIEN qui ralentit. `listen_for_commands()` est maintenant dans Extended.

## ✅ Modifications appliquées

### Core (AltControl.lua)
- ❌ Retiré `listen_for_commands()` complètement
- ❌ Retiré l'appel dans `initialize_after_login()`
- ✅ Core ne fait que créer le fichier de config
- ✅ 0 socket, 0 boucle, 0 ralentissement

### Extended (AltControlExtended.lua)
- ✅ Ajouté `listen_for_commands()` dans `initialize()`
- ✅ Ajouté `stop_listening()` dans `shutdown()`
- ✅ Socket fermé proprement quand Extended est déchargé

### Python (FFXI_ALT_Control.py)
- ✅ Envoie déjà `//ac load_extended` au démarrage
- ✅ Envoie `//ac unload_extended` à l'arrêt

## 🧪 Test 1 : Core seul (ULTRA LÉGER)

1. Dans FFXI : `//lua r altcontrol`
2. Tu devrais voir :
   ```
   [AltControl] ✅ Core initialized for [Nom]
   [AltControl] Port: 5XXX
   [AltControl] Load Extended with: //ac load_extended
   ```
3. **NE PAS démarrer le serveur Python**
4. **Jouer normalement pendant 1-2 minutes**
5. **Vérifier si le jeu est fluide**

### ✅ Résultat attendu
- Le jeu doit être **100% fluide**
- Aucun ralentissement
- Core ne fait RIEN (juste le fichier de config)

### ❌ Si ça rame encore
- Alors le problème vient d'ailleurs (autre addon?)
- Tester : `//lua u altcontrol` pour confirmer

## 🧪 Test 2 : Core + Extended (FONCTIONNEL)

1. Démarrer le serveur Python
2. Le serveur envoie automatiquement `//ac load_extended`
3. Tu devrais voir :
   ```
   [AltControl] Loading Extended features...
   [Extended] 🚀 Initializing features...
   [Extended] ✅ TCP listener started on port 5XXX
   [Extended] ✅ All features initialized
   [AltControl] ✅ Extended features loaded
   ```
4. **Tester la webapp** (commandes, AutoCast, etc.)

### ✅ Résultat attendu
- Tout fonctionne comme avant
- Webapp peut envoyer des commandes
- AutoCast, AutoEngage, DistanceFollow OK

## 🧪 Test 3 : Arrêt du serveur (DÉCHARGEMENT)

1. **Arrêter le serveur Python**
2. Le serveur envoie `//ac unload_extended`
3. Tu devrais voir :
   ```
   [Extended] 🛑 Shutting down features...
   [Extended] ✅ TCP listener stopped
   [Extended] ✅ All features stopped
   [AltControl] ✅ Extended features unloaded
   ```
4. **Jouer normalement pendant 1-2 minutes**
5. **Vérifier si le jeu est fluide**

### ✅ Résultat attendu
- Le jeu doit être **100% fluide**
- Aucun ralentissement
- Core reste chargé mais ne fait RIEN

## 🎯 Commandes manuelles

Si besoin de tester manuellement :

```lua
//ac status              -- Voir l'état (Core ACTIVE, Extended LOADED/NOT LOADED)
//ac load_extended       -- Charger Extended manuellement
//ac unload_extended     -- Décharger Extended manuellement
//lua u altcontrol       -- Décharger complètement (Core + Extended)
//lua r altcontrol       -- Recharger le Core seul
```

## 📊 Diagnostic

### Si Core seul rame :
- Le problème n'est PAS AltControl
- Vérifier les autres addons : `//lua list`
- Tester en déchargeant tout : `//lua unloadall`

### Si Extended rame :
- C'est normal, Extended fait beaucoup de choses
- Mais tu peux le décharger quand tu ne l'utilises pas
- Le serveur Python le charge/décharge automatiquement

### Si tout est fluide :
- 🎉 **SUCCÈS !** Le split fonctionne parfaitement
- Core ultra léger (0 ralentissement)
- Extended chargé uniquement quand nécessaire

## 🚀 Workflow final

1. **Démarrage FFXI** → Core chargé (ultra léger, 0 lag)
2. **Démarrage serveur Python** → Extended chargé automatiquement
3. **Utilisation webapp** → Tout fonctionne
4. **Arrêt serveur Python** → Extended déchargé automatiquement
5. **Jeu fluide** → Core reste mais ne fait rien

## 🎯 Avantages

- ✅ Core ultra léger (0 ralentissement)
- ✅ Extended chargé uniquement quand nécessaire
- ✅ Pas besoin de décharger manuellement
- ✅ Serveur Python gère tout automatiquement
- ✅ Jeu fluide quand serveur arrêté

---

**Teste et dis-moi ce que ça donne ! 🔍**
