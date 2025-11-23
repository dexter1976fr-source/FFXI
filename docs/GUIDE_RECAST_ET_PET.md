# 🎯 Guide: Recast visuel et HP/TP du pet

## ✅ Ce qui a été implémenté

### 1. HP/TP du Pet
- ✅ Lua modifié pour envoyer HP/TP
- ✅ Python modifié pour recevoir et stocker
- ✅ TypeScript modifié pour afficher
- ✅ Barres de progression visuelles
- ✅ Couleurs dynamiques (rouge si HP < 50%)

### 2. Système de Recast
- ✅ Lua modifié pour envoyer les recasts
- ✅ Python modifié pour recevoir et stocker
- ✅ TypeScript prêt à afficher les recasts
- ✅ Composant `CommandButtonWithRecast` créé

---

## 📋 Actions à faire MAINTENANT

### Étape 1: Redémarrer le serveur Python
1. Fermez `FFXI_ALT_Control.py` (si ouvert)
2. Relancez-le
3. Cliquez sur "ON / OFF Servers" pour activer

### Étape 2: Dans FFXI
Tapez dans le chat:
```
//lua r AltControl
```

### Étape 3: Sur la tablette/webapp
1. **IMPORTANT**: Videz le cache du navigateur!
   - Chrome/Edge: Ctrl+Shift+Delete → Effacer les données
   - Ou faites un refresh forcé: Ctrl+F5
2. Allez sur `http://192.168.1.80:5000`
3. Vérifiez que vous voyez:
   - HP/TP du pet (si pet actif)
   - Les boutons en 3 colonnes
   - Le D-pad fixe en bas

---

## 🐾 Test HP/TP du Pet

### Pour tester:
1. Invoquez un pet (wyvern, avatar, familier, automate)
2. Dans le header, vous devriez voir:
   ```
   🐾 Wyvern  HP: 100%  TP: 0
   ████████████ ░░░░
   ```
3. La barre HP devient rouge si < 50%
4. La barre TP se remplit jusqu'à 3000

### Si vous ne voyez rien:
- Vérifiez que le serveur Python est redémarré
- Vérifiez que l'addon est rechargé dans FFXI
- Videz le cache du navigateur (IMPORTANT!)

---

## ⏱️ Système de Recast

### État actuel:
Les recasts sont **envoyés** par le Lua et **stockés** par le Python, mais **pas encore affichés** sur les boutons.

### Pourquoi?
FFXI utilise des IDs numériques pour les spells/abilities, pas les noms. Il faut créer un mapping ID → Nom pour afficher les recasts correctement.

### Prochaine étape:
Créer un fichier de mapping `spell_ids.json` et `ability_ids.json` qui associe:
```json
{
  "1": "Cure",
  "2": "Cure II",
  "143": "Fire",
  ...
}
```

### Pour l'instant:
Les données de recast sont disponibles dans `altData.spell_recasts` et `altData.ability_recasts`, mais ne sont pas affichées visuellement.

---

## 🔍 Vérification des données

### Dans la console Python:
Vous devriez voir:
```
[ALT UPDATE] 'MonPerso' at 127.0.0.1:5008
  Job/Sub: WAR 75 / NIN 37
  Weapon: Great Sword (ID: 18264)
  Active Pet: Wyvern (HP: 100%, TP: 0)
  Party: Perso1, Perso2, Perso3
```

### Dans la console du navigateur (F12):
```javascript
[AltController MonPerso] Applied config: {
  spells: 15,
  ws: 8,
  macros: 3,
  petAttacks: 0,
  recasts: 512  // ← Nombre de recasts reçus
}
```

### Test API:
```bash
curl http://localhost:5000/alt-abilities/MonPerso
```

Vous devriez voir dans la réponse:
```json
{
  "pet_hp": 1234,
  "pet_hpp": 100,
  "pet_tp": 0,
  "spell_recasts": {...},
  "ability_recasts": {...}
}
```

---

## 🎨 Rendu visuel actuel

### Header avec pet:
```
┌─────────────────────────────────────┐
│ ALT 1  MonPerso                  📶 │
│ WAR 75 / NIN 37                     │
│ 🐾 Wyvern  HP: 80%  TP: 1000        │
│ ████████░░ ████                     │
└─────────────────────────────────────┘
```

### Grille de boutons (3 colonnes):
```
┌──────┬──────┬──────┐
│Assist│Attack│Magic │
│Abilit│  WS  │ Pet  │
│Mount │Walk  │Follow│
└──────┴──────┴──────┘
```

### D-pad (fixe en bas):
```
┌─────────────────────┐
│        ▲            │
│      ◄ ● ►          │
│        ▼            │
└─────────────────────┘
```

---

## 🐛 Dépannage

### HP/TP du pet ne s'affiche pas:

1. **Vérifier que le pet est actif**
   - Invoquez un pet dans FFXI
   - Attendez 1-2 secondes

2. **Vérifier les logs Python**
   - Cherchez: `Active Pet: Wyvern (HP: 100%, TP: 0)`
   - Si absent, l'addon n'envoie pas les données

3. **Vider le cache du navigateur**
   - C'est la cause #1 des problèmes!
   - Ctrl+Shift+Delete → Tout effacer
   - Ou Ctrl+F5 pour refresh forcé

4. **Vérifier l'API**
   ```bash
   curl http://localhost:5000/all-alts
   ```
   Cherchez `"pet_hp"`, `"pet_hpp"`, `"pet_tp"` dans la réponse

### Recasts ne s'affichent pas:

C'est normal pour l'instant! Les recasts sont reçus mais pas encore affichés visuellement. Il faut créer le mapping ID → Nom.

---

## 📊 Statistiques

### Données envoyées par le Lua:
- Nom, job, level
- Weapon ID et type
- Party members
- **Pet HP, HPP, TP** ✅
- **Ability recasts (512 IDs)** ✅
- **Spell recasts (1024 IDs)** ✅

### Données affichées:
- Header compact ✅
- Grille 3 colonnes ✅
- D-pad fixe ✅
- **Pet HP/TP avec barres** ✅
- Recasts ⏳ (données reçues, affichage à implémenter)

---

## 🚀 Prochaines étapes

### Pour afficher les recasts:
1. Créer `spell_ids.json` avec mapping ID → Nom
2. Créer `ability_ids.json` avec mapping ID → Nom
3. Modifier `AltController.tsx` pour utiliser ces mappings
4. Afficher la barre de recast sur chaque bouton

### Estimation:
- 1-2 heures pour créer les mappings
- 30 minutes pour intégrer l'affichage

---

**Date:** $(date)
**Status:** 
- HP/TP Pet: ✅ TERMINÉ
- Recast: ⏳ Données reçues, affichage à implémenter
**Fichiers modifiés:**
- `AltControl.lua` ✅
- `FFXI_ALT_Control.py` ✅
- `Web_App/src/components/AltController.tsx` ✅
- `Web_App/src/services/backendService.ts` ✅
- `Web_App/src/components/CommandButtonWithRecast.tsx` ✅ (nouveau)
