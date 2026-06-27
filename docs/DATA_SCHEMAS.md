# Schémas de données (data-driven)

> Décrit la **forme** des contenus, pas les contenus eux-mêmes. Tous les contenus concrets
> (noms, chiffres, descriptions) sont **inventés pour ce projet** et ne copient aucune œuvre.
> Ces schémas seront implémentés en ressources Godot typées (`.tres`) au lot 1+, pas avant.

## Conventions communes
- Chaque entrée a un `id` unique (chaîne, ex. `"mob_petite_creature"`), stable dans le temps.
- Les libellés affichés (`display_name`, `description`) sont du texte original du projet.
- Les nombres sont **inventés** et ajustés par notre propre équilibrage.

## Classe jouable (`data/classes/`)
```
id: String
display_name: String
description: String
base_stats: { hp, mana, attack, defense, speed, ... }   # chiffres du projet
growth_per_level: { hp, mana, attack, ... }              # progression par niveau
starting_skills: [skill_id, ...]
skill_unlocks: [ { level: int, skill_id: String }, ... ]
```

## Compétence / sort (`data/skills/`)
```
id: String
display_name: String
description: String
resource_cost: { type: "mana"|"energy", amount: int }
target: "enemy"|"ally"|"self"|"all_enemies"|...
power: int                 # base de l'effet (chiffre du projet)
effect_type: "damage"|"heal"|"buff"|"debuff"|"summon"|...
status_effects: [ { id, duration, magnitude }, ... ]    # optionnel
```

## Monstre (`data/monsters/`)
```
id: String
display_name: String
stats: { hp, attack, defense, speed, ... }
skills: [skill_id, ...]
loot_table_id: String
xp_reward: int
```

## Objet / équipement (`data/items/`)
```
id: String
display_name: String
description: String
slot: "weapon"|"armor"|"trinket"|"consumable"|null
stat_modifiers: { attack: int, defense: int, ... }      # si équipable
on_use: { effect_type, power }                           # si consommable
stackable: bool
```

## Table de butin (`data/loot_tables/`)
```
id: String
rolls: int                 # nombre de tirages
entries: [ { item_id: String, weight: int, min: int, max: int }, ... ]
```

## Zone (`data/zones/`)
```
id: String
display_name: String
scene_path: String         # scène .tscn associée
encounter_table: [ { monster_id, weight }, ... ]
```

## Sauvegarde (`user://save.json` ou ressource)
```
save_version: int          # incrémenté à chaque changement de format ; migration obligatoire
player: { class_id, level, xp, current_hp, current_mana, stats, ... }
inventory: [ { item_id, count }, ... ]
equipment: { weapon: item_id|null, armor: item_id|null, ... }
progression: { current_zone_id, flags: {...} }
```
