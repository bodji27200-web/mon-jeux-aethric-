# Architecture — vue d'ensemble

> Document vivant. Décrit la structure cible du projet. Mis à jour à chaque lot qui change l'archi.
> État actuel : **conception sur papier**. Les dossiers `scenes/`, `scripts/`, `data/` etc. seront
> créés au fur et à mesure des lots, pas tous d'un coup.

## 1. Principes directeurs

1. **Data-driven** : un contenu (monstre, sort, objet, zone) = une *ressource de données*, pas du
   code en dur. Ajouter un monstre ne doit pas demander d'écrire de la logique.
2. **Modulaire** : chaque système est isolé derrière une interface claire ; on peut le tester seul.
3. **Mobile-first** : tout est pensé pour un écran portrait tactile 720×1280 avec safe areas.
4. **Petit et chargé à la demande** : pas de monde ouvert chargé d'un bloc ; des zones/scènes
   indépendantes instanciées au besoin.
5. **Sauvegarde versionnée** : toute structure sauvegardée porte un numéro de version migrable.

## 2. Arborescence cible

> À créer progressivement. Ne PAS tout générer en avance.

```
res://
├── project.godot
├── autoload/                 # Singletons (chargés via Project Settings > Autoload)
│   ├── GameState.gd          # état global de la partie (joueur, progression)
│   ├── SaveManager.gd        # sauvegarde / chargement versionnés
│   ├── DataRegistry.gd       # charge et indexe les ressources de données
│   ├── SceneRouter.gd        # transitions de scènes (zone <-> combat <-> menus)
│   └── AudioBus.gd           # sons/musique (plus tard)
├── data/                     # CONTENU data-driven (ressources .tres ou .json)
│   ├── classes/              # définitions de classes jouables
│   ├── skills/               # sorts / compétences
│   ├── monsters/             # monstres
│   ├── items/                # objets / équipement
│   ├── loot_tables/          # tables de butin
│   └── zones/                # définitions de zones
├── scripts/                  # logique (classes GDScript réutilisables)
│   ├── core/                 # types de base (Stats, DamageFormula, RNG…)
│   ├── combat/               # moteur de combat tour par tour
│   ├── entities/             # acteurs (joueur, monstre) à l'exécution
│   └── ui/                   # contrôleurs d'interface
├── scenes/                   # scènes Godot (.tscn)
│   ├── boot/                 # écran de lancement
│   ├── world/                # exploration de zone
│   ├── combat/               # scène de combat
│   └── ui/                   # composants d'UI mobiles réutilisables
├── ui/theme/                 # thème Godot (polices, couleurs, tailles tactiles)
├── tests/                    # tests automatisés (GUT ou scripts de test maison)
└── docs/                     # cette documentation
```

## 3. Couches et responsabilités

### Autoloads (singletons)
- **GameState** : source de vérité de la partie en cours (personnage, inventaire, progression).
  Ne contient pas de logique de rendu.
- **SaveManager** : sérialise/désérialise `GameState` vers `user://`. Gère `save_version` + migrations.
- **DataRegistry** : au démarrage, charge les ressources de `data/` et les expose par identifiant
  (ex. `DataRegistry.get_monster("id")`). Aucun contenu n'est codé en dur ailleurs.
- **SceneRouter** : gère les transitions (fondu, libération mémoire de la zone précédente).
- **AudioBus** : centralise audio (lot ultérieur).

### Données (`data/`)
Chaque type de contenu a un **schéma** documenté dans `docs/DATA_SCHEMAS.md`. Le format préféré est
la **Resource Godot personnalisée (.tres)** typée, car validée à l'édition. JSON possible pour les
contenus volumineux. Tous les chiffres sont **inventés pour ce projet**.

### Logique (`scripts/`)
Pur GDScript, indépendant des scènes autant que possible (facilite les tests).
Exemple : le **moteur de combat** prend en entrée des données (acteurs, action) et renvoie un
résultat (dégâts, effets), sans toucher l'UI directement.

### Présentation (`scenes/` + `scripts/ui/`)
Les scènes affichent l'état et émettent des intentions (signaux). Elles ne contiennent pas la règle
du jeu — elles appellent la logique.

## 4. Flux de scènes (cible du lot 1)

```
Boot → World(zone) → [rencontre] → Combat → [victoire + loot] → World(zone) → (sauvegarde)
```

Chaque transition passe par `SceneRouter`, qui libère la scène précédente pour limiter la mémoire
sur mobile.

## 5. Contraintes Web mobile (rappel technique)

- Renderer **Compatibility** ; export **mono-thread** (pas de threads/atomics requis).
- Entrées **tactiles** d'abord ; le clavier/souris reste utile au dev sur desktop.
- Gérer les **safe areas** via `DisplayServer.get_display_safe_area()` et un conteneur de marge.
- Viewport : mode `canvas_items`, aspect `expand`, résolution de référence **720×1280**.
- Budget mémoire et nombre de nodes **conservateurs** (pas de milliers de nodes par scène).

## 6. Stratégie de tests

- Logique pure (combat, formules, sauvegarde) → tests automatisés.
- UI / rendu → vérification manuelle + checklist export Web sur iPhone (voir `docs/TESTING.md` à venir).

## 7. Ce qui n'est volontairement PAS encore décidé

Pour éviter de bâtir sur des hypothèses : multijoueur, économie, raids, IA avancée, ville complète.
Ces sujets seront tranchés dans `docs/ROADMAP.md` lot par lot, pas anticipés en code.
