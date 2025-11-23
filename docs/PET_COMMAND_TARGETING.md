# 🐾 Guide de ciblage des Pet Commands

## Catégories standardisées

### `attack` → Cible `<t>` (ennemi)
Commandes qui ordonnent au pet d'attaquer la cible actuelle.

**Exemples:**
- `Assault` (SMN) - Ordonne au pet d'attaquer
- `Fight` (BST) - Ordonne au pet d'attaquer
- `Sic` (BST) - Ordonne au pet d'utiliser une attaque spéciale
- `Blood Pact: Rage` (SMN) - Attaques offensives
- `Smiting Breath` (DRG) - Attaque du wyvern

**Commande générée:** `/pet "CommandName" <t>`

---

### `support` → Cible `<me>` (soi-même)
Commandes de support, buffs, ou soins.

**Exemples:**
- `Blood Pact: Ward` (SMN) - Buffs et soins
- `Dismiss` (DRG) - Renvoie le wyvern
- `Restoring Breath` (DRG) - Soin du wyvern
- `Steady Wing` (DRG) - Buff du wyvern

**Commande générée:** `/pet "CommandName" <me>`

---

### `utility` → Cible `<me>` (soi-même)
Commandes utilitaires de contrôle du pet.

**Exemples:**
- `Release` (SMN/BST) - Libère le pet
- `Retreat` (SMN) - Rappelle le pet

**Commande générée:** `/pet "CommandName" <me>`

---

### `pet` → Cible `<me>` (soi-même)
Commandes de contrôle basique du pet.

**Exemples:**
- `Heel` (BST) - Rappelle le pet
- `Stay` (BST) - Ordonne au pet de rester
- `Leave` (BST) - Libère le pet
- `Deploy` (PUP) - Change le frame de l'automate
- `Retrieve` (PUP) - Rappelle l'automate

**Commande générée:** `/pet "CommandName" <me>`

---

## Logique de ciblage dans le code

```typescript
const handlePetCommand = (cmd: any) => {
  const category = cmd.category?.toLowerCase();
  
  let target = "<me>"; // Par défaut
  
  // Catégories qui ciblent l'ennemi
  if (["attack", "offense", "offensive"].includes(category)) {
    target = "<t>";
  }
  // Catégories qui ciblent soi-même
  else if (["support", "utility", "self", "pet"].includes(category)) {
    target = "<me>";
  }
  
  sendCommand(`/pet "${commandName}" ${target}`);
};
```

---

## Corrections appliquées

### ✅ Corrections dans jobs.json

1. **Smiting Breath (DRG)**
   - Avant: `"category": "support"`
   - Après: `"category": "attack"`
   - Raison: C'est une attaque offensive

2. **Deploy & Retrieve (PUP)**
   - Avant: Pas de catégorie
   - Après: `"category": "pet"`
   - Raison: Commandes de contrôle du pet

### ✅ Logique améliorée dans AltController.tsx

- Utilise maintenant la `category` du JSON en priorité
- Fallback intelligent par nom de commande si pas de catégorie
- Logs de debug pour tracer les commandes

---

## Jobs avec Pet Commands

| Job | Pet Commands | Notes |
|-----|--------------|-------|
| **BST** | Fight, Heel, Stay, Leave, Sic | + Ready moves (pet_attack) |
| **DRG** | Dismiss, Restoring Breath, Steady Wing, Smiting Breath | Wyvern uniquement |
| **PUP** | Deploy, Retrieve | Automaton |
| **SMN** | Assault, Blood Pact: Rage, Blood Pact: Ward, Release, Retreat | + Blood Pacts (pet_attack) |

---

## Test des corrections

Pour vérifier que le ciblage fonctionne:

1. **Assault (SMN)** → Devrait cibler `<t>` ✅
2. **Fight (BST)** → Devrait cibler `<t>` ✅
3. **Sic (BST)** → Devrait cibler `<t>` ✅
4. **Smiting Breath (DRG)** → Devrait cibler `<t>` ✅
5. **Restoring Breath (DRG)** → Devrait cibler `<me>` ✅
6. **Release (SMN)** → Devrait cibler `<me>` ✅
7. **Heel (BST)** → Devrait cibler `<me>` ✅

---

## Ajouter une nouvelle commande

Si vous ajoutez une nouvelle pet command dans jobs.json:

```json
{
  "name": "New Command",
  "category": "attack",  // ou "support", "utility", "pet"
  "desc": "Description"
}
```

La catégorie déterminera automatiquement le ciblage:
- `attack` → `<t>`
- `support`, `utility`, `pet` → `<me>`

---

**Date de mise à jour:** $(date)
**Fichiers modifiés:** 
- `data_json/jobs.json` (corrections de catégories)
- `Web_App/src/components/AltController.tsx` (logique améliorée)
