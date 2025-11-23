# 🐛 Debug Auto Engage

## ✅ Corrections appliquées

1. **Utilisation de `useRef`** au lieu de `useState` pour `lastMainEngagedState`
   - Évite les re-renders inutiles
   - Garde la valeur entre les vérifications

2. **Ajout d'emojis dans les logs** pour faciliter le suivi
   - ✅ = Activation
   - 🎯 = Détection d'engagement
   - 🛑 = Désactivation
   - ❌ = Erreur

3. **Build réussi** - Nouveau fichier généré dans `Web_App/dist/`

## 🔍 Comment débugger

### 1. Ouvrir la console du navigateur

**Chrome/Edge:**
- Appuyer sur `F12`
- Aller dans l'onglet "Console"

**Firefox:**
- Appuyer sur `F12`
- Aller dans l'onglet "Console"

### 2. Filtrer les logs Auto Engage

Dans la barre de recherche de la console, taper:
```
Auto Engage
```

Cela va filtrer uniquement les logs du système auto engage.

### 3. Logs attendus

#### Quand tu actives "Auto: ON"
```
[Auto Engage] ✅ Active, monitoring MainCharName
```

#### Toutes les 2 secondes
```
[Auto Engage] MainCharName: engaged=false, last=false, alt=AltName
```

#### Quand le main engage
```
[Auto Engage] MainCharName: engaged=true, last=false, alt=AltName
[Auto Engage] 🎯 MainCharName engaged! AltName attacking...
[AltController AltName] Sending: /assist <p1>
[AltController AltName] Sending: /attack <bt>
```

#### Quand tu désactives "Auto: OFF"
```
[Auto Engage] 🛑 Cleanup for AltName
```

### 4. Erreurs possibles

#### Erreur: "Skipping: main is self or empty"
```
[Auto Engage] Skipping: main is self or empty
```
**Cause:** L'ALT est le premier membre de la party (p1) ou la party est vide
**Solution:** Assure-toi que le main est en position p1 et l'ALT en p2+

#### Erreur: Pas de logs du tout
**Causes possibles:**
1. Le serveur Python n'est pas lancé
2. La Web App n'est pas connectée au serveur
3. L'ALT n'a pas de party

**Solutions:**
1. Vérifier que le serveur Python affiche "Flask+WebSocket: ON"
2. Recharger la page (F5)
3. Vérifier dans FFXI que les personnages sont dans la même party

#### Erreur: "Error: ..."
```
[Auto Engage] ❌ Error: Failed to fetch
```
**Cause:** Problème de connexion réseau
**Solution:** 
1. Vérifier que le serveur Python tourne
2. Vérifier l'URL dans la barre d'adresse
3. Essayer `http://localhost:5000` au lieu de l'IP

### 5. Vérifier les données du serveur

#### Test manuel dans le navigateur

Ouvrir dans un nouvel onglet:
```
http://localhost:5000/alt-abilities/MainCharName
```

Remplacer `MainCharName` par le nom de ton personnage principal.

Tu devrais voir un JSON avec:
```json
{
  "alt_name": "MainCharName",
  "is_engaged": false,
  "party": ["MainCharName", "AltName"],
  ...
}
```

**Vérifications:**
- ✅ `is_engaged` doit être présent (true ou false)
- ✅ `party` doit contenir les noms des personnages
- ✅ Le premier nom dans `party` doit être le main

### 6. Vérifier le serveur Python

Dans la console du serveur Python, tu devrais voir:
```
[ALT UPDATE] 'MainCharName' at 127.0.0.1:5008
  Job/Sub: WAR 99 / NIN 49
  Weapon: Great Sword (ID: 18500)
  Engaged: False
  Party: MainCharName, AltName
```

**Vérifications:**
- ✅ `Engaged: True/False` doit changer quand tu engages/désengages
- ✅ `Party:` doit lister tous les membres

### 7. Vérifier le Lua addon

Dans FFXI, taper:
```
//lua reload AltControl
```

Tu devrais voir dans le chat:
```
AltControl loaded
```

Si tu vois une erreur, l'addon n'est pas chargé correctement.

## 🧪 Test étape par étape

### Étape 1: Vérifier la connexion
1. Ouvrir `http://localhost:5000`
2. Vérifier que tu vois la liste des ALTs
3. Cliquer sur un ALT

### Étape 2: Vérifier les données
1. Ouvrir la console (F12)
2. Chercher `[AltController]` dans les logs
3. Tu devrais voir: `Loaded data:` avec toutes les infos

### Étape 3: Activer Auto Engage
1. Cliquer sur "Auto: OFF" → "Auto: ON"
2. Vérifier dans la console: `[Auto Engage] ✅ Active, monitoring ...`
3. Tu devrais voir des logs toutes les 2 secondes

### Étape 4: Tester l'engagement
1. Dans FFXI, avec le personnage principal (p1)
2. Cibler un ennemi
3. Appuyer sur Ctrl (ou ta touche d'attaque)
4. Regarder la console: tu devrais voir `🎯 ... engaged! ... attacking...`
5. L'ALT devrait attaquer automatiquement

## 📊 Checklist de vérification

- [ ] Serveur Python lancé et "ON"
- [ ] FFXI lancé avec 2+ personnages
- [ ] Addon AltControl chargé sur tous les personnages
- [ ] Personnages dans la même party
- [ ] Main en position p1
- [ ] Web App ouverte sur l'ALT
- [ ] Console du navigateur ouverte (F12)
- [ ] "Auto: ON" activé (bouton vert)
- [ ] Logs `[Auto Engage]` visibles toutes les 2 secondes

## 🆘 Si ça ne marche toujours pas

1. **Copie les logs de la console** et envoie-les moi
2. **Copie les logs du serveur Python** (la partie avec `[ALT UPDATE]`)
3. **Vérifie l'URL** dans le navigateur (doit être `http://localhost:5000` ou l'IP de ton PC)
4. **Essaie de recharger** la page (F5)
5. **Essaie de redémarrer** le serveur Python

## 💡 Astuce

Pour voir TOUS les logs (pas seulement Auto Engage), dans la console:
- Cliquer sur le bouton "Clear" (🗑️) pour vider
- Activer "Auto: ON"
- Engager le combat
- Copier tous les logs et les analyser

Les logs importants commencent par:
- `[Auto Engage]` - Système auto engage
- `[AltController]` - Contrôleur de l'ALT
- `[BackendService]` - Communication avec le serveur
