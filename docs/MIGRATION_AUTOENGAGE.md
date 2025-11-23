# Migration Auto Engage vers Lua Tool

## Changements effectués

### ✅ Avant (React + Python)
- Logique dans `AltController.tsx` avec `useEffect`
- Polling toutes les 2 secondes depuis la webapp
- Surveillance de tous les ALTs depuis React
- Commandes `/assist` et `/attack` envoyées via Python

### ✅ Après (Lua Tool)
- Logique dans `tools/AutoEngage.lua`
- Surveillance locale dans le jeu (1 Hz)
- Pas de polling réseau
- Commandes exécutées directement dans FFXI

## Avantages

1. **Performance** : Pas de polling réseau constant
2. **Réactivité** : Détection instantanée dans le jeu
3. **Fiabilité** : Pas de dépendance webapp/Python
4. **Modularité** : Tool indépendant réutilisable

## Utilisation

### Dans le jeu
```
//ac autoengage start Dexterbrown
//ac autoengage stop
```

### Depuis la webapp
Le bouton "Auto: ON/OFF" envoie automatiquement les commandes Lua

## Code nettoyé

- ❌ Supprimé : 70 lignes de logique React
- ❌ Supprimé : `lastMainEngagedStateRef`
- ✅ Ajouté : `handleAutoEngageToggle()` (15 lignes)
- ✅ Ajouté : `tools/AutoEngage.lua` (module autonome)

## Test

1. Recharger AltControl : `//lua reload AltControl`
2. Cliquer sur "Auto: ON" dans la webapp
3. Vérifier : `//ac status`
4. Le personnage devrait engager quand le tank attaque
