# TODO - BardCycle pour la prochaine session

## ✅ Ce qui est fait

1. **Sélection du Main Character**
   - Dropdown ajouté dans Home.tsx (au-dessus des ALT 1/2)
   - Sauvegarde automatique à chaque changement
   - Routes backend `/party/roles` (GET/POST)
   - Fichier `party_roles.json` dans `data_json/`

## 🎯 Prochaine étape : Créer BardCycle.lua

### Architecture proposée

```
tools/BardCycle.lua
│
├─ Config
│  ├─ main_character (lu depuis party_roles.json)
│  ├─ healer_name (string)
│  ├─ melee_name (string)
│  ├─ mage_songs (array de 2 songs)
│  └─ melee_songs (array de 2 songs)
│
├─ State Machine
│  ├─ idle (attend engagement du main)
│  ├─ moving_to_healer (DistanceFollow vers healer)
│  ├─ checking_mage_buffs (vérifie buffs du healer)
│  ├─ casting_mage_songs (cast 2 songs mage)
│  ├─ checking_melee_buffs (vérifie buffs du melee)
│  ├─ moving_to_melee (DistanceFollow vers melee)
│  ├─ casting_melee_songs (cast 2 songs melee)
│  ├─ returning_to_healer (DistanceFollow vers healer)
│  └─ cooldown (attendre 20s avant re-check)
│
└─ Fonctions
   ├─ load_config() (lit config depuis JSON)
   ├─ check_buffs(target_name, song_names) (vérifie buffs)
   ├─ cast_song(song_name) (cast un song)
   ├─ update() (appelée toutes les 0.1s, gère la state machine)
   ├─ start() (démarre le cycle)
   └─ stop() (arrête le cycle)
```

### Questions à répondre

1. **Healer/melee toujours dans la party ?** → Oui/Non
2. **Timing songs :** Attendre buff ou attendre 4s ? → À décider
3. **Cooldown cycle :** 20s ok ? → À confirmer
4. **Distance healer :** 10-18 yalms ok ? → À confirmer
5. **Distance melee :** Combien ? → À définir

### Cycle complet

```
1. Main engage détecté
   ↓
2. BRD → DistanceFollow healer (10-18 yalms)
   ↓
3. Check buffs mage (healer)
   ↓
4. Si manquants → Cast 2 songs mage (attendre 4s entre chaque)
   ↓
5. Check buffs melee (melee target)
   ↓
6. Si manquants → DistanceFollow melee → Cast 2 songs melee
   ↓
7. Retour healer (DistanceFollow)
   ↓
8. Boucle (check toutes les 20s)
```

### Intégration

- Chargé par Extended (comme AutoEngage/DistanceFollow)
- Commandes: `//ac bardcycle start/stop`
- Webapp: Bouton ON/OFF + config (healer, melee, songs)

### Buff IDs à utiliser

Exemples de buff IDs pour les songs :
- Ballad: 195
- March: 214
- Minuet: 198
- Madrigal: 199
- Mambo: 200
- Paeon: 196

(À compléter avec la liste complète)

## 📝 Notes

- Tout le cycle en Lua (pas de Python)
- Webapp juste pour ON/OFF et config
- Utilise DistanceFollow pour les mouvements
- Détection du main via party_roles.json

## 💡 Idée future : Auto-start serveur Python

Lua peut lancer un .exe avec `os.execute()` :
```lua
os.execute('start "" "python" "C:\\chemin\\vers\\FFXI_ALT_Control.py"')
```

**À implémenter plus tard :**
- Core démarre → lance automatiquement le serveur Python
- Plus besoin de lancer manuellement
- Tout automatique ! 🚀

---

**Prêt pour la prochaine session ! 🎵**
