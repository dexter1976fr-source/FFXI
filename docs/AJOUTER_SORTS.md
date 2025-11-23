# 📝 Guide: Ajouter des sorts à la liste des recasts

## Fichier à modifier

`Web_App/src/data/spellIds.ts`

## Comment trouver l'ID d'un sort

### Méthode 1: BG Wiki
1. Allez sur https://www.bg-wiki.com/ffxi/Category:Magic
2. Cherchez votre sort (ex: "Phalanx")
3. L'ID est généralement indiqué sur la page

### Méthode 2: Dans le jeu
Lancez le sort et regardez les logs Windower - l'ID peut apparaître.

### Méthode 3: Liste complète
https://github.com/Windower/Lua/blob/live/addons/libs/spells.lua

## Format

```typescript
export const SPELL_IDS: Record<number, string> = {
  // ... autres sorts
  
  // Votre nouveau sort
  123: "Nom du Sort",
  
  // ... suite
};
```

## Exemples récents ajoutés

```typescript
// Enhancing
55: "Phalanx",
106: "Phalanx II",
54: "Stoneskin",
112: "Flash",
113: "Aquaveil",
114: "Sneak",
115: "Invisible",
116: "Deodorize",
```

## Après modification

1. **Sauvegarder** le fichier
2. **Rebuild**:
   ```bash
   cd Web_App
   npm run build
   ```
3. **Vider le cache** du navigateur (Ctrl+F5)
4. **Tester** le sort

## Liste des sorts courants à ajouter

Voici quelques sorts populaires avec leurs IDs (à vérifier):

### White Magic:
```typescript
// Curagas
7: "Cura",
8: "Cura II",
9: "Cura III",

// Status removal
15: "Poisona",
16: "Paralyna",
17: "Blindna",
18: "Silena",
19: "Stona",
20: "Viruna",
21: "Cursna",

// Bars
60: "Barfire",
61: "Barblizzard",
62: "Baraero",
63: "Barstone",
64: "Barthunder",
65: "Barwater",
```

### Black Magic:
```typescript
// -ga spells
176: "Firaga",
177: "Blizzaga",
178: "Aeroga",
179: "Stonega",
180: "Thundaga",
181: "Waterga",

// Bio
230: "Bio",
231: "Bio II",
232: "Bio III",

// Drain/Aspir
245: "Drain",
246: "Drain II",
247: "Aspir",
248: "Aspir II",
```

### Red Magic:
```typescript
// Enspells
100: "Enfire",
101: "Enblizzard",
102: "Enaero",
103: "Enstone",
104: "Enthunder",
105: "Enwater",
```

## Après avoir ajouté plusieurs sorts

N'oubliez pas de:
1. Sauvegarder
2. Rebuild (`npm run build`)
3. Vider le cache (Ctrl+F5)

---

## 🎨 Nouveau visuel du recast

### Avant:
```
┌─────────────┐
│  Cure IV    │
│    8.5s     │ ← Texte en dessous (changeait la taille)
│ ████░░░░░░  │ ← Barre en bas
└─────────────┘
```

### Après:
```
┌─────────────┐
│ ▓▓▓▓▓░░░░░░ │ ← Overlay grisé qui se réduit
│   8.5s      │ ← Timer au centre
│  Cure IV    │ ← Nom toujours visible
└─────────────┘
```

### Avantages:
- ✅ Taille du bouton constante
- ✅ Timer au centre (plus visible)
- ✅ Overlay qui se réduit de droite à gauche
- ✅ Effet visuel plus fluide

---

**Date:** $(date)
**Fichier:** `Web_App/src/data/spellIds.ts`
**Sorts ajoutés:** Phalanx, Phalanx II, Stoneskin, Flash, Aquaveil, Sneak, Invisible, Deodorize
