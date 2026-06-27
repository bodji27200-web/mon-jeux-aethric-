# Roadmap — développement par lots

> Règle absolue : **un lot à la fois**, validé sur iPhone 13 Safari avant le suivant.
> Cette roadmap décrit des *catégories de systèmes originaux*. Tous les noms/données concrets
> seront inventés dans le projet, jamais copiés d'une œuvre existante.

## Lot 0 — Rails (EN COURS / ce commit)
- [x] `CLAUDE.md` (règles, méthode, contraintes).
- [x] `docs/ARCHITECTURE.md`.
- [x] `docs/ROADMAP.md`.
- [x] `docs/DATA_SCHEMAS.md` (schémas data-driven).
- [ ] Aucun système de jeu codé. (Volontaire.)

## Lot 1 — Boucle minimale jouable (PROCHAIN)
Objectif : une tranche complète de bout en bout.
- Projet Godot 4.7 configuré (Compatibility, viewport 720×1280, autoloads de base).
- Écran de lancement → une petite zone d'exploration.
- Déplacement **tactile** (joystick virtuel ou tap-to-move).
- Une rencontre déclenchée par un monstre.
- Combat **tour par tour** minimal (1 héros vs 1 monstre, attaque + une compétence).
- Victoire → **loot** simple (1 objet via table de butin).
- **Sauvegarde** versionnée + rechargement.
- **Export Web** testé sur iPhone 13.

## Lot 2 — Profondeur du combat
- Plusieurs compétences/sorts data-driven, coûts (mana/énergie), effets de statut.
- Ordre de tour basé sur une stat (vitesse), file d'actions.
- Plusieurs ennemis.

## Lot 3 — Classes & progression
- Système de **classes évolutives** (montée de niveau, déblocage de compétences).
- Stats dérivées de données par classe.

## Lot 4 — Équipement & inventaire
- Objets équipables modifiant les stats ; UI d'inventaire mobile.

## Lot 5 — Zones & donjons
- Plusieurs zones, transitions, un donjon simple avec progression.

## Lots ultérieurs (à préciser, non engagés)
- Familiers/compagnons, ville/base, quêtes, économie. Décidés un par un, jamais anticipés en code.

## Hors périmètre pour l'instant
Multijoueur, raids, serveur, monde ouvert. À rediscuter explicitement plus tard.
