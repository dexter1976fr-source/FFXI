# GUIDE COMMANDES ALLON / ALLOFF

## 🎯 Solution finale pour gérer Extended

Au lieu de laisser le serveur Python gérer automatiquement le chargement/déchargement d'Extended, tu contrôles tout manuellement avec 2 commandes simples.

## ✅ Commandes disponibles

### `//ac allon`
**Charge Extended sur TOUS les alts en même temps**

```lua
//ac allon
```

Ce que ça fait :
- Envoie `/console send @all input //ac load_extended`
- Tous les alts chargent Extended simultanément
- Le socket TCP de chaque alt devient actif
- La webapp peut maintenant envoyer des commandes

### `//ac alloff`
**Décharge Extended sur TOUS les alts en même temps**

```lua
//ac alloff
```

Ce que ça fait :
- Envoie `/console send @all input //ac unload_extended`
- Tous les alts déchargent Extended simultanément
- Les sockets TCP sont fermés proprement
- Le jeu redevient ultra fluide (Core seul)

## 🚀 Workflow recommandé

### Démarrage
```
1. Lancer FFXI avec tous tes alts
2. Le Core se charge automatiquement (ultra léger)
3. Démarrer le serveur Python
4. Dans FFXI : //ac allon
5. Utiliser la webapp normalement
```

### Arrêt
```
1. Dans FFXI : //ac alloff
2. Arrêter le serveur Python
3. Continuer à jouer (Core reste, 0 lag)
```

## 💡 Avantages de cette solution

### 1. Contrôle total
- Tu décides quand charger/décharger Extended
- Pas de timing automatique qui peut échouer
- Simple et prévisible

### 2. Performance optimale
- Core ultra léger (socket TCP minimal)
- Extended chargé uniquement quand tu en as besoin
- Jeu fluide quand Extended est off

### 3. Simplicité
- 2 commandes faciles à retenir
- Pas besoin de commandes individuelles par alt
- Fonctionne sur tous les alts en même temps

## 🧪 Test rapide

### Test 1 : Vérifier que le Core fonctionne
```lua
//lua r altcontrol
```

Tu devrais voir :
```
[AltControl] ✅ Core initialized for [Nom]
[AltControl] Port: 5XXX
[AltControl] 💡 Quick commands:
[AltControl]   //ac allon  = Load Extended on ALL alts
[AltControl]   //ac alloff = Unload Extended on ALL alts
```

### Test 2 : Charger Extended
```lua
//ac allon
```

Sur chaque alt, tu devrais voir :
```
[AltControl] Loading Extended features...
[Extended] 🚀 Initializing features...
[Extended] ✅ All features initialized
[AltControl] ✅ Extended features loaded
```

### Test 3 : Vérifier le status
```lua
//ac status
```

Tu devrais voir :
```
[AltControl] Core: ACTIVE
[AltControl] Extended: LOADED
```

### Test 4 : Décharger Extended
```lua
//ac alloff
```

Sur chaque alt, tu devrais voir :
```
[AltControl] Unloading Extended features...
[Extended] 🛑 Shutting down features...
[Extended] ✅ All features stopped
[AltControl] ✅ Extended features unloaded
```

## 📋 Commandes individuelles (si besoin)

Si tu veux gérer un seul alt :

```lua
//ac load_extended    -- Charger Extended sur cet alt uniquement
//ac unload_extended  -- Décharger Extended sur cet alt uniquement
//ac status           -- Voir l'état de cet alt
```

## 🔧 Architecture finale

```
┌─────────────────────────────────────────────────────────┐
│                    FFXI + Windower                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  AltControl CORE (léger)                         │  │
│  │  - write_connection_file()                       │  │
│  │  - get_auto_port()                               │  │
│  │  - listen_for_commands() ← Socket TCP minimal   │  │
│  │  - Commandes: allon, alloff, load, unload       │  │
│  └──────────────────────────────────────────────────┘  │
│                          │                              │
│                          │ //ac allon                   │
│                          ▼                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  AltControl EXTENDED (fonctionnalités)           │  │
│  │  - send_alt_info()                               │  │
│  │  - AutoCast, AutoEngage, DistanceFollow         │  │
│  │  - Chargé manuellement avec //ac allon          │  │
│  └──────────────────────────────────────────────────┘  │
│                          ▲                              │
└──────────────────────────┼──────────────────────────────┘
                           │ TCP
                           │
┌──────────────────────────┼──────────────────────────────┐
│                          │                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Python Server (FFXI_ALT_Control.py)             │  │
│  │  - Reçoit les données des alts                   │  │
│  │  - Envoie les commandes de la webapp            │  │
│  │  - N'a plus besoin de gérer load/unload         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  React WebApp                                     │  │
│  │  - Interface de contrôle                         │  │
│  │  - Envoie commandes via Python                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Pourquoi cette solution est meilleure

### Avant (automatique)
- ❌ Serveur Python essaie de charger Extended trop tôt
- ❌ Erreurs de connexion au démarrage
- ❌ Timing imprévisible
- ❌ Difficile à débugger

### Maintenant (manuel)
- ✅ Tu contrôles quand charger Extended
- ✅ Pas d'erreurs de timing
- ✅ Simple et prévisible
- ✅ Facile à débugger

## 📝 Notes importantes

1. **Core toujours actif**
   - Le Core reste chargé en permanence
   - Socket TCP minimal (juste pour recevoir les commandes)
   - Très léger, pas de ralentissement notable

2. **Extended à la demande**
   - Charge uniquement quand tu utilises la webapp
   - Décharge quand tu as fini
   - Libère les ressources proprement

3. **Serveur Python**
   - Peut rester actif en permanence
   - N'essaie plus de gérer load/unload automatiquement
   - Juste un relais entre webapp et FFXI

## 🚀 Macro recommandée

Tu peux créer une macro Windower pour encore plus de rapidité :

```lua
/console ac allon
```

Ou dans ton fichier `init.txt` de Windower :
```
alias allon ac allon
alias alloff ac alloff
```

Ensuite tu peux juste taper :
```
//allon
//alloff
```

---

**C'est prêt ! Teste avec `//ac allon` et dis-moi si ça marche ! 🎮**
