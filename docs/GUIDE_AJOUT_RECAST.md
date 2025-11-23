# 📘 Guide: Ajouter des Recast IDs

## ✅ Système Implémenté

Le système de recast est maintenant **automatique** et **universel** pour:
- ✅ **Spells** (Magic)
- ✅ **Job Abilities**
- ✅ **Pet Commands**
- ✅ **Pet Attacks**

## 🎯 Comment ça marche

### 1. Fichier de Mapping: `recastIds.ts`

Tous les recast IDs sont centralisés dans `Web_App/src/data/recastIds.ts`:

```typescript
export const SPELL_RECAST_IDS: Record<string, number> = {
  "Cure": 1,
  "Fire": 144,
  // ...
};

export const ABILITY_RECAST_IDS: Record<string, number> = {
  "Provoke": 5,
  "Berserk": 1,
  // ...
};
```

### 2. Fonction Universelle: `getCommandRecast()`

Dans `AltController.tsx`, une seule fonction gère TOUS les types de recast:

```typescript
const getCommandRecast = (commandName: string): number => {
  const recastInfo = getRecastId(commandName);
  if (!recastInfo) return 0;
  
  if (recastInfo.type === 'spell') {
    return altData.spell_recasts[recastInfo.id] || 0;
  } else if (recastInfo.type === 'ability') {
    return altData.ability_recasts[recastInfo.id] || 0;
  }
  
  return 0;
};
```

### 3. Application Automatique

Tous les boutons utilisent maintenant `CommandButtonWithRecast`:

```typescript
<CommandButtonWithRecast
  label={spell.name}
  recastTime={getCommandRecast(spell.name)}
  onClick={() => handleSpell(spell)}
/>
```

## 📝 Ajouter un Nouveau Recast

### Pour un Sort (Spell):

1. Ouvrir `Web_App/src/data/recastIds.ts`
2. Ajouter dans `SPELL_RECAST_IDS`:

```typescript
export const SPELL_RECAST_IDS: Record<string, number> = {
  // ... sorts existants
  "Nouveau Sort": 999,  // ID du sort dans FFXI
};
```

### Pour une Ability:

1. Ouvrir `Web_App/src/data/recastIds.ts`
2. Ajouter dans `ABILITY_RECAST_IDS`:

```typescript
export const ABILITY_RECAST_IDS: Record<string, number> = {
  // ... abilities existantes
  "Nouvelle Ability": 42,  // ID de l'ability dans FFXI
};
```

### Pour un Pet Command:

Même chose que les abilities (ils utilisent le même système):

```typescript
export const ABILITY_RECAST_IDS: Record<string, number> = {
  // ... 
  "Sic": 3,
  "Reward": 5,
};
```

## 🔍 Trouver les Recast IDs

Les IDs de recast FFXI peuvent être trouvés dans:

1. **Windower Resources**: 
   - `Windower4/res/spells.lua` pour les sorts
   - `Windower4/res/job_abilities.lua` pour les abilities

2. **FFXIAH Database**: https://www.ffxiah.com/

3. **BG Wiki**: https://www.bg-wiki.com/

## 🎨 Personnalisation Visuelle

La barre de recast est dans `CommandButtonWithRecast.tsx`:

```typescript
// Overlay grisé qui se réduit
<div
  className="absolute top-0 left-0 bottom-0 bg-black bg-opacity-60"
  style={{ width: `${remainingPercentage}%` }}
/>
```

Vous pouvez modifier:
- **Couleur**: `bg-black` → `bg-red-900`, `bg-blue-900`, etc.
- **Opacité**: `bg-opacity-60` → `bg-opacity-40`, `bg-opacity-80`, etc.
- **Direction**: Inverser avec `right: 0` au lieu de `left: 0`

## 🧪 Tester

1. **Build**: `npm run build` dans `Web_App/`
2. **Videz le cache**: Ctrl+F5 dans le navigateur
3. **Lancez une commande** avec recast
4. **Vérifiez**:
   - La barre grise apparaît
   - Le timer s'affiche
   - La barre se réduit progressivement
   - Le bouton est désactivé pendant le recast

## 📊 Données du Serveur

Le serveur Python doit envoyer:

```python
{
  "spell_recasts": {
    "1": 8.5,    # Cure a 8.5s de recast
    "144": 3.2   # Fire a 3.2s de recast
  },
  "ability_recasts": {
    "5": 30.0,   # Provoke a 30s de recast
    "1": 120.0   # Berserk a 120s de recast
  }
}
```

## ✨ Avantages du Système

- ✅ **Centralisé**: Un seul fichier à modifier
- ✅ **Automatique**: Pas besoin de toucher aux composants
- ✅ **Type-safe**: TypeScript vérifie les types
- ✅ **Extensible**: Facile d'ajouter de nouveaux types
- ✅ **Synchronisé**: Utilise directement les données du serveur

---

**Note**: Si un recast ne fonctionne pas, vérifiez:
1. Le nom est **exactement** le même dans `jobs.json` et `recastIds.ts`
2. L'ID de recast est correct
3. Le serveur envoie bien les données de recast
