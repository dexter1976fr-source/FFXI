# AltControl - Architecture Split Core + Extended

## 🎯 Vue d'ensemble

AltControl est maintenant divisé en 2 modules pour optimiser les performances :

- **Core** : Ultra léger, toujours actif, 0 ralentissement
- **Extended** : Toutes les fonctionnalités, chargé à la demande

## 📦 Architecture

```
AltControl/
├── AltControl.lua          # Core (ultra léger)
├── AltControlExtended.lua  # Extended (fonctionnalités)
├── AutoCast.lua            # Module AutoCast
├── AutoCast_BRD.lua        # Module BRD spécifique
└── tools/
    ├── AutoEngage.lua      # Tool AutoEngage
    └── DistanceFollow.lua  # Tool DistanceFollow
```

## 🚀 Fonctionnement

### Démarrage automatique

Quand tu lances FFXI avec AltControl :

1. **Core se charge** (ultra léger)
2. **Extended se charge automatiquement**
3. **Socket TCP s'ouvre** (pour recevoir les commandes de la webapp)
4. **Tout fonctionne** (AutoCast, AutoEngage, webapp, etc.)

### Contrôle manuel

Tu peux charger/décharger Extended à tout moment :

```lua
//ac alloff  -- Décharge Extended sur TOUS les alts
//ac allon   -- Charge Extended sur TOUS les alts
//ac status  -- Affiche l'état (Core + Extended)
```

## 💡 Cas d'usage

### Utilisation normale (avec webapp)

```
1. Lancer FFXI
   → Core + Extended chargés automatiquement
   
2. Démarrer le serveur Python
   → Webapp fonctionnelle
   
3. Utiliser normalement
   → Tout fonctionne
```

### Jeu sans webapp (performance maximale)

```
1. Lancer FFXI
   → Core + Extended chargés automatiquement
   
2. Décharger Extended
   → //ac alloff
   
3. Jouer normalement
   → Jeu ultra fluide (Core seul)
```

### Relancer Extended après l'avoir arrêté

```
1. Extended est déchargé
   → Jeu fluide
   
2. Tu veux utiliser la webapp
   → //ac allon
   
3. Extended se recharge
   → Webapp fonctionne à nouveau
```

## 🎮 Commandes disponibles

### Commandes globales (tous les alts)

```lua
//ac allon   -- Charge Extended sur tous les alts
//ac alloff  -- Décharge Extended sur tous les alts
```

Ces commandes utilisent `/console send @all` pour affecter tous les alts simultanément.

### Commandes individuelles (un seul alt)

```lua
//ac load_extended    -- Charge Extended sur cet alt uniquement
//ac unload_extended  -- Décharge Extended sur cet alt uniquement
//ac status           -- Affiche l'état de cet alt
```

## 📊 Comparaison des performances

### Core seul (Extended déchargé)

- ✅ 0 socket TCP
- ✅ 0 boucle active
- ✅ 0 ralentissement
- ❌ Webapp ne fonctionne pas
- ❌ AutoCast désactivé

### Core + Extended (chargé)

- ✅ Webapp fonctionnelle
- ✅ AutoCast actif
- ✅ AutoEngage actif
- ✅ DistanceFollow actif
- ⚠️ Socket TCP actif (léger ralentissement possible)

## 🔧 Détails techniques

### Core (AltControl.lua)

**Responsabilités :**
- Créer le fichier de config (port)
- Charger Extended automatiquement au démarrage
- Gérer les commandes `allon` / `alloff` / `load_extended` / `unload_extended`
- Afficher les messages d'état

**Ce qu'il ne fait PAS :**
- Pas de socket TCP
- Pas de boucle active
- Pas d'envoi de données au serveur Python

### Extended (AltControlExtended.lua)

**Responsabilités :**
- Socket TCP pour recevoir les commandes de la webapp
- Envoi des données au serveur Python (toutes les 0.1 secondes)
- Gestion des modules (AutoCast, AutoEngage, DistanceFollow)
- Gestion des events Windower (job_change, equip_change, etc.)

