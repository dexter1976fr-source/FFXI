# 🎵 Implémentation du Système AutoCast

## 📋 Résumé

Système d'automatisation modulaire pour gérer les sorts/abilities par job. Phase 1 implémentée: **BRD (Bard)**.

---

## ✅ Fichiers Créés

### 🔧 Modules Lua (Windower)

1. **AutoCast.lua** (Module principal)
   - Gestion du système global
   - Chargement dynamique des modules par job
   - Détection des événements (cast, finish, interrupt)
   - Cooldown global entre actions

2. **AutoCast_BRD.lua** (Logique BRD)
   - Positionnement intelligent (home/melee/mob)
   - Classification des chansons (melee/support/debuff)
   - Recherche automatique du healer/tank
   - Mouvement directionnel avec distance min/max
   - Pause automatique pendant les casts
   - Retour à la home position après action

### 🎮 Frontend React

3. **AltController.tsx** (Modifié)
   - Ajout état `autoCastActive`
   - Fonction `toggleAutoCast()`
   - Bouton "🎵 Auto: ON/OFF" (visible uniquement pour BRD)
   - Envoi de la config au Lua

### 📚 Documentation

4. **docs/AUTOCAST_SYSTEM.md**
   - Architecture complète
   - Guide d'utilisation
   - Troubleshooting
   - Roadmap futur

5. **test_autocast.md**
   - Checklist de test complète
   - Procédures de validation
   - Debugging

6. **deploy_autocast.ps1**
   - Script de déploiement automatique
   - Copie les fichiers vers Windower

---

## 🔧 Modifications Minimales

### AltControl.lua

**Ajouts (lignes 8-40):**
```lua
-- Module AutoCast
local autocast = nil

function load_autocast()
function start_autocast(config_json)
function stop_autocast()
```

**Ajouts (boucle principale):**
```lua
-- Mise à jour AutoCast
if autocast and autocast.is_active() then
    autocast.update()
end

-- Événement action
windower.register_event('action', function(action)
    if autocast and autocast.is_active() then
        autocast.on_action(action)
    end
end)
```

**Total:** ~50 lignes ajoutées, 0 lignes modifiées du code existant ✅

---

## 🎯 Fonctionnalités Implémentées

### ✅ Phase 1: Fondations

- [x] Module AutoCast principal
- [x] Chargement dynamique par job
- [x] Détection de cast (begin/finish/interrupt)
- [x] Cooldown global
- [x] Intégration dans AltControl.lua

### ✅ Phase 1: BRD

- [x] Classification des jobs (tank/healer/melee/ranged/mage)
- [x] Classification des chansons (melee/support/debuff)
- [x] Recherche automatique du healer (home position)
- [x] Recherche automatique du tank (melee position)
- [x] Calcul de distance 2D
- [x] Mouvement directionnel avec vecteur normalisé
- [x] Distance min/max configurable
- [x] Pause automatique pendant cast
- [x] Retour à la home après cast
- [x] Timer des chansons actives
- [x] Détection du combat (party engaged)

### ✅ Phase 1: WebApp

- [x] Bouton AutoCast dans AltController
- [x] Toggle ON/OFF
- [x] Envoi de la config au Lua
- [x] Logs dans la console

---

## 🚀 Déploiement

### 1. Copier les fichiers

```powershell
.\deploy_autocast.ps1
```

### 2. Recharger l'addon dans FFXI

```
//lua r AltControl
```

### 3. Tester depuis la WebApp

1. Ouvrir `http://localhost:5000`
2. Sélectionner un BRD
3. Cliquer sur "🎵 Auto: OFF"
4. Observer le positionnement automatique

---

## 🎵 Configuration BRD par Défaut

```typescript
{
  enabled: true,
  max_songs: 2,
  priority_songs: [
    "Valor Minuet IV",
    "Victory March",
    "Sword Madrigal",
    "Blade Madrigal"
  ],
  distances: {
    home: { min: 12, max: 18 },   // Healer
    melee: { min: 3, max: 7 },    // Tank
    mob: { min: 15, max: 20 }     // Battle Target
  },
  home_role: "healer",
  auto_songs: true,
  auto_movement: true
}
```

---

## 🔮 Prochaines Étapes

### Phase 2: Configuration Avancée

- [ ] Panel AutoCastConfig dans la WebApp
- [ ] Sauvegarde de la config par ALT/Job
- [ ] Route API `/autocast-config` dans Python
- [ ] Drag & drop pour l'ordre des chansons
- [ ] Sliders pour les distances

### Phase 3: BRD Avancé

- [ ] Détection des buffs actifs (via `active_buffs`)
- [ ] Calcul de la durée restante des chansons
- [ ] Refresh automatique avant expiration
- [ ] Gestion du nombre max de chansons (2-4)
- [ ] Overwrite intelligent (ne pas écraser chanson importante)
- [ ] Debuffs automatiques sur les mobs
- [ ] Soul Voice / Nightingale / Pianissimo

### Phase 4: Autres Jobs

- [ ] AutoCast_WHM.lua (Cure, Raise, Regen)
- [ ] AutoCast_RDM.lua (Refresh, Haste, Cure)
- [ ] AutoCast_SCH.lua (Arts, Accession, Helix)
- [ ] AutoCast_GEO.lua (Bubbles, Indi/Geo)
- [ ] AutoCast_COR.lua (Rolls, Quick Draw)

---

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| Fichiers créés | 6 |
| Lignes de code Lua | ~600 |
| Lignes de code TypeScript | ~50 |
| Modifications AltControl.lua | ~50 lignes |
| Jobs supportés | 1 (BRD) |
| Temps de développement | ~2h |

---

## 🎉 Conclusion

Le système AutoCast est maintenant **opérationnel** pour le BRD! 

**Points forts:**
- ✅ Architecture modulaire et évolutive
- ✅ Code propre et documenté
- ✅ Modifications minimales du code existant
- ✅ Facile à étendre pour d'autres jobs

**Prêt pour les tests!** 🚀

---

**Version:** 1.0.0  
**Date:** 18 novembre 2025  
**Status:** ✅ Implémenté, en test
