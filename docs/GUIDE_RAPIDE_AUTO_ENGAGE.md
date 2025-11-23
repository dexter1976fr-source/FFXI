# 🚀 Guide Rapide - Auto Engage

## ⚡ Démarrage rapide (3 étapes)

### 1️⃣ Lancer le serveur
```bash
python FFXI_ALT_Control.py
```
- Cliquer sur "ON / OFF Servers" pour démarrer
- Vérifier que "Lua Server" et "Flask+WebSocket" sont en vert

### 2️⃣ Lancer FFXI
- Démarrer FFXI avec 2+ personnages
- S'assurer que l'addon AltControl est chargé (`//lua load AltControl`)
- Mettre les personnages dans la même party

### 3️⃣ Ouvrir la Web App
- Naviguer vers `http://localhost:5000` (ou l'IP de votre PC depuis tablette)
- Sélectionner l'ALT
- Cliquer sur "Auto: OFF" → "Auto: ON" (devient vert)
- Engager le combat avec le personnage principal
- ✅ L'ALT attaque automatiquement!

## 🎮 Utilisation

### Bouton Auto Engage
- **OFF (orange)** : Désactivé
- **ON (vert)** : Activé - L'ALT suivra automatiquement le main en combat

### Comportement
Quand le main engage un ennemi :
1. L'ALT fait `/assist <p1>` (cible la même cible)
2. Attend 1 seconde
3. L'ALT fait `/attack <bt>` (attaque)

### Désactivation
- Cliquer à nouveau sur le bouton pour désactiver
- L'ALT arrête de suivre automatiquement

## 🔍 Vérification

### Console du navigateur (F12)
```
[Auto Engage] Active, monitoring MainName
[Auto Engage] MainName: engaged=true, last=false, alt=AltName
[Auto Engage] MainName engaged! AltName attacking...
```

### Serveur Python
```
[ALT UPDATE] 'MainName' at 127.0.0.1:5008
  Engaged: True
```

## ⚠️ Prérequis

- ✅ Les personnages doivent être dans la même party
- ✅ Le main doit être en position p1 (premier membre)
- ✅ L'addon AltControl doit être chargé sur tous les personnages
- ✅ Le serveur Python doit être lancé

## 🐛 Problèmes courants

### "Auto: ON" mais rien ne se passe
1. Vérifier que les personnages sont dans la même party
2. Ouvrir la console (F12) et regarder les logs
3. Vérifier que le serveur Python affiche "Engaged: True"

### Erreur de connexion
1. Vérifier que le serveur Python est lancé
2. Vérifier l'URL dans la barre d'adresse
3. Essayer de recharger la page (F5)

### L'ALT n'attaque pas
1. Vérifier que l'ALT n'est pas déjà en combat
2. Vérifier que le main est bien en position p1
3. Désactiver puis réactiver "Auto: ON"

## 📊 Test avec le script

Pour tester sans FFXI :
```bash
python test_auto_engage.py
```

Ce script affiche en temps réel l'état d'engagement des personnages.

## 🎯 Fonctionnalités futures possibles

- Auto Heal (soigner automatiquement quand HP < X%)
- Auto Buff (rebuffer automatiquement)
- Auto Follow (suivre le main automatiquement)
- Auto Disengage (se désengager si le main se désengage)

## 📝 Notes

- Délai de réaction : ~2 secondes maximum
- Fonctionne sur PC et tablette
- Pas besoin de toucher la Web App pendant le combat
- Le système s'arrête automatiquement si on change de zone

---

**Bon jeu! 🎮**