**Chargement/Déchargement :**
- `Extended.initialize()` : Démarre le socket TCP et les boucles
- `Extended.shutdown()` : Ferme le socket TCP et arrête tout proprement

## 🎯 Workflow recommandé

### Pour une utilisation quotidienne

```
1. Lancer FFXI
   → Tout se charge automatiquement
   
2. Démarrer le serveur Python
   → Webapp prête à l'emploi
   
3. Utiliser normalement
   → Profiter de toutes les fonctionnalités
```

### Pour un jeu sans webapp (performance max)

```
1. Lancer FFXI
   → Tout se charge automatiquement
   
2. Décharger Extended
   → //ac alloff
   
3. Jouer sans ralentissement
   → Core ultra léger
```

### Pour alterner entre les deux

```
1. Jeu normal
   → Extended chargé
   
2. Besoin de performance
   → //ac alloff
   
3. Besoin de la webapp
   → //ac allon
```

## 📝 Notes importantes

### Chargement automatique au démarrage

Extended se charge **automatiquement** quand le Core démarre. Tu n'as rien à faire.

Si tu ne veux pas qu'Extended se charge automatiquement, tu peux modifier `AltControl.lua` et commenter la section d'auto-load.

### Socket TCP

Le socket TCP est **uniquement dans Extended**. Quand Extended est déchargé, le socket est fermé proprement.

Le Core n'a **aucun socket TCP**, donc 0 ralentissement quand Extended est off.

### Serveur Python

Le serveur Python peut rester actif en permanence. Il n'essaie plus de charger/décharger Extended automatiquement.

Tu contrôles tout manuellement avec `//ac allon` et `//ac alloff`.

## 🐛 Dépannage

### Extended ne se charge pas au démarrage

Vérifier dans la console Windower :
```
[AltControl] ✅ Core initialized for [Nom]
[AltControl] 🚀 Auto-loading Extended features...
[Extended] 🚀 Initializing features...
[Extended] ✅ TCP listener started on port 5XXX
[Extended] ✅ All features initialized
[AltControl] ✅ Extended features loaded
```

Si tu ne vois pas ces messages, il y a une erreur. Vérifie que `AltControlExtended.lua` existe.

### La webapp ne répond pas

1. Vérifier qu'Extended est chargé : `//ac status`
2. Si Extended est NOT LOADED : `//ac allon`
3. Vérifier que le serveur Python est actif
4. Vérifier les erreurs dans la console Python

### Le jeu ralentit

1. Décharger Extended : `//ac alloff`
2. Vérifier si le ralentissement persiste
3. Si oui, le problème vient d'ailleurs (autre addon?)
4. Si non, c'est Extended qui cause le ralentissement

### //ac allon ne fonctionne pas

Vérifier que tu es bien sur le personnage principal (celui qui envoie la commande).

La commande utilise `/console send @all`, donc elle affecte tous les alts connectés.

## 📚 Documentation complémentaire

- `GUIDE_ALLON_ALLOFF.md` - Guide détaillé des commandes
- `SESSION_ALLON_ALLOFF_FINAL.md` - Récapitulatif de la session de développement
- `TEST_CORE_ULTRA_LEGER.md` - Guide de test du système

## 🎉 Avantages de cette architecture

1. **Performance optimale**
   - Core ultra léger (0 ralentissement)
   - Extended chargé uniquement quand nécessaire

2. **Flexibilité**
   - Peut jouer sans webapp (Core seul)
   - Peut utiliser webapp (Core + Extended)
   - Peut alterner à volonté

3. **Simplicité**
   - 2 commandes faciles à retenir (`allon` / `alloff`)
   - Chargement automatique au démarrage
   - Pas de configuration complexe

4. **Fiabilité**
   - Pas de timing automatique qui peut échouer
   - Contrôle manuel total
   - Déchargement propre des ressources

---

**Version :** 2.0.0 (Split Core + Extended)  
**Date :** 23 Novembre 2025  
**Commit :** 62e8b3f
