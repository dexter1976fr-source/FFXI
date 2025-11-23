# 🧪 Test du système de Recast

## ✅ Ce qui fonctionne maintenant

1. **HP/TP du pet** - ✅ PARFAIT
2. **Recasts visuels** - ✅ IMPLÉMENTÉ (à tester)

---

## 🎯 Comment tester les recasts

### Étape 1: Rafraîchir la webapp
Sur la tablette/navigateur:
- **Videz le cache**: Ctrl+Shift+Delete
- Ou **refresh forcé**: Ctrl+F5
- Allez sur `http://192.168.1.80:5000`

### Étape 2: Lancer un sort avec recast
Dans FFXI, via la webapp:
1. Cliquez sur "Magic"
2. Cliquez sur "Cure III" (ou n'importe quel sort)
3. Le sort se lance dans le jeu

### Étape 3: Observer le recast
Sur le bouton "Cure III", vous devriez voir:
```
┌─────────────┐
│  Cure III   │
│    8.5s     │ ← Temps restant
│ ████░░░░░░  │ ← Barre de progression
└─────────────┘
```

La barre se remplit progressivement jusqu'à ce que le recast soit terminé.

---

## 🎨 Comportement visuel

### Pendant le recast:
- ✅ Bouton grisé (opacity 50%)
- ✅ Curseur "not-allowed"
- ✅ Temps restant affiché (ex: "8.5s")
- ✅ Barre cyan qui se remplit
- ✅ Bouton non cliquable

### Après le recast:
- ✅ Bouton redevient normal
- ✅ Temps disparaît
- ✅ Barre complète
- ✅ Bouton cliquable

---

## 📋 Sorts supportés (avec ID)

Les sorts suivants ont leur recast affiché:

### White Magic:
- Cure, Cure II, Cure III, Cure IV, Cure V, Cure VI
- Raise, Raise II, Raise III, Reraise
- Protect I-V, Shell I-V
- Regen I-IV
- Haste, Haste II
- Refresh, Refresh II
- Blink

### Black Magic:
- Fire, Blizzard, Thunder, Water, Aero, Stone (I-V)
- Sleep, Sleep II, Sleepga, Sleepga II
- Dia, Dia II, Dia III, Diaga
- Slow, Slow II
- Paralyze, Paralyze II
- Silence
- Blind, Blind II

### Summoning:
- Carbuncle, Fenrir, Ifrit, Titan, Leviathan, Garuda, Shiva, Ramuh, Diabolos

### Ninjutsu:
- Utsusemi: Ichi, Utsusemi: Ni

### Songs:
- Foe Requiem I-III
- Horde Lullaby I-II

---

## 🔍 Vérification des données

### Dans la console du navigateur (F12):
Après avoir lancé un sort, tapez:
```javascript
// Voir les recasts actuels
console.log(altData.spell_recasts);
```

Vous devriez voir quelque chose comme:
```javascript
{
  "3": 10.5,  // Cure III avec 10.5s de recast
  "57": 5.2   // Haste avec 5.2s de recast
}
```

### Via l'API:
```bash
curl http://localhost:5000/alt-abilities/MonPerso
```

Cherchez dans la réponse:
```json
{
  "spell_recasts": {
    "3": 10.5,
    "57": 5.2
  }
}
```

---

## 🐛 Dépannage

### Le recast ne s'affiche pas:

1. **Vérifier que le sort est dans la liste**
   - Seuls les sorts avec ID connu s'affichent
   - Voir la liste dans `spellIds.ts`

2. **Vider le cache du navigateur**
   - C'est la cause #1!
   - Ctrl+Shift+Delete

3. **Vérifier les logs**
   Console du navigateur (F12):
   ```javascript
   [AltController MonPerso] Applied config: {
     spells: 15,
     recasts: 2  // ← Nombre de recasts actifs
   }
   ```

4. **Tester avec un sort connu**
   - Cure III (ID: 3)
   - Fire (ID: 144)
   - Haste (ID: 57)

### Le bouton reste grisé:

1. **Attendre la fin du recast**
   - Le timer doit arriver à 0

2. **Recharger la page**
   - F5 ou Ctrl+F5

---

## 📊 Performance

### Mise à jour des recasts:
- Fréquence: Toutes les secondes (envoyé par le Lua)
- Affichage: Mise à jour toutes les 100ms (smooth)
- Impact: Minimal (seulement les recasts actifs)

### Nombre de recasts typiques:
- Repos: 0
- Combat léger: 2-5
- Combat intense: 5-15
- Maximum: ~30 (rare)

---

## 🎯 Prochaines améliorations possibles

### Court terme:
1. Ajouter plus d'IDs de spells
2. Ajouter les IDs des job abilities
3. Ajouter les IDs des weapon skills

### Moyen terme:
1. Son/vibration quand recast terminé
2. Notification visuelle
3. Ordre automatique par recast

### Long terme:
1. Mapping complet de tous les spells FFXI
2. Prédiction du recast (avant de lancer)
3. Historique des casts

---

## 📝 Ajouter un nouveau spell

Si un sort n'est pas dans la liste, ajoutez-le dans `Web_App/src/data/spellIds.ts`:

```typescript
export const SPELL_IDS: Record<number, string> = {
  // ... autres sorts
  123: "Nouveau Sort",  // ← Ajouter ici
};
```

Pour trouver l'ID d'un sort:
1. https://www.bg-wiki.com/ffxi/Category:Magic
2. Ou regarder dans les logs Windower

---

**Date:** $(date)
**Status:** ✅ IMPLÉMENTÉ
**À tester:** Lancer un sort et observer le recast
**Fichiers modifiés:**
- `Web_App/src/data/spellIds.ts` ✅ (nouveau)
- `Web_App/src/components/AltController.tsx` ✅
- `Web_App/src/components/CommandButtonWithRecast.tsx` ✅
