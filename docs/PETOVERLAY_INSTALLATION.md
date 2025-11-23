# 🎨 AltPetOverlay - Installation et Test

## 📦 Installation

### Étape 1 : Copier le fichier

```bash
# Copier dans Windower addons
copy AltPetOverlay_Simple.lua "A:\Jeux\PlayOnline\Windower4\addons\AltPetOverlay\AltPetOverlay.lua"
```

### Étape 2 : Charger l'addon

```
//lua load AltPetOverlay
```

## 🧪 Test Rapide

### Test avec données fictives

```
//po test
```

Tu devrais voir apparaître :
```
Dexterbrown → BlackbeardRandy
██████████░░░░░░░░░░░░░░░░░░░░ 650/1000
Ready: ● ● ● ○ ○ (3/5)

Summoner → Ifrit
████████████████████████░░░░░░ 800/1000
Blood Pact: 2.5s
```

### Commandes disponibles

```
//po pos <x> <y>  - Changer position
//po hide         - Cacher
//po show         - Afficher
//po test         - Données test
//po clear        - Effacer données
```

---

## 🔗 Intégration avec AltControl

### Modifier AltControl.lua (BST exemple)

Ajouter à la fin du fichier :

```lua
-- ============================================
-- PET OVERLAY INTEGRATION
-- ============================================

local last_pet_overlay_update = 0

function send_pet_to_overlay()
    if not pet.isvalid then return end
    
    local player = windower.ffxi.get_player()
    
    -- Calculate ready charges (BST specific)
    local ready_charges = 0
    local recast = windower.ffxi.get_ability_recasts()[102] -- Sic
    if recast then
        local charge_time = 30 -- Base charge time
        ready_charges = math.floor((charge_time * 5 - recast) / charge_time)
        ready_charges = math.max(0, math.min(5, ready_charges))
    end
    
    -- Build IPC message
    local msg = string.format(
        "petoverlay_owner:%s_pet:%s_hp:%d_maxhp:%d_charges:%d",
        player.name,
        pet.name,
        pet.hp,
        pet.max_hp,
        ready_charges
    )
    
    -- Send via IPC
    windower.send_ipc_message(msg)
end

-- Send pet data every 100ms
windower.register_event('prerender', function()
    local now = os.clock()
    if now - last_pet_overlay_update > 0.1 then
        send_pet_to_overlay()
        last_pet_overlay_update = now
    end
end)
```

### Pour SMN

```lua
function send_pet_to_overlay()
    if not pet.isvalid then return end
    
    local player = windower.ffxi.get_player()
    
    -- Calculate BP timer
    local bp_recast = windower.ffxi.get_ability_recasts()[173] -- Blood Pact: Rage
    
    local msg = string.format(
        "petoverlay_owner:%s_pet:%s_hp:%d_maxhp:%d_bp_timer:%.1f",
        player.name,
        pet.name,
        pet.hp,
        pet.max_hp,
        bp_recast or 0
    )
    
    windower.send_ipc_message(msg)
end
```

### Pour DRG

```lua
function send_pet_to_overlay()
    if not pet.isvalid then return end
    
    local player = windower.ffxi.get_player()
    
    -- Check if Healing Breath is ready (simplified)
    local breath_ready = pet.hpp < 75 -- Wyvern uses breath when < 75% HP
    
    local msg = string.format(
        "petoverlay_owner:%s_pet:%s_hp:%d_maxhp:%d_breath_ready:%s",
        player.name,
        pet.name,
        pet.hp,
        pet.max_hp,
        tostring(breath_ready)
    )
    
    windower.send_ipc_message(msg)
end
```

---

## 🎨 Positionnement

### Placer sous XIVParty

Si XIVParty est à `y = 100`, place l'overlay à `y = 400` :

```
//po pos 100 400
```

### Ajuster selon ta résolution

- **1920x1080** : `//po pos 100 400`
- **2560x1440** : `//po pos 150 600`
- **3840x2160** : `//po pos 200 800`

---

## 🔧 Troubleshooting

### L'overlay ne s'affiche pas

1. Vérifier que l'addon est chargé :
   ```
   //lua list
   ```

2. Tester avec données fictives :
   ```
   //po test
   ```

3. Vérifier la position :
   ```
   //po pos 100 100
   ```

### Pas de données des alts

1. Vérifier que AltControl envoie les données :
   - Ajouter `windower.add_to_chat(122, 'Sending: ' .. msg)` dans `send_pet_to_overlay()`

2. Vérifier l'IPC :
   - Les deux addons doivent être sur le même PC
   - Windower IPC doit être activé

### Données ne se mettent pas à jour

1. Vérifier le prerender loop dans AltControl
2. Vérifier que le pet existe (`pet.isvalid`)
3. Vérifier les logs Windower

---

## 📈 Prochaines Étapes

### Phase 1 : Test Basique ✅
- [x] Créer overlay simple
- [ ] Tester avec //po test
- [ ] Ajuster position

### Phase 2 : Intégration
- [ ] Ajouter code dans AltControl_BST.lua
- [ ] Tester avec vrai pet
- [ ] Vérifier IPC fonctionne

### Phase 3 : Multi-Jobs
- [ ] Adapter pour SMN
- [ ] Adapter pour DRG
- [ ] Tester avec plusieurs alts

### Phase 4 : Polish
- [ ] Ajouter images style XIVParty
- [ ] Améliorer couleurs
- [ ] Sauvegarder settings

---

## 💡 Conseils

1. **Commence simple** : Test avec `//po test` d'abord
2. **Un job à la fois** : BST d'abord, puis SMN, puis DRG
3. **Vérifie l'IPC** : Utilise `windower.add_to_chat()` pour debug
4. **Ajuste la position** : Trouve ce qui te convient
5. **Sauvegarde** : Note ta position préférée

---

**Date:** 23 novembre 2024  
**Version:** 1.0 - Installation guide  
**Status:** Ready to test
