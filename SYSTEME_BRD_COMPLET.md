# 🎵 SYSTÈME BRD COMPLET - FONCTIONNEMENT ATTENDU

## 📋 OBJECTIF
Le BRD doit caster automatiquement les songs SEULEMENT quand les buffs manquent, en utilisant les songs configurés dans la page web.

## 🔄 FLUX COMPLET

### 1. CONFIGURATION (Page Web)
```
Utilisateur → Page AutoCast Config
  ↓
Choisit: Healer Target, Melee Target, Mage Songs, Melee Songs
  ↓
Clique "Sauvegarder"
  ↓
POST /autocast/config → Serveur Python
  ↓
Sauvegarde dans: data_json/autocast_config.json
  ET
Sauvegarde dans: Windower4/addons/AltControl/data/autocast_config.json
```

### 2. DÉMARRAGE (Bouton Web App)
```
Utilisateur clique bouton "AutoCast"
  ↓
Web App envoie: POST /command avec "//ac start"
  ↓
Serveur Python → UDP → BRD Lua
  ↓
AltControl.lua reçoit commande "start"
  ↓
Appelle start_autocast()
  ↓
Charge AutoCast.lua
  ↓
AutoCast.lua charge AutoCast_BRD.lua
  ↓
AutoCast_BRD.lua charge config depuis fichier JSON
  ↓
BRD en mode "idle" (attend commandes du serveur)
```

### 3. VÉRIFICATION AUTOMATIQUE (Serveur Python)
```
Thread BRD Manager tourne en boucle (toutes les 1 seconde)
  ↓
Toutes les 5 secondes: brd_intelligent_manager()
  ↓
Charge config depuis: Windower4/addons/AltControl/data/autocast_config.json
  ↓
Extrait keywords des songs configurés (ex: "Ballad", "Minuet")
  ↓
Vérifie si quelqu'un est engagé
  ↓
Alterne entre check "mages" et "melees"
  ↓
Vérifie les buffs du healer/melee
  ↓
Si keywords manquants ET cooldown écoulé (20s):
  ↓
Envoie commande: "//ac cast_mage_songs" ou "//ac cast_melee_songs"
```

### 4. CAST (BRD Lua)
```
AltControl.lua reçoit "cast_mage_songs"
  ↓
Vérifie: autocast.is_active() == true
  ↓
Appelle: autocast.force_cast_mages()
  ↓
AutoCast.lua → job_module.force_cast_mages()
  ↓
AutoCast_BRD.lua: brd.force_cast_mages()
  ↓
Met cycle_phase = "mages"
  ↓
brd.update_songs() exécute le cycle
  ↓
Cast song 1, attend 3s, cast song 2
  ↓
Retourne en "idle"
```

## ✅ POINTS DE VÉRIFICATION

### Fichier: autocast_config.json
- [ ] Existe dans: data_json/autocast_config.json
- [ ] Existe dans: Windower4/addons/AltControl/data/autocast_config.json
- [ ] Contient: healerTarget, meleeTarget, mageSongs, meleeSongs

### Serveur Python (FFXI_ALT_Control.py)
- [ ] Thread BRD Manager démarre: `[BRD Manager] Thread started`
- [ ] Loop tourne: `[BRD Manager] Loop started`
- [ ] Fonction load_brd_config_for_check() existe
- [ ] Fonction extract_song_keywords() existe
- [ ] Fonction brd_intelligent_manager() existe
- [ ] Vérifie buffs toutes les 5s: `[BRD Manager] Checking...`
- [ ] Détecte buffs manquants: `[BRD Manager] ... missing ... buffs`
- [ ] Envoie commande: `[COMMAND] '//ac cast_mage_songs'`

### Lua: AltControl.lua
- [ ] Commande "start" existe et appelle start_autocast()
- [ ] Commande "cast_mage_songs" existe
- [ ] Vérifie autocast.is_active()
- [ ] Appelle autocast.force_cast_mages()
- [ ] Affiche: `[AltControl] 📥 Received cast_mage_songs command`
- [ ] Affiche: `[AltControl] ✅ Calling autocast.force_cast_mages()`

### Lua: AutoCast.lua
- [ ] Fonction start() existe
- [ ] Fonction load_job_module() existe
- [ ] Fonction force_cast_mages() existe
- [ ] Appelle job_module.force_cast_mages()
- [ ] Charge config depuis fichier au démarrage

### Lua: AutoCast_BRD.lua
- [ ] Fonction load_config_from_file() existe
- [ ] Fonction force_cast_mages() existe
- [ ] Fonction force_cast_melees() existe
- [ ] Cycle NE démarre PAS automatiquement (ligne 283 commentée)
- [ ] force_cast_mages() met cycle_phase = "mages"
- [ ] update_songs() exécute le cycle quand phase != "idle"

### Web App
- [ ] Bouton AutoCast envoie: `//ac start`
- [ ] NE PAS envoyer: `//ac enable_auto_songs`
- [ ] Page AutoCast Config sauvegarde dans les 2 fichiers

## 🐛 PROBLÈMES ACTUELS À RÉSOUDRE

1. **AutoCast ne démarre pas** → Vérifier start_autocast() et autocast.start()
2. **Config pas chargée** → Vérifier load_config_from_file() appelée au bon moment
3. **Cycle démarre automatiquement** → Vérifier ligne 283 commentée
4. **force_cast ne fonctionne pas** → Vérifier que les fonctions existent

## 🔧 PROCHAINES ÉTAPES

1. Vérifier chaque point de la checklist
2. Corriger les problèmes un par un
3. Tester le flux complet
4. Documenter ce qui fonctionne
