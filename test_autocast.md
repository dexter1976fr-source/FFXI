# 🧪 Test AutoCast BRD

## Checklist de Test

### ✅ Phase 1: Chargement des Modules

1. **Déployer les fichiers**
   ```powershell
   .\deploy_autocast.ps1
   ```

2. **Dans FFXI (avec un BRD)**
   ```
   //lua r AltControl
   ```
   
   **Résultat attendu:**
   - Pas d'erreur Lua
   - Message: `[AltControl] Listening on 127.0.0.1:5007`

3. **Charger AutoCast manuellement**
   ```
   //lua i AltControl load_autocast()
   ```
   
   **Résultat attendu:**
   - Message: `[AltControl] ✅ AutoCast module loaded`

---

### ✅ Phase 2: Démarrage AutoCast

4. **Démarrer AutoCast avec config par défaut**
   ```
   //lua i AltControl start_autocast()
   ```
   
   **Résultat attendu:**
   - Message: `[AutoCast] ✅ Started for BRD`
   - Message: `[BRD AutoCast] 🎵 Initialized`

5. **Vérifier l'état**
   ```
   //lua i AltControl print(autocast and autocast.is_active())
   ```
   
   **Résultat attendu:**
   - `true`

---

### ✅ Phase 3: Test du Positionnement

6. **Être dans une party avec un healer (WHM/RDM/SCH)**
   - Le BRD devrait commencer à se déplacer vers le healer
   - Distance cible: 12-18 yalms

7. **Observer le mouvement**
   - Le BRD doit se rapprocher si trop loin (>18y)
   - Le BRD doit s'éloigner si trop proche (<12y)
   - Le BRD doit s'arrêter si distance OK (12-18y)

---

### ✅ Phase 4: Test du Cast

8. **Caster un sort manuellement**
   ```
   /ma "Valor Minuet IV" <me>
   ```
   
   **Résultat attendu:**
   - Pendant le cast: Le BRD s'arrête de bouger
   - Message: `[BRD AutoCast] ⏸️ Movement paused for cast`
   - Après le cast: Le BRD reprend le mouvement
   - Message: `[BRD AutoCast] ✅ Cast finished`

---

### ✅ Phase 5: Test depuis la WebApp

9. **Ouvrir la WebApp**
   - Aller sur `http://localhost:5000`
   - Sélectionner le BRD

10. **Cliquer sur le bouton "🎵 Auto: OFF"**
    
    **Résultat attendu:**
    - Le bouton devient "🎵 Auto: ON" (vert)
    - Dans FFXI: Messages AutoCast
    - Le BRD commence à se positionner

11. **Vérifier la console du navigateur (F12)**
    ```
    [AutoCast] Starting for Mycharacter (BRD)
    [AutoCast] Config: {...}
    ```

12. **Cliquer sur "🎵 Auto: ON" pour arrêter**
    
    **Résultat attendu:**
    - Le bouton redevient "🎵 Auto: OFF"
    - Dans FFXI: `[AutoCast] 🛑 Stopped`
    - Le BRD s'arrête de bouger

---

### ✅ Phase 6: Test en Combat

13. **Engager un mob avec un autre personnage**
    - Le BRD devrait détecter le combat
    - Le BRD devrait commencer à caster les chansons prioritaires

14. **Observer le cycle de chansons**
    - Cast de Valor Minuet IV
    - Attente 3 secondes (cooldown)
    - Cast de Victory March
    - Etc.

---

## 🐛 Problèmes Connus

### Le BRD ne bouge pas

**Causes possibles:**
- Pas de healer dans la party
- `auto_movement: false` dans la config
- Le BRD est déjà à la bonne distance

**Solution:**
```
//lua i AltControl stop_autocast()
//lua i AltControl start_autocast()
```

### Erreur "module not found"

**Cause:**
- Les fichiers ne sont pas au bon endroit

**Solution:**
```powershell
.\deploy_autocast.ps1
```
Puis dans FFXI:
```
//lua r AltControl
```

### Le BRD cast en boucle la même chanson

**Cause:**
- Le timer de chanson n'est pas correctement géré

**Solution temporaire:**
- Désactiver `auto_songs` dans la config
- Utiliser seulement `auto_movement` pour l'instant

---

## 📊 Résultats Attendus

| Test | Statut | Notes |
|------|--------|-------|
| Chargement modules | ⏳ | |
| Démarrage AutoCast | ⏳ | |
| Positionnement | ⏳ | |
| Pause pendant cast | ⏳ | |
| Bouton WebApp | ⏳ | |
| Combat auto | ⏳ | |

**Légende:**
- ⏳ À tester
- ✅ OK
- ❌ Échec
- ⚠️ Partiel

---

## 🎯 Prochaines Étapes

Si tous les tests passent:
1. ✅ Affiner les distances
2. ✅ Ajouter la détection des buffs actifs
3. ✅ Implémenter la rotation de chansons
4. ✅ Créer le panel de configuration dans Admin
5. ✅ Ajouter les autres jobs (WHM, RDM, SCH)

---

**Date du test:** _________________  
**Testeur:** _________________  
**Version:** 1.0.0
