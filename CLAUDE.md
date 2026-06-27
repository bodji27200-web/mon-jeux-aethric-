# CLAUDE.md — Règles du projet

> Ce fichier est la mémoire de travail du projet. À lire **en premier** à chaque session.
> Il doit rester court, à jour et factuel. Toute décision d'architecture importante y est consignée.

## 1. Nature du projet

Création d'un **RPG original** sous **Godot 4.7 (GDScript)**, destiné **en priorité au Web mobile sur iPhone 13 (Safari)**.

Le jeu s'inspire de **catégories générales de systèmes** que l'on trouve dans les RPG du genre
(exploration, combat tour par tour, classes évolutives, équipement, loot, monstres, quêtes,
donjons, familiers, ville/base, progression). Il possède **son propre univers, ses propres noms,
ses propres données, son propre équilibrage et sa propre identité visuelle**.

## 2. Règles de propriété intellectuelle (NON NÉGOCIABLE)

Il est **interdit** de :

- copier un nom de personnage, classe, compétence, objet, monstre, région, faction ou bâtiment
  provenant d'un jeu existant ;
- copier un dialogue, texte, description ou élément de lore existant ;
- reproduire une carte, interface, icône, musique, sprite ou asset d'un jeu existant ;
- reprendre une liste complète de statistiques ou une formule d'équilibrage existante ;
- présenter un élément comme provenant d'un autre jeu ;
- chercher du code source, des assets extraits ou des ressources non autorisées.

Règle pratique : **renommer en gardant tout le reste identique = copie interdite.**
On reprend des *idées de catégories de systèmes*, jamais l'expression concrète (noms + descriptions
+ chiffres + visuels) d'une œuvre existante. Toute donnée concrète du jeu doit être **inventée ici**.

## 3. Contraintes techniques

- Godot **4.7 stable**, **GDScript uniquement**.
- Renderer **Compatibility** (obligatoire pour le Web mobile).
- Export **Web mono-thread** (pas de SharedArrayBuffer requis).
- Interface **mobile portrait responsive**.
- Résolution logique de référence : **720 × 1280**.
- Prise en charge des **marges sûres (safe areas)** des iPhone (notch / barre home).
- Fluidité visée : **iPhone 13 Safari**.
- Architecture **data-driven** (les contenus vivent dans des fichiers de données, pas en dur).
- **Aucune immense carte** chargée entièrement ; zones modulaires et streamées.
- Scènes et ressources **modulaires**.
- Sauvegarde **versionnée** (champ `save_version`, migration possible).
- **Tests automatisés** lorsque c'est pertinent.
- **Aucune dépendance inutile**.
- **Aucun refactor géant** sans justification écrite.

## 4. Méthode de travail (lots)

On avance par **lots autonomes, testables et validés**. Jamais deux énormes lots fourre-tout.

Cycle de chaque lot :

1. Lire tout le dépôt et ce fichier.
2. Écrire un plan précis **avant** toute modification importante.
3. Ne développer **que** le lot demandé. Ne pas anticiper plusieurs gros systèmes futurs.
4. Lancer tests + export Web après le lot.
5. Corriger les erreurs **avant** de déclarer le lot terminé.
6. Commit Git clair et isolé.
7. Rapport final honnête (voir §6).

Règle d'or : **on ne lance pas le lot suivant tant que le précédent ne marche pas réellement
sur l'iPhone 13.**

## 5. Premier objectif (boucle minimale — PAS encore commencé)

La première vraie tranche de jeu (lot 1) sera minuscule mais **complète de bout en bout** :

lancement → déplacement tactile → petite zone → rencontre d'un monstre → combat tour par tour →
victoire → loot → sauvegarde → retour dans la zone → export Web jouable sur iPhone.

> État actuel : **rails seulement** (documentation d'architecture). Aucun système de jeu codé.

## 6. Format du rapport final de chaque lot

- Ce qui a été réalisé.
- Fichiers créés et modifiés.
- Tests exécutés + résultats réels.
- Limitations restantes.
- Risques techniques.
- Procédure exacte pour tester sur iPhone.
- Hash du commit.

**Ne jamais prétendre qu'une fonctionnalité marche si elle n'a pas été testée.**

## 7. Journal des décisions

| Date | Décision | Raison |
|------|----------|--------|
| 2026-06-27 | Création des rails du projet (CLAUDE.md + docs d'architecture). Aucun code de jeu. | Poser les fondations avant tout développement. |
| 2026-06-27 | Lot 1 : boucle minimale jouable (Godot 4.7, autoloads data-driven, combat tour par tour, loot, sauvegarde versionnée). 18 tests headless OK + export Web OK. | Première tranche complète de bout en bout. |
| 2026-06-27 | Données concrètes en JSON (data/) plutôt qu'en .tres pour le lot 1. | Simplicité, chargement headless, pas de dépendance à l'éditeur. |
| 2026-06-27 | Lot 2 : CI GitHub Actions exporte le Web et déploie sur GitHub Pages à chaque push sur main. | Lien jouable persistant et à jour automatiquement. |
| 2026-06-27 | Lot 3 : combat de groupe + ordre des tours par vitesse. 22 tests OK. | Profondeur du combat. |
| 2026-06-27 | Lot 4 : effets de statut data-driven (DoT, debuffs). 26 tests OK. | Variété tactique. |
| 2026-06-27 | Lot 5 : progression (niveaux, courbe XP, déblocage de compétences). 33 tests OK. | Évolution du personnage. |
| 2026-06-27 | Pages bloqué : dépôt privé en plan gratuit. CI build/test/export OK mais déploiement Pages échoue. | Décision utilisateur requise (dépôt public ou plan payant). |
| 2026-06-27 | Dépôt rendu public par l'utilisateur → Pages déploie. Lien jouable live. | Débloque le lien jouable gratuit. |
| 2026-06-27 | Habillage & pipeline d'assets : chemins d'images data-driven (background/sprite) avec fallback, fond de zone, sprites, combat animé (dégâts flottants, flash). Correction du bug tactile (mouse_filter). 33 tests OK. | Intégrer les images originales de l'utilisateur + rendre le jeu vivant. |
| 2026-06-27 | Lot 6 : coup critique + esquive, résolution d'attaque centralisée, RNG déterministe. 38 tests OK. | Profondeur tactique et formules testables. |
| 2026-06-27 | Lot 7 : inventaire & équipement (3 emplacements, stats effectives, UI Sac, consommables en combat). 45 tests OK. | Personnalisation du personnage. |
| 2026-06-27 | Lot 8 : sauvegarde robuste (migration v1→v2, copie de secours .bak + repli, saves corrompues gérées). 49 tests OK. | Fiabilité de la progression. |
