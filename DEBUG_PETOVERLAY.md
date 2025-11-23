# 🐛 Debug AltPetOverlay - L'overlay ne s'affiche plus

## 🔍 Diagnostic

### 1. Vérifier que l'addon est chargé

```lua
//lua list
```

**Chercher** : `AltPetOverlay` dans la liste

**Si absent** :
```lua
//lua load AltPetOverlay
```

---

### 2. Vérifier les erreurs au chargement

Regarder dans le chat log si des erreurs s'affichent quand tu charges l'addon.

**Erreurs possibles** :
- `module 'texts' not found` → Problème avec la library texts
- `module 'socket' not found` → Problème avec la library socket
- Erreur de syntaxe

---

### 3. Tester avec la commande test

```lua
//po test
```

**Si ça ne marche pas** :
- L'addon n'est pas chargé correctement
- Il y a une erreur dans le code

**Si ça marche** :
- Le problème vient de la communication IPC avec AltControl

---

### 4. Vérifier AltControl

```lua
//lua reload AltControl
```

Regarder si des erreurs s'affichent.

---

### 5. Vérifier la position de l'overlay

Peut-être que l'overlay est hors écran :

```lua
//po pos 100 500
```

---

## 🔧 Solutions rapides

### Solution 1 : Recharger tout

```lua
//lua unload AltPetOverlay
//lua unload AltControl
//lua load AltControl
//lua load AltPetOverlay
//po test
```

---

### Solution 2 : Vérifier les libraries

L'addon utilise :
- `texts` (pour le texte)
- `socket` (pour le timestamp)

Ces libraries doivent être présentes dans Windower.

---

### Solution 3 : Utiliser une version simplifiée

Si le problème persiste, on peut créer une version encore plus simple sans `windower.prim`.

---

## 📝 Informations à me donner

Pour que je puisse t'aider, dis-moi :

1. **Est-ce que l'addon se charge ?**
   ```lua
   //lua list
   ```

2. **Est-ce qu'il y a des erreurs dans le chat ?**
   (Copie-colle les messages d'erreur)

3. **Est-ce que `//po test` fonctionne ?**
   (Oui/Non)

4. **Est-ce que tu as un pet actif ?**
   (BST/SMN/DRG avec pet invoqué)

5. **Est-ce qu'AltControl est chargé ?**
   ```lua
   //lua list
   ```

---

## 🚨 Si rien ne marche

On peut revenir à une version plus simple qui utilise juste `texts` sans `windower.prim`.

Dis-moi ce que tu vois et je corrigerai !
