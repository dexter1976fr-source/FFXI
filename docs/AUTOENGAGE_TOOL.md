# AutoEngage Tool

## Description
AutoEngage surveille automatiquement la cible du tank et engage le combat quand le tank attaque.

## Utilisation

### Commandes in-game
```
//ac autoengage start <nom_du_tank>   - Démarrer l'auto-engage
//ac autoengage stop                  - Arrêter l'auto-engage
//ac autoengage status                - Voir le statut
//ac status                           - Voir tous les statuts (AutoCast + AutoEngage)
```

### Exemple
```
//ac autoengage start Dexterbrown
```

## Fonctionnement

1. **Surveillance** : Vérifie toutes les secondes si le tank est engagé
2. **Détection** : Quand le tank attaque une nouvelle cible
3. **Action** : Exécute `/assist <tank>` puis `/attack <bt>`
4. **Sécurité** : Ne fait rien si déjà engagé ou en cast

## Intégration webapp

La webapp peut activer/désactiver AutoEngage via commande :
```lua
-- Depuis la webapp, envoyer la commande :
"//ac autoengage start Dexterbrown"  -- ON
"//ac autoengage stop"               -- OFF
```

## Architecture

- **Fichier** : `addons/AltControl/tools/AutoEngage.lua`
- **Chargement** : À la demande (lazy loading)
- **Update** : Appelé dans la boucle principale d'AltControl (10 Hz)
- **État** : Indépendant, peut fonctionner avec ou sans AutoCast

## TODO
- [ ] Ajouter un bouton ON/OFF dans la webapp
- [ ] Sauvegarder le nom du tank dans la config
- [ ] Ajouter un délai configurable entre assist et attack
