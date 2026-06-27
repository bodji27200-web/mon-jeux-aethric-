# Passation — état du projet & reprise

> À lire avec `CLAUDE.md` (règles) et `docs/ROADMAP.md` (lots). Ce fichier dit **où on en est**
> et **comment reprendre** sans rien casser.

## 1. Résumé en une phrase
RPG original **Velmoria** sous **Godot 4.7 (GDScript)**, ciblé **Web mobile iPhone 13 Safari**,
data-driven, déployé automatiquement sur GitHub Pages. **Phase A (lots 1→8) terminée, 49 tests OK.**

## 2. Où ça vit
- Dépôt : `bodji27200-web/mon-jeux-aethric-` (public).
- Branche de dev : `claude/godot-rpg-mobile-web-6q5hnl`. On pousse **aussi sur `main`** (déclenche le déploiement).
- Lien jouable : **https://bodji27200-web.github.io/mon-jeux-aethric-/** (mis à jour à chaque push sur `main`).

## 3. Ce qui est fait (Phase A)
1. Boucle minimale (zone tactile → rencontre → combat → loot → sauvegarde).
2. CI GitHub Actions : build + tests + export Web + déploiement Pages.
3. Combat de groupe + ordre des tours par vitesse (initiative par manche).
4. Effets de statut data-driven (DoT, debuffs atk/def), résolus en début de tour.
5. Classes & progression : courbe d'XP, montée de niveau, déblocage de compétences.
6. Coup critique & esquive, `resolve_attack()` centralisé, RNG déterministe.
7. Inventaire & équipement (arme/armure/bijou), stats effectives, UI Sac, consommables en combat.
8. Sauvegarde robuste : migration versionnée (v1→v2), copie de secours `.bak` + repli, saves corrompues gérées.

## 4. Architecture (rappel)
- **Autoloads** : `DataRegistry` (charge `data/*.json`), `GameState` (état partie + équipement + progression),
  `SaveManager` (save versionnée + secours), `SceneRouter` (transitions).
- **Logique pure** (testable headless) : `scripts/combat/CombatEngine.gd`, `scripts/core/RNG.gd`,
  `scripts/core/Assets.gd` (chargement d'images tolérant).
- **Scènes** (UI construite en code) : `scenes/boot`, `scenes/world`, `scenes/combat`.
- **Données** : `data/{classes,skills,monsters,items,loot_tables,zones}/*.json`.
- **Images** : `assets/{zones,sprites}/` reliées via les champs `background` / `sprite` des données
  (fallback si absent). Voir `assets/README.md`.

## 5. Comment développer / tester (headless)
Godot 4.7 requis (binaire + templates d'export Web installés). Commandes depuis la racine :
```bash
godot --headless --path . --import                       # importer les ressources
godot --headless --path . res://tests/TestRunner.tscn    # lancer les 49 tests (exit 0 si OK)
godot --headless --path . --export-release "Web" build/web/index.html   # export Web
```
Règle projet : **ne pas déclarer un lot fini sans tests verts + export OK**, puis commit + push
(`main` ET la branche de dev), et mettre à jour `ROADMAP.md` + le journal de `CLAUDE.md`.

## 6. Pièges connus (déjà rencontrés)
- Ne pas nommer une méthode `get_class()` (collision avec `Object`). → `get_class_def()`.
- Éviter `var x := ...` qui infère un `Variant` (ex. `.get()`, `min(float,float)`). Typer explicitement
  ou utiliser `minf/maxf`. Sinon erreur de parse (avertissements parfois traités en erreurs).
- Comparer `int == String` lève une erreur d'exécution en GDScript 4 (cf. file d'initiative : sentinelle `-1`).
- UI tactile : les Control décoratifs doivent être en `MOUSE_FILTER_IGNORE`, sinon ils mangent le tap
  (c'était la cause du « le héros ne bouge pas »).

## 7. Suite (Phase B — contenu & monde)
Prochain = **Lot 9 : système de zones** (relier la Clairière à une 2ᵉ zone, transitions, retour).
Puis lots 10→18 : tables de rencontre avancées, bestiaire, boss, donjons, loot avancé, boutique,
ville/base, quêtes, dialogues. Détails dans `docs/ROADMAP.md`.

## 8. Images (à intégrer plus tard, à la demande de l'utilisateur)
L'utilisateur fournira ses **images originales** (zones, héros, ennemis, boss) générées de son côté.
Workflow : déposer dans `assets/`, relier via le champ data correspondant, push. Le pipeline est prêt.
**Ne jamais importer d'assets d'un autre jeu** ; uniquement du contenu original (cf. `CLAUDE.md` §2).
