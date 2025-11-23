# 🐾 AltPetOverlay - Guide Complet

## 📋 Description

**AltPetOverlay** est un addon Windower qui affiche les informations des familiers (pets) de tous les personnages du party en temps réel avec un style graphique inspiré de XIVParty.

### Fonctionnalités

- **Affichage graphique** : Barres HP colorées, fond semi-transparent
- **Multi-jobs** :
  - **BST** : Charges Ready (●●●○○)
  - **SMN** : Timer Blood Pact
  - **DRG** : Status Healing Breath
- **Temps réel** : Mise à jour automatique via IPC
- **Personnalisable** : Position ajustable

---

## 🚀 Installation

### 1. Copier l'addon

L'addon est déjà installé dans :
```
A:\Jeux\PlayOnline\Windower4\addons\AltPetOverlay\
```

### 2. Charger l'addon in-game

```lua
//lua load AltPetOverlay
```

Ou ajouter dans `init.txt` :
```
lua load AltPetOverlay
```

---

## 🎮 Utilisation

### Commandes disponibles

```lua
//po test          -- Afficher des données de test
//po clear         -- Effacer tous les pets affichés
//po pos <x> <y>   -- Changer la position de l'overlay
```

### Exemples

```lua
//po test                  -- Tester l'affichage
//po pos 100 500           -- Positionner en bas à gauche
//po pos 1500 100          -- Positionner en haut à droite
//po clear                 -- Nettoyer l'affichage
```

---

## 🔧 Configuration

### Position par défaut

```lua
x = 100
y = 500
```

### Personnalisation

Pour changer la position, utiliser `//po pos <x> <y>` in-game.

La position est sauvegardée automatiquement.

---

## 📡 Communication avec AltControl

AltPetOverlay reçoit les données via **IPC** (Inter-Process Communication) depuis AltControl.

### Format des messages IPC

```
petoverlay_owner:Dexterbrown_pet:BlackbeardRandy_hp:650_maxhp:1000_charges:3
```

### Données envoyées

- `owner` : Nom du propriétaire
- `pet` : Nom du familier
- `hp` : HP actuel
- `maxhp` : HP maximum
- `charges` : Charges Ready (BST uniquement)
- `bp_timer` : Timer Blood Pact (SMN uniquement)
- `breath_ready` : Status Healing Breath (DRG uniquement)

---

## 🎨 Style Graphique

### Couleurs des barres HP

- **Vert** : HP > 75%
- **Jaune** : HP 50-75%
- **Orange** : HP 25-50%
- **Rouge** : HP < 25%

### Affichage

```
┌─────────────────────────────────────────┐
│ Dexterbrown → BlackbeardRandy           │
│ ████████████████░░░░░░░░░░ 650/1000     │
│ Ready: ●●●○○ (3/5)                      │
└─────────────────────────────────────────┘
```

---

## 🐛 Dépannage

### L'overlay ne s'affiche pas

1. Vérifier que l'addon est chargé :
   ```lua
   //lua list
   ```

2. Tester avec des données de test :
   ```lua
   //po test
   ```

3. Vérifier la position (peut être hors écran) :
   ```lua
   //po pos 100 500
   ```

### Les données ne se mettent pas à jour

1. Vérifier qu'AltControl est chargé :
   ```lua
   //lua list
   ```

2. Recharger AltControl :
   ```lua
   //lua reload AltControl
   ```

3. Vérifier que vous avez un pet actif

### Performances

L'overlay utilise `windower.prim` pour les graphiques, ce qui est très performant.

Si vous avez des problèmes de FPS, vous pouvez :
- Réduire le nombre de pets affichés
- Désactiver temporairement l'overlay

---

## 📝 Notes Techniques

### Nettoyage automatique

Les pets qui n'ont pas été mis à jour depuis **10 secondes** sont automatiquement supprimés de l'affichage.

### Fréquence de mise à jour

- **AltControl** envoie les données toutes les **1 seconde**
- **AltPetOverlay** vérifie les données toutes les **5 secondes**

### Limites

- Maximum **6 pets** affichés (limité par la taille du party)
- Les trusts ne sont pas affichés (uniquement les pets des joueurs)

---

## 🔄 Mise à jour

Pour mettre à jour l'addon :

1. Copier le nouveau fichier `AltPetOverlay.lua`
2. Recharger l'addon :
   ```lua
   //lua reload AltPetOverlay
   ```

---

## 📚 Ressources

- **XIVParty** : Inspiration pour le style graphique
- **Windower Primitives** : Documentation sur `windower.prim`
- **IPC** : Communication inter-addons Windower

---

**Version** : 1.0.0-graphics  
**Auteur** : Dexter  
**Date** : 23 novembre 2024
