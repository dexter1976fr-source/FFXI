# 🎵 GUIDE RAPIDE - Système BRD

## Démarrage Rapide

### 1. Démarrer le Serveur Python
- Ouvrir `FFXI_ALT_Control.py`
- Cliquer "ON / OFF Servers"
- Attendre que les deux voyants passent au VERT

### 2. Dans le Jeu (BRD)
```
//lua l altcontrol
//ac start
```

### 3. Vérifier que ça Marche
```
//ac status
```
Doit afficher: `[AltControl] AutoCast is ACTIVE`

### 4. Test Manuel
```
//ac cast_mage_songs
```
Le BRD doit caster 2 songs mages.

## Fonctionnement Automatique

Une fois démarré avec `//ac start`, le système est **100% automatique**:

1. Le serveur Python vérifie les buffs toutes les 5 secondes
2. Si quelqu'un manque des buffs → envoie commande au BRD
3. Le BRD cast automatiquement les songs manquants
4. Retourne en mode idle

## Configuration

Fichier: `Windower4/addons/AltControl/data/autocast_config.json`

```json
{
  "BRD": {
    "healerTarget": "NomDuHealer",
    "meleeTarget": "NomDuMelee",
    "mageSongs": [
      "Mage's Ballad II",
      "Mage's Ballad III"
    ],
    "meleeSongs": [
      "Valor Minuet V",
      "Sword Madrigal"
    ]
  }
}
```

## Commandes Utiles

```
//ac start              # Démarrer AutoCast
//ac stop               # Arrêter AutoCast
//ac status             # Voir le status
//ac cast_mage_songs    # Forcer cast mages
//ac cast_melee_songs   # Forcer cast melees
//lua r altcontrol      # Recharger l'addon
```

## Dépannage

### Le BRD ne cast rien
1. Vérifier: `//ac status` → doit dire "ACTIVE"
2. Si "INACTIVE" → faire `//ac start`
3. Vérifier que le serveur Python est démarré (voyants VERTS)

### Les songs ne sont pas les bons
1. Éditer `autocast_config.json`
2. Changer les songs dans `mageSongs` et `meleeSongs`
3. Faire `//lua r altcontrol` dans le jeu

### Le serveur Python ne détecte pas les buffs manquants
1. Vérifier que quelqu'un est engagé en combat
2. Vérifier les logs Python pour voir les buffs détectés
3. Attendre 20 secondes entre chaque cast (cooldown)

## Logs Importants

### Dans le Jeu (Windower)
```
[BRD AutoCast] 📖 Healer target: Deedeebrown
[BRD AutoCast] 📖 Mage songs: Mage's Ballad II, Mage's Ballad III
[BRD AutoCast] ✅ Config loaded from file
[BRD AutoCast] 🎵 FORCE cast mages
[BRD AutoCast] 🎵 Casting Mage's Ballad II
```

### Dans le Serveur Python
```
[BRD Manager] Deedeebrown buffs: [...] | Missing: ['Ballad']
[BRD Manager] Deedeebrown missing mage buffs, casting [...]
[COMMAND] '//ac cast_mage_songs' → Dexterbrown
```

## C'est Tout!

Le système est maintenant réparé et devrait fonctionner comme avant. 🎵
