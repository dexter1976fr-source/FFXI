# 🧪 TEST - Nouveau Système BRD v2.0

## Ce qui a été créé

### 1. AutoCast_BRD.lua ✅
- Système de queue pour les songs
- Follow avec distance automatique
- Chargement de la config depuis JSON
- Traitement automatique de la queue

### 2. AltControl.lua ✅
- Commande `//ac follow <nom>`
- Commande `//ac queue_song <song> <target>`
- Intégration avec le module BRD

### 3. FFXI_ALT_Control.py ✅
- Thread BRD Manager intelligent
- Check mage → Queue 2 songs → Attend inactif
- Check melee → Follow melee → Queue 2 songs → Attend inactif → Retour healer
- Loop toutes les 10 secondes

### 4. Fichiers copiés dans Windower ✅

## Comment tester

### Étape 1: Démarrer le serveur Python
```
Cliquer sur "ON / OFF Servers" dans le GUI
```

### Étape 2: Dans le jeu (BRD)
```
//lua r altcontrol
```

### Étape 3: Cliquer sur le bouton AutoCast dans la Web App
```
Bouton "🎵 Auto: OFF" → Passe à "ON"
```

### Étape 4: Engager en combat
```
Attaquer un mob
```

## Ce qui devrait se passer

1. **Au clic du bouton:**
   - BRD charge la config
   - BRD follow le healer

2. **Quand quelqu'un engage:**
   - Serveur check les buffs mage
   - Si manquants → Queue 2 songs mages
   - BRD cast les 2 songs
   - Serveur attend que BRD soit inactif 2 sec

3. **Ensuite:**
   - Serveur check les buffs melee
   - Si manquants → BRD follow le melee
   - Queue 2 songs melees
   - BRD cast les 2 songs
   - BRD retourne au healer

4. **Loop:**
   - Recommence toutes les 10 secondes

## Logs attendus

### Windower (BRD)
```
[BRD] ✅ Config loaded
[BRD] Healer: Deedeebrown
[BRD] Melee: Dexterbrown
[BRD] 🎯 Following: Deedeebrown
[BRD] 📋 Queued: Mage's Ballad II
[BRD] 📋 Queued: Mage's Ballad III
[BRD] 🎵 Casting: Mage's Ballad II
[BRD] 🎵 Casting: Mage's Ballad III
[BRD] 🎯 Following: Dexterbrown
[BRD] 📋 Queued: Valor Minuet V
[BRD] 📋 Queued: Sword Madrigal
[BRD] 🎵 Casting: Valor Minuet V
[BRD] 🎵 Casting: Sword Madrigal
[BRD] 🎯 Following: Deedeebrown
```

### Serveur Python
```
[BRD Manager] Thread started
[BRD Manager] Mage buffs missing: ['Ballad', 'March']
[COMMAND] '//ac queue_song "Mage's Ballad II" <me>' → Debybrown
[COMMAND] '//ac queue_song "Mage's Ballad III" <me>' → Debybrown
[BRD Manager] BRD inactive, next phase: melee
[BRD Manager] Melee buffs missing: ['Minuet', 'Madrigal']
[COMMAND] '//ac follow Dexterbrown' → Debybrown
[COMMAND] '//ac queue_song "Valor Minuet V" <me>' → Debybrown
[COMMAND] '//ac queue_song "Sword Madrigal" <me>' → Debybrown
[BRD Manager] BRD inactive, next phase: return_healer
[COMMAND] '//ac follow Deedeebrown' → Debybrown
```

## Si ça ne marche pas

1. Vérifier que le serveur Python est démarré
2. Vérifier que `//lua r altcontrol` a été fait
3. Vérifier que le fichier `autocast_config.json` existe
4. Copier-coller les logs Windower ET Python

## Architecture

```
Bouton Web App
  ↓
//ac start
  ↓
BRD charge config + Follow healer
  ↓
Serveur Python détecte engagement
  ↓
Loop:
  Check mage → Queue songs → Attend
  Check melee → Follow → Queue songs → Attend → Retour
```

## Différences avec l'ancien système

❌ **Ancien:** Cycle automatique dans le Lua (s'emballait)
✅ **Nouveau:** Serveur Python décide tout, Lua exécute

❌ **Ancien:** Logique complexe avec phases imbriquées
✅ **Nouveau:** Logique simple et linéaire

❌ **Ancien:** Difficile à débugger
✅ **Nouveau:** Logs clairs à chaque étape

## Prêt à tester!

Relance le serveur Python et teste dans le jeu! 🎵
