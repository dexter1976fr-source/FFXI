# 🎯 Correction Auto Engage

## Problème identifié

Le système Auto Engage ne fonctionnait pas correctement pour les raisons suivantes:

1. **Fetch direct vers localhost** : Le code utilisait `fetch('http://localhost:5000/...')` au lieu du `backendService`
2. **Pas de gestion d'erreur réseau** : Les erreurs de connexion n'étaient pas gérées
3. **Intervalle non nettoyé** : L'intervalle continuait après le démontage du composant
4. **Dépendances incorrectes** : Le `useEffect` se relançait trop souvent

## Corrections apportées

### 1. Utilisation du backendService (AltController.tsx)

**Avant:**
```typescript
const response = await fetch(`http://localhost:5000/alt-abilities/${mainName}`);
const mainData = await response.json();
```

**Après:**
```typescript
const mainData = await backendService.fetchAltAbilities(mainName);
```

**Avantages:**
- Gestion automatique de l'URL (localhost ou IP réseau)
- Gestion des erreurs intégrée
- Logs cohérents avec le reste de l'application

### 2. Nettoyage correct de l'intervalle

**Ajouté:**
```typescript
let isActive = true; // Flag pour éviter les updates après unmount

return () => {
  isActive = false;
  clearInterval(interval);
  console.log(`[Auto Engage] Cleanup for ${altData.alt_name}`);
};
```

**Avantages:**
- Évite les memory leaks
- Empêche les updates après démontage du composant
- Logs de debug pour le suivi

### 3. Optimisation des dépendances

**Avant:**
```typescript
}, [altData, autoEngage, lastMainEngagedState]);
```

**Après:**
```typescript
}, [altData?.party, altData?.alt_name, autoEngage]);
```

**Avantages:**
- Évite les re-renders inutiles
- Ne se relance que si la party ou le nom change
- Plus performant

### 4. Intervalle moins agressif

**Changé:** 1 seconde → 2 secondes

**Raison:** Réduit la charge réseau et CPU sans impacter la réactivité

### 5. Ajout des types TypeScript (backendService.ts)

**Ajouté à l'interface `PythonAltAbilities`:**
```typescript
bst_ready_charges?: number;
is_engaged?: boolean;
```

## Fonctionnement du système Auto Engage

1. **Activation** : L'utilisateur clique sur le bouton "Auto: OFF" → "Auto: ON"
2. **Surveillance** : Le système vérifie toutes les 2 secondes l'état du premier membre de la party (p1)
3. **Détection** : Quand `is_engaged` passe de `false` à `true` pour le main
4. **Action automatique** :
   - `/assist <p1>` (cible la même cible que le main)
   - Attente de 1 seconde
   - `/attack <bt>` (attaque la cible)

## Données envoyées par le Lua

Le fichier `AltControl.lua` envoie déjà `is_engaged` dans les données:

```lua
local is_engaged = player.status == 1  -- 1 = Engaged, 0 = Idle, 2 = Resting, 3 = Dead

local data = {
  -- ...
  is_engaged = is_engaged,
  -- ...
}
```

**Statuts FFXI:**
- 0 = Idle (repos)
- 1 = Engaged (en combat)
- 2 = Resting (assis)
- 3 = Dead (mort)

## Test de la fonctionnalité

1. Lancer le serveur Python (`FFXI_ALT_Control.py`)
2. Lancer FFXI avec 2+ personnages avec l'addon AltControl
3. Ouvrir la Web App sur l'ALT
4. Activer "Auto: ON"
5. Engager le combat avec le personnage principal (p1)
6. L'ALT devrait automatiquement assist + attack

## Logs de debug

Pour suivre le fonctionnement:

```
[Auto Engage] Active, monitoring MainCharName
[Auto Engage] MainCharName: engaged=false, last=false, alt=AltName
[Auto Engage] MainCharName: engaged=true, last=false, alt=AltName
[Auto Engage] MainCharName engaged! AltName attacking...
[AltController AltName] Sending: /assist <p1>
[AltController AltName] Sending: /attack <bt>
```

## Fichiers modifiés

- ✅ `Web_App/src/components/AltController.tsx` - Correction du système auto engage
- ✅ `Web_App/src/services/backendService.ts` - Ajout des types TypeScript
- ✅ Build réussi sans erreurs

## Prochaines étapes

Si le problème persiste:

1. **Vérifier la connexion réseau** : Ouvrir la console du navigateur (F12) et regarder les logs
2. **Vérifier le serveur Python** : S'assurer qu'il tourne et reçoit les données
3. **Vérifier le Lua** : S'assurer que `is_engaged` est bien envoyé (regarder les logs du serveur Python)
4. **Tester manuellement** : Utiliser `/alt-abilities/MainName` dans le navigateur pour voir si `is_engaged` est présent

## Notes importantes

- Le système ne fonctionne que si l'ALT est dans la même party que le main
- Le main doit être en position p1 (premier membre de la party)
- L'intervalle de 2 secondes peut créer un léger délai (ajustable si nécessaire)
