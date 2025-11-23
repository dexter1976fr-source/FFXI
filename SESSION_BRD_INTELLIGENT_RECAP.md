# 🎵 SESSION BRD INTELLIGENT - RÉCAPITULATIF COMPLET

**Date:** 19 Novembre 2025  
**Objectif:** Créer un système BRD intelligent qui détecte les buffs manquants et cast automatiquement

---

## 📁 STRUCTURE DES FICHIERS

### Fichiers Windower (A:\Jeux\PlayOnline\Windower4\addons\AltControl\)
- `AltControl.lua` - Addon principal, gère les commandes
- `AutoCast.lua` - Module AutoCast, délègue aux modules job
- `AutoCast_BRD.lua` - Module BRD spécifique, gère les songs et mouvements

### Fichiers Projet (A:\Jeux\PlayOnline\Projet Python\FFXI_ALT_Control\)
- `FFXI_ALT_Control.py` - Serveur Python, analyse les buffs et envoie commandes
- `Web_App/` - Interface web React

### Backups Importants
- `AutoCast_BRD_WORKING_MAGE_MELEE.lua` - Version STABLE (Mages + Melee qui marche)
- `AutoCast_BRD_BEFORE_SMART_LOGIC.lua` - Avant logique intelligente
- `FFXI_ALT_Control_BACKUP_BEFORE_BRD_LOGIC.py` - Serveur avant BRD Manager

---

## 🎯 CE QUI MARCHE ACTUELLEMENT

### ✅ Système de Base
1. **Commandes manuelles fonctionnelles:**
   - `//ac cast_mage_songs` - Force cast Ballad III + Victory March
   - `//ac cast_melee_songs` - Force cast Minuet V + Madrigal
   - `//ac enable_auto_songs` - Active le système auto
   - `//ac disable_auto_songs` - Désactive le système auto

2. **Gestion des mouvements:**
   - Follow automatique du healer (home_target)
   - Déplacement vers le melee pour songs melee
   - Queue system (pending_cast) pour éviter cast pendant mouvement
   - Retour automatique au healer après cast

3. **Détection des buffs (Serveur Python):**
   - Le serveur voit les buffs de tous les ALTs
   - Détecte "Ballad", "March", "Minuet", "Madrigal"
   - Alterne entre check mages et check melees

### ❌ Problèmes Actuels
1. **Le BRD se mélange les pinceaux:**
   - Cast parfois Ballad sur le melee au lieu du healer
   - Change d'avis entre les phases
   - Pas de distinction claire entre "cast sur healer" vs "cast sur melee"

2. **Timing:**
   - Parfois ne cast qu'un seul song au lieu de deux
   - Cooldown de 20 secondes peut être trop long ou trop court

---

## 🔧 ARCHITECTURE TECHNIQUE

### Flux de Données
```
Windower (Lua) → Serveur Python → Analyse Buffs → Envoie Commandes → Windower (Lua)
```

### Phases BRD (AutoCast_BRD.lua)
- `idle` - Repos, suit le healer
- `cast_mages` - Cast 2 songs mages sur `<me>` (près du healer)
- `cast_melees` - Cast 2 songs melees sur `<me>` (près du melee)
- `cast_debuff` - Cast debuff sur `<bt>` (désactivé pour le moment)

### Logique Serveur (FFXI_ALT_Control.py)
```python
# Fonction: brd_intelligent_manager()
# Appelée toutes les 10 secondes
# Alterne: mages → melees → mages → melees

if brd_next_check == "mages":
    if healer manque Ballad OU March:
        send_command("//ac cast_mage_songs")
        brd_next_check = "melees"
    else:
        brd_next_check = "melees"

elif brd_next_check == "melees":
    if melee manque Minuet OU Madrigal:
        send_command("//ac cast_melee_songs")
        brd_next_check = "mages"
    else:
        brd_next_check = "mages"
```

---

