# Assets pour AltPetOverlay

## Images Nécessaires

Pour un rendu optimal style XIVParty, créer ces images :

### bg.png
- Taille : 400x50 pixels
- Fond semi-transparent noir (#000000DD)
- Coins arrondis optionnels

### bar_bg.png
- Taille : 300x12 pixels
- Fond sombre (#323232FF)
- Pour le fond de la barre HP

### bar.png
- Taille : 300x12 pixels
- Couleur unie (sera colorée dynamiquement)
- Pour la barre HP elle-même

## Alternative Simple

Si tu n'as pas les images, l'addon utilisera des rectangles de couleur simple via `images.new()`.

Pour un rendu style XIVParty, tu peux :
1. Extraire les assets de XIVParty (`assets/xiv/` folder)
2. Ou créer des images simples avec GIMP/Photoshop
3. Ou utiliser juste des couleurs (pas d'images)

## Version Sans Images

Pour tester sans images, modifie le code pour utiliser `texts` uniquement avec des caractères █░ pour les barres.
