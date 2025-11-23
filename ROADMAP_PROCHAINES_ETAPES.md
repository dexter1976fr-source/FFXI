# 🗺️ ROADMAP - Prochaines étapes

## ✅ Phase 1 : BRD & SCH AutoCast (TERMINÉ)

### Fonctionnalités implémentées :
- ✅ Boutons ON/OFF avec feedback visuel instantané
- ✅ BRD : Cycle automatique Mage → Melee → Retour
- ✅ SCH : Follow adaptatif avec DistanceFollow
- ✅ Détection automatique du healer
- ✅ Arrêt propre de tous les systèmes
- ✅ Sécurité : Reset automatique si cycle bloqué (30s)

### Bugs connus à surveiller :
- ⚠️ BRD aggro pendant retour vers healer → Cycle peut se bloquer (timeout 30s devrait gérer)
- ⚠️ Combat qui se termine pendant un cast → Follow doit reprendre (fix ajouté)

---

## 🎯 Phase 2 : Améliorations BRD (À FAIRE)

### Priorité HAUTE :
1. **Gestion des interruptions**
   - Détecter quand un song est interrompu
   - Réessayer automatiquement le song interrompu
   - Timeout plus court (15s au lieu de 30s ?)

2. **Optimisation du positionnement**
   - Améliorer le retour vers healer (éviter les obstacles)
   - Gérer les cas d'aggro pendant le cycle
   - Option : Auto-flee si aggro ?

3. **Configuration avancée**
   - Choix des songs par situation (party size, jobs présents)
   - Priorité des buffs (heal > melee > tank ?)
   - Durée minimale avant refresh des songs

### Priorité MOYENNE :
4. **Interface web améliorée**
   - Affichage des buffs actifs en temps réel
   - Indicateur visuel du cycle en cours (Mage/Melee)
   - Bouton "Force Reset" pour débloquer manuellement

5. **Logs et monitoring**
   - Historique des songs castés
   - Statistiques : uptime des buffs, nombre de cycles
   - Alertes si cycle bloqué trop souvent

### Priorité BASSE :
6. **Features avancées**
   - Support des Debuffs (Elegy, Requiem, etc.)
   - Gestion des Clarion Call / Soul Voice
   - Auto-switch songs selon la situation

---

## 🔮 Phase 3 : Autres jobs (FUTUR)

### Jobs à implémenter :
1. **WHM (White Mage)**
   - Auto-Cure selon HP%
   - Buffs automatiques (Protect, Shell, Haste)
   - Raise automatique

2. **RDM (Red Mage)**
   - Refresh automatique
   - Haste sur melees
   - Dispel sur ennemis

3. **COR (Corsair)**
   - Rolls automatiques
   - Quick Draw sur ennemis
   - Gestion des Phantom Rolls

4. **GEO (Geomancer)**
   - Bubbles automatiques
   - Indi/Geo selon situation
   - Entrust sur support

---

## 🛠️ Phase 4 : Infrastructure (CONTINU)

### Améliorations techniques :
- [ ] Système de plugins pour ajouter facilement de nouveaux jobs
- [ ] API REST complète pour contrôle externe
- [ ] Sauvegarde/restauration des configurations
- [ ] Mode "Simulation" pour tester sans être en jeu
- [ ] Documentation complète pour développeurs

### Optimisations :
- [ ] Réduire la latence entre détection et action
- [ ] Cache intelligent pour les données de party
- [ ] Compression des logs pour performances
- [ ] Mode "Performance" avec moins de checks

---

## 📝 Notes de développement

### Architecture actuelle :
```
FFXI_ALT_Control.py (Serveur Python)
├── BRD Manager (Thread)
├── SCH Manager (Thread)
└── Flask API (/brd/autocast, /sch/autocast)

AltControl.lua (Addon Windower)
├── AutoCast.lua (Module principal)
├── AutoCast_BRD.lua (Module BRD)
└── Commands (//ac start, //ac stop, etc.)

Web App (React/TypeScript)
└── AltController.tsx (Interface utilisateur)
```

### Conventions de code :
- Logs importants : `print('[Module] ✅ Message')`
- Logs de debug : `# Debug: print(...)`  (commentés en production)
- Erreurs : `print('[Module] ❌ Error: ...')`
- Warnings : `print('[Module] ⚠️ Warning: ...')`

### Tests à effectuer régulièrement :
1. Cycle complet BRD (Mage → Melee → Retour)
2. Interruption pendant cast
3. Desengage pendant cycle
4. Aggro pendant retour
5. ON/OFF rapide multiple fois
6. Changement de healer en cours de cycle

---

**Dernière mise à jour** : 21 Novembre 2025 - 23h30
**Status** : Phase 1 terminée, Phase 2 en préparation
