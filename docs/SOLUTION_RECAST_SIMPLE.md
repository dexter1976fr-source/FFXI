# 🔧 Solution simple pour activer les recasts

## Problème
Le Lua n'envoie les données que quand job/pet/arme/party change.
Il ne renvoie PAS les mises à jour de recast toutes les secondes.

## Solution manuelle (5 minutes)

### Ouvrir le fichier Lua
```
a:\Jeux\PlayOnline\Windower4\addons\AltControl\AltControl.lua
```

### Trouver cette section (ligne ~178):
```lua
    -- ✅ Ne rien envoyer si rien n'a changé
    if last_state.main_job == player.main_job
       and last_state.sub_job == player.sub_job
       and last_state.pet_name == pet_info.name
       and last_state.weapon_id == weapon_id
       and not table_diff(party_info, last_state.party_members) then
        return
    end
```

### Commenter ces lignes (ajouter `--` devant):
```lua
    -- ✅ Ne rien envoyer si rien n'a changé
    --[[ DÉSACTIVÉ POUR RECASTS
    if last_state.main_job == player.main_job
       and last_state.sub_job == player.sub_job
       and last_state.pet_name == pet_info.name
       and last_state.weapon_id == weapon_id
       and not table_diff(party_info, last_state.party_members) then
        return
    end
    ]]--
```

### Sauvegarder et recharger
Dans FFXI:
```
//lua r AltControl
```

## Résultat
Le Lua enverra maintenant les données toutes les secondes (même si rien ne change), ce qui permettra de voir les recasts se mettre à jour en temps réel.

## Alternative: Modification optimisée

Si vous voulez une version plus optimisée, remplacez la section par:

```lua
    -- 🆕 Récupérer les recasts
    local recasts = get_recasts()
    local has_active_recasts = false
    for _ in pairs(recasts.abilities) do has_active_recasts = true break end
    if not has_active_recasts then
        for _ in pairs(recasts.spells) do has_active_recasts = true break end
    end

    -- ✅ Ne rien envoyer si rien n'a changé ET pas de recasts actifs
    if not has_active_recasts 
       and last_state.main_job == player.main_job
       and last_state.sub_job == player.sub_job
       and last_state.pet_name == pet_info.name
       and last_state.weapon_id == weapon_id
       and not table_diff(party_info, last_state.party_members) then
        return
    end
```

Cela n'enverra les mises à jour que si:
- Quelque chose a changé (job/pet/arme/party) OU
- Il y a des recasts actifs

---

**Après modification:**
1. Sauvegarder le fichier
2. Dans FFXI: `//lua r AltControl`
3. Vider le cache du navigateur (Ctrl+F5)
4. Tester un sort (Cure IV)
5. Vous devriez voir la barre de recast!
