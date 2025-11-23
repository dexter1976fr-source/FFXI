# 🔄 RESET COMPLET - AutoCast BRD

## Date: 20 Novembre 2025

## Raison du Reset
Le système AutoCast BRD était devenu trop complexe et cassé. Impossible de le réparer sans tout casser davantage.

## Actions Effectuées

### 1. Archivage ✅
Tout le code cassé a été archivé dans: `ARCHIVE_AUTOCAST_BROKEN/`
- `AutoCast_BRD.lua` (version cassée)
- `AutoCast_BRD_BACKUP_STABLE.lua`
- `AutoCast_BRD_WORKING_MAGE_MELEE.lua`
- `FFXI_ALT_Control_BROKEN.py`

### 2. Nettoyage du Serveur Python ✅
- Supprimé: `brd_intelligent_manager()`
- Supprimé: `run_brd_manager_loop()`
- Supprimé: Thread BRD Manager
- Supprimé: Toutes les variables globales BRD

### 3. Nettoyage Lua ✅
- `AutoCast_BRD.lua` remplacé par un module vide minimal
- Copié dans Windower

### 4. Ce qui est PRÉSERVÉ ✅
- ✅ Web App complète (intacte)
- ✅ `AutoCastConfigPanel.tsx` (page de config)
- ✅ Serveur Python (fonctionne normalement)
- ✅ Tous les autres systèmes (SCH, commandes, etc.)

## État Actuel

### Serveur Python
- ✅ Fonctionne normalement
- ✅ Reçoit les données des ALTs
- ✅ Web App accessible
- ❌ Pas de logique BRD AutoCast

### Windower Lua
- ✅ `AltControl.lua` fonctionne
- ✅ `AutoCast.lua` fonctionne
- ✅ `AutoCast_BRD.lua` existe mais est vide
- ❌ Pas de fonctionnalité AutoCast BRD

### Web App
- ✅ Toutes les pages fonctionnent
- ✅ Page AutoCast Config existe (mais ne fait rien pour le moment)
- ✅ Bouton AutoCast existe (mais ne fait rien pour le moment)

## Prochaines Étapes

### Approche SIMPLE pour reconstruire:

1. **Créer 2 commandes basiques dans Lua:**
   - `//ac cast_mage_songs` → Cast 2 songs mages hardcodés
   - `//ac cast_melee_songs` → Cast 2 songs melees hardcodés

2. **Tester manuellement:**
   - Vérifier que les commandes fonctionnent
   - Vérifier que le BRD cast bien les songs

3. **Ajouter la logique Python (SIMPLE):**
   - Thread qui check les buffs toutes les 10 secondes
   - Si buffs manquent → Envoie la commande
   - C'est TOUT

4. **Plus tard (si ça marche):**
   - Ajouter la config depuis le panel web
   - Ajouter les mouvements
   - Ajouter les debuffs

## Leçons Apprises

❌ **Ne PAS faire:**
- Système trop complexe dès le début
- Mélanger logique Lua et Python
- Cycles automatiques qui s'emballent
- Trop de vérifications imbriquées

✅ **À FAIRE:**
- Commencer SIMPLE
- Tester chaque étape
- Séparer clairement: Python = cerveau, Lua = exécutant
- Garder des backups à chaque étape qui marche

## Commandes de Test

Une fois reconstruit, tester dans cet ordre:
```
1. //lua r altcontrol
2. //ac start
3. //ac cast_mage_songs (manuel)
4. Vérifier que ça cast
5. Activer le système auto
```

## Fichiers Importants

- `FFXI_ALT_Control.py` - Serveur (nettoyé)
- `AutoCast_BRD.lua` - Module BRD (vide, à reconstruire)
- `AltControl.lua` - Addon principal (intact)
- `AutoCast.lua` - Module AutoCast (intact)

## Notes

Le système est maintenant PROPRE et prêt pour une reconstruction SIMPLE et PROGRESSIVE.

Pas de panique, pas de précipitation. On construit brique par brique.
