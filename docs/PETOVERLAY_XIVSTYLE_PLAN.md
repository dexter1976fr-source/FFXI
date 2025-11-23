# 🎨 AltPetOverlay - Style XIVParty Complet

## 🎯 Objectif

Créer un overlay avec le **même style visuel** que XIVParty pour la cohésion avec les autres addons FFXIV-style.

---

## ✅ État Actuel

- ✅ Overlay fonctionne (texte simple)
- ✅ IPC fonctionne
- ✅ Données s'affichent
- ✅ Assets XIVParty copiés

## 🎨 Ce qu'il Faut

### Style XIVParty = 3 composants

1. **Background** (fond avec bordures)
   - Images : `BgTop.png`, `BgMid.png`, `BgBottom.png`
   - Couleur semi-transparente

2. **HP Bar** (barre graphique)
   - Images : `Bar.png`, `BarBG.png`, `BarFG.png`, `BarGlow.png`
   - Couleurs dynamiques (vert/jaune/orange/rouge)
   - Animation smooth

3. **Text** (noms, valeurs)
   - Font : Grammara (ou Arial)
   - Couleurs : blanc avec stroke noir
   - Alignement propre

---

## 📋 Plan d'Implémentation

### Phase 1 : Utiliser les UI Components XIVParty

On va utiliser directement les fichiers copiés :
- `uiElement.lua` - Base
- `uiImage.lua` - Pour les images
- `uiBar.lua` - Pour les barres HP
- `uiText.lua` - Pour le texte

### Phase 2 : Créer PetListItem

Créer un composant qui affiche UN pet avec le style XIVParty :

```lua
-- petListItem.lua
local PetListItem = {}

function PetListItem:new(pet_data, index)
    -- Position
    local y = index * 50
    
    -- Background (comme XIVParty)
    self.bg = uiImage:new({
        path = 'assets/xiv/BgMid.png',
        pos = {x = 0, y = y},
        size = {width = 400, height = 46}
    })
    
    -- HP Bar (comme XIVParty)
    self.hpBar = uiBar:new({
        pos = {x = 10, y = y + 10},
        size = {width = 300, height = 12},
        images = {
            bg = 'assets/xiv/BarBG.png',
            bar = 'assets/xiv/Bar.png',
            fg = 'assets/xiv/BarFG.png'
        }
    })
    
    -- Name Text
    self.nameText = uiText:new({
        text = pet_data.owner .. ' → ' .. pet_data.name,
        pos = {x = 10, y = y + 5},
        color = '#FFFFFF'
    })
    
    -- HP Value Text
    self.hpText = uiText:new({
        text = pet_data.hp .. '/' .. pet_data.max_hp,
        pos = {x = 320, y = y + 10},
        color = '#FFFFFF'
    })
end

function PetListItem:update(pet_data)
    -- Update HP bar
    local hp_percent = pet_data.hp / pet_data.max_hp
    self.hpBar:setValue(hp_percent)
    
    -- Update color
    if hp_percent < 0.25 then
        self.hpBar:setColor('#FC8182FF') -- Red
    elseif hp_percent < 0.50 then
        self.hpBar:setColor('#F8BA80FF') -- Orange
    elseif hp_percent < 0.75 then
        self.hpBar:setColor('#F3F37CFF') -- Yellow
    else
        self.hpBar:setColor('#A0F080FF') -- Green
    end
    
    -- Update text
    self.hpText:setText(pet_data.hp .. '/' .. pet_data.max_hp)
end
```

### Phase 3 : Intégrer dans Main

```lua
-- AltPetOverlay.lua
local petListItems = {}

function update_display()
    local index = 0
    
    for owner, pet_data in pairs(pets) do
        if not petListItems[owner] then
            -- Créer nouveau item
            petListItems[owner] = PetListItem:new(pet_data, index)
        else
            -- Update existant
            petListItems[owner]:update(pet_data)
        end
        index = index + 1
    end
end
```

---

## ⏱️ Estimation

- **Phase 1** : Comprendre les UI components (1h)
- **Phase 2** : Créer PetListItem (2h)
- **Phase 3** : Intégrer et tester (1h)
- **Polish** : Ajuster positions, couleurs (1h)

**Total : ~5h de travail**

---

## 🚀 Alternative Rapide

Si 5h c'est trop long, on peut :

1. **Améliorer le style actuel** avec de meilleures couleurs/fonts (30min)
2. **Ajouter un background** semi-transparent (30min)
3. **Utiliser des caractères Unicode** plus jolis pour les barres (30min)

Résultat : Pas exactement XIVParty mais **beaucoup mieux** que maintenant, en 1h30.

---

## 💡 Ma Recommandation

**Pour aujourd'hui :**
1. Améliorer le style actuel (1h30)
2. Intégrer avec AltControl pour les vraies données (1h)
3. Tester avec tes vrais pets (30min)

**Plus tard (quand tu veux) :**
- Implémenter le vrai style XIVParty (5h)

**Qu'est-ce que tu préfères ?**
- A) On améliore le style actuel maintenant (rapide)
- B) On fait le vrai style XIVParty maintenant (long mais parfait)
- C) On intègre d'abord avec AltControl, style après

---

**Date:** 23 novembre 2024  
**Status:** Planification style graphique
