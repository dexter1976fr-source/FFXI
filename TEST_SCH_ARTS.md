# 🧪 Test SCH Light/Dark Arts Indicator

## Problème résolu
L'indicateur Light Arts / Dark Arts du SCH ne s'affichait pas correctement car le Lua envoyait les buffs comme un objet `{1: "Light Arts", 2: "Haste"}` au lieu d'un array `["Light Arts", "Haste"]`.

## Solution appliquée
1. **Lua**: Ajout de `is_array()` pour détecter les arrays et les convertir en JSON arrays `[]`
2. **Python**: Parsing des buffs (dict ou list) pour garantir un array
3. **TypeScript**: Simplification de la détection des buffs

## Test rapide

### 1. Copier le fichier Lua
Le fichier a déjà été copié vers:
```
a:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua
```

### 2. Recharger l'addon dans FFXI
```
//lua r AltControl
```

### 3. Lancer le serveur Python
- Ouvrir `FFXI_ALT_Control.py`
- Cliquer sur "ON / OFF Servers"
- Vérifier que les deux serveurs sont ON (vert)

### 4. Ouvrir la Web App
- Naviguer vers `http://localhost:5000`
- Sélectionner un ALT SCH

### 5. Tester les Arts
Dans FFXI avec le SCH:
```
/ja "Light Arts" <me>
```
Attendre 1-2 secondes → L'indicateur devrait afficher **🔵 Light**

```
/ja "Dark Arts" <me>
```
Attendre 1-2 secondes → L'indicateur devrait afficher **🔴 Dark**

## Vérification des logs

### Console Python
Tu devrais voir:
```
[DEBUG] Buffs raw data for NomDuSCH: ['Light Arts'] (type: <class 'list'>)
[DEBUG] Buffs parsed: ['Light Arts']
  Active buffs: ['Light Arts']
```

### Console Browser (F12)
Tu devrais voir:
```
[SCH] Active buffs from server: ['Light Arts']
[SCH] Buffs array: ['Light Arts']
[SCH] ✅ Setting mode to LIGHT from server
```

## Indicateur visuel

L'indicateur apparaît dans le header de l'ALT, à côté du job:
- **🔵 Light** = fond bleu, Light Arts actif
- **🔴 Dark** = fond rouge, Dark Arts actif
- **⚪ None** = fond gris, aucun Arts actif

## Troubleshooting

### L'indicateur reste sur ⚪ None
1. Vérifier que le Lua a été rechargé: `//lua r AltControl`
2. Vérifier les logs Python pour voir si les buffs sont reçus
3. Vérifier la console browser (F12) pour voir les logs SCH
4. Vérifier que le WebSocket est connecté (icône Wifi verte)

### Les buffs ne sont pas détectés
1. Vérifier que le personnage est bien SCH main job
2. Vérifier que Light/Dark Arts est bien actif dans le jeu (icône de buff)
3. Attendre 1-2 secondes après avoir lancé l'Arts (refresh automatique)

### L'indicateur ne se met pas à jour
1. Recharger la page web
2. Vérifier que le serveur Python est bien démarré
3. Vérifier les logs WebSocket dans la console Python

## Fichiers modifiés
- ✅ `AltControl.lua` - Fonction `is_array()` et `table_to_json()` corrigée
- ✅ `FFXI_ALT_Control.py` - Parsing des buffs ajouté
- ✅ `Web_App/src/components/AltController.tsx` - Détection simplifiée
- ✅ `Web_App/dist/` - Build compilé
