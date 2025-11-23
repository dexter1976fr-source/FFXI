# Test des Buffs SCH Light/Dark Arts

## Modifications effectuées

### 1. AltControl.lua
- ✅ Ajout de la fonction `is_array()` pour détecter les arrays Lua
- ✅ Modification de `table_to_json()` pour convertir les arrays en JSON arrays `[]` au lieu d'objets `{}`
- ✅ Les buffs sont maintenant envoyés comme `["Light Arts", "Haste"]` au lieu de `{1: "Light Arts", 2: "Haste"}`

### 2. FFXI_ALT_Control.py
- ✅ Ajout du parsing des buffs (dict ou list) pour garantir un array
- ✅ Conversion explicite: `active_buffs = []` puis remplissage
- ✅ Logs de debug pour tracer le type de données reçu

### 3. Web_App/src/components/AltController.tsx
- ✅ Simplification de la détection des buffs (plus besoin de conversion dict→array)
- ✅ Détection directe: `buffs.includes('Light Arts')` ou `buffs.includes('Dark Arts')`
- ✅ Affichage de l'indicateur dans le header avec couleurs:
  - 🔵 Light = fond bleu
  - 🔴 Dark = fond rouge
  - ⚪ None = fond gris

## Comment tester

1. **Démarrer le serveur Python**
   - Lancer `FFXI_ALT_Control.py`
   - Cliquer sur "ON / OFF Servers"

2. **Recharger l'addon Lua dans FFXI**
   - Dans le jeu: `//lua r AltControl`
   - Vérifier les logs Python pour voir les buffs détectés

3. **Ouvrir la Web App**
   - Aller sur `http://localhost:5000`
   - Sélectionner un ALT SCH
   - Vérifier l'indicateur dans le header

4. **Tester les Arts**
   - Dans FFXI, lancer `/ja "Light Arts" <me>`
   - Attendre 1-2 secondes (refresh automatique)
   - L'indicateur devrait passer à 🔵 Light
   - Lancer `/ja "Dark Arts" <me>`
   - L'indicateur devrait passer à 🔴 Dark

## Logs à vérifier

### Python (console)
```
[DEBUG] Buffs raw data for NomDuSCH: ['Light Arts', 'Haste'] (type: <class 'list'>)
[DEBUG] Buffs parsed: ['Light Arts', 'Haste']
  Active buffs: ['Light Arts', 'Haste']
```

### Browser (F12 Console)
```
[SCH] Active buffs from server: ['Light Arts', 'Haste']
[SCH] Buffs array: ['Light Arts', 'Haste']
[SCH] ✅ Setting mode to LIGHT from server
```

## Problèmes possibles

### L'indicateur reste sur ⚪ None
- Vérifier que le Lua a été rechargé: `//lua r AltControl`
- Vérifier les logs Python pour voir si les buffs sont reçus
- Vérifier la console browser (F12) pour voir les logs SCH

### Les buffs ne sont pas détectés
- Vérifier que le personnage est bien SCH main job
- Vérifier que Light/Dark Arts est bien actif dans le jeu
- Les IDs de buffs dans le Lua sont corrects (377=Light Arts, 378=Dark Arts)

### L'indicateur ne se met pas à jour
- Le WebSocket doit être connecté (icône Wifi verte)
- Vérifier que le serveur Python envoie bien les broadcasts
- Recharger la page web si nécessaire