## 🐛 PROBLÈME PRINCIPAL À RÉSOUDRE

**Le BRD cast sur la mauvaise cible!**

### Cause Probable
Quand `force_cast_mages()` est appelé, le BRD:
1. Passe en phase `cast_mages`
2. Cast les songs sur `<me>` (lui-même)
3. Mais il est peut-être près du melee au lieu du healer!

### Solution à Implémenter
Il faut que `force_cast_mages()` force le BRD à:
1. Retourner au healer AVANT de caster
2. Attendre d'être près du healer
3. PUIS caster les songs

Même chose pour `force_cast_melees()`:
1. Aller vers le melee
2. Attendre d'être près
3. PUIS caster

---

## 📝 CONFIGURATION ACTUELLE

### Songs Configurés (AutoCast_BRD.lua)
```lua
mage_songs = {
    "Mage's Ballad III",
    "Victory March",
}
melee_songs = {
    "Valor Minuet V",
    "Sword Madrigal",
}
```

### Timings
- `cycle_cooldown = 3` secondes (entre chaque song)
- `cycle_phase_timeout = 45` secondes (timeout phase)
- `brd_check_interval = 10` secondes (serveur check buffs)
- `brd_cast_cooldown = 20` secondes (cooldown entre commandes serveur)

### Distances
```lua
distances = {
    home = {min = 0.5, max = 2},    -- Distance du healer
    melee = {min = 1, max = 3},     -- Distance du melee
}
```

---

## 🚀 PROCHAINES ÉTAPES (Avec compte femme)

1. **Corriger le problème de cible:**
   - Forcer le retour au healer avant cast_mages
   - Forcer le déplacement vers melee avant cast_melees
   - Ajouter un état "moving_to_target" avant "casting"

2. **Améliorer la détection:**
   - Vérifier que le BRD est bien positionné avant de caster
   - Ajouter un délai après mouvement avant cast

3. **Ajouter les debuffs:**
   - Phase debuff intelligente
   - Timer de 2 minutes
   - Cast sur `<bt>` après assist

4. **Interface web:**
   - Afficher l'état du BRD (phase actuelle)
   - Afficher les buffs actifs de chaque membre
   - Bouton pour forcer un refresh

---

## 💾 COMMANDES UTILES

### Windower
```
//lua r altcontrol              # Recharger l'addon
//ac start                       # Démarrer AutoCast
//ac stop                        # Arrêter AutoCast
//ac enable_auto_songs          # Activer auto-songs
//ac cast_mage_songs            # Forcer cast mages
//ac cast_melee_songs           # Forcer cast melees
//ac follow <nom>               # Définir qui suivre
```

### Serveur Python
- Arrêter/Relancer via GUI
- Les changements Python nécessitent un restart
- Les changements Lua nécessitent `//lua r altcontrol`

---

## 📊 CRÉDITS UTILISÉS

**Session totale:** ~460 crédits  
**Restants:** ~40 crédits

**Accomplissements:**
- Système BRD complet de A à Z
- Détection intelligente des buffs
- Gestion automatique des mouvements
- Intégration serveur Python ↔ Windower Lua
- Interface web avec bouton activation

---

## 🎵 NOTES IMPORTANTES

1. **Le système de base MARCHE** - Les commandes manuelles fonctionnent parfaitement
2. **Le problème est dans la coordination** - Le BRD ne sait pas où il doit être avant de caster
3. **La détection des buffs fonctionne** - Le serveur voit correctement les buffs manquants
4. **Il faut séparer "décision" et "exécution"** - Le serveur décide, le Lua exécute proprement

---

## 🔄 POUR REPRENDRE LA SESSION

1. Lire ce document en entier
2. Tester les commandes manuelles pour vérifier que la base marche
3. Observer le comportement actuel (logs Windower + logs serveur)
4. Identifier précisément où le BRD se trompe de cible
5. Corriger la logique de positionnement avant cast

**Bon courage pour la suite!** 🎵
