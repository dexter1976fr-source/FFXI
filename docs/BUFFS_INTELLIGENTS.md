# 🛡️ Système de Buffs Intelligents

## ✅ Étape 1: Détection des buffs (TERMINÉ)

### Lua
- ✅ Fonction `get_active_buffs()` ajoutée
- ✅ Détection des buffs SCH (Light/Dark Arts, Addendum, Stratagems)
- ✅ Envoi des buffs au serveur
- ✅ **CORRECTION**: Fonction `is_array()` pour détecter les arrays Lua
- ✅ **CORRECTION**: `table_to_json()` convertit les arrays en JSON arrays `[]` au lieu d'objets `{}`

### Python
- ✅ Réception des buffs dans `handle_client()`
- ✅ Stockage dans `alts[alt_name]["active_buffs"]`
- ✅ Envoi aux clients via `get_alt_abilities()`
- ✅ **CORRECTION**: Parsing des buffs (dict ou list) pour garantir un array
- ✅ **CORRECTION**: Logs de debug pour tracer le type de données

### TypeScript
- ✅ Type `active_buffs?: string[]` ajouté
- ✅ **CORRECTION**: Simplification de la détection (plus besoin de conversion dict→array)

### Configuration
- ✅ Fichier `spell_requirements.json` créé
- ✅ Prérequis définis pour tous les sorts SCH avancés

## ✅ Étape 2: Affichage des buffs (TERMINÉ)

### SCH Arts Mode Indicator
- ✅ Affichage dans le header de l'ALT
- ✅ Indicateur visuel avec couleurs:
  - 🔵 Light = fond bleu (`bg-blue-600`)
  - ⚫ Dark = fond noir (`bg-gray-900`) avec bordure grise
  - ⚪ None = fond gris (`bg-gray-600`)
- ✅ Mise à jour automatique via WebSocket
- ✅ Détection de Light Arts, Dark Arts, Addendum: White, Addendum: Black
- ✅ Récupération de TOUS les buffs via ressources Windower (plus de liste manuelle!)

## 🎯 Étape 3: Logique intelligente (À VENIR)

### À faire
- [ ] Charger `spell_requirements.json` dans le serveur Python
- [ ] Vérifier les prérequis avant de lancer un sort
- [ ] Lancer automatiquement les buffs manquants
- [ ] Attendre 2 secondes entre chaque buff
- [ ] Lancer le sort final

## 🎯 Étape 4: Bouton "All" pour Accession (À VENIR)

### À faire
- [ ] Ajouter option "All" dans le menu party
- [ ] Détecter les sorts qui nécessitent Accession
- [ ] Lancer Accession automatiquement si nécessaire
- [ ] Appliquer le buff à toute la party

## 📋 Sorts configurés

### Light Arts → Addendum: White
- Reraise I/II/III
- Raise II/III
- Erase
- Poisona, Paralyna, Blindna, Silena
- Stona, Viruna, Cursna

### Dark Arts → Addendum: Black
- Fire IV/V
- Blizzard IV/V
- Aero IV/V
- Stone IV/V
- Water IV/V
- Break

### Light Arts → Accession (buffs party)
- À configurer dans la prochaine étape

## 🧪 Test

1. Lance FFXI avec le SCH
2. Recharge le Lua: `//lua reload AltControl`
3. Lance un buff (ex: Haste)
4. Vérifie dans la console Python que les buffs sont reçus
5. Ouvre la Web App et vérifie l'API: `http://localhost:5000/alt-abilities/NomDuSCH`

Tu devrais voir `"active_buffs": ["Haste"]` dans le JSON!
