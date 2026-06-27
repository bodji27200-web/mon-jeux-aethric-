# Roadmap — développement par lots (1 → 40)

> Règle absolue : **un lot à la fois**, chaque lot autonome, testable, validé.
> Cette roadmap décrit des **catégories de systèmes originaux**. Tous les noms, descriptions et
> chiffres concrets sont **inventés pour ce projet** — aucune copie d'une œuvre existante.
> Plateforme cible : **Web mobile, iPhone 13 Safari**, Godot 4.7, GDScript, renderer Compatibility.

Légende : ✅ fait · 🚧 en cours · ⬜ à faire

---

## Phase A — Fondations & boucle de jeu (lots 1–8)

- ✅ **Lot 1 — Boucle minimale jouable.** Projet Godot configuré (Compatibility, 720×1280, autoloads).
  Écran de lancement → petite zone → déplacement tactile → rencontre → combat 1v1 tour par tour →
  victoire → loot simple → sauvegarde versionnée → rechargement. Export Web. 18 tests OK.
- ✅ **Lot 2 — Pipeline d'export Web + lien jouable.** GitHub Actions exporte le build HTML5 et le
  publie sur GitHub Pages à chaque push sur main. Lien jouable persistant.
- ✅ **Lot 3 — Profondeur du combat.** Plusieurs ennemis (groupes 1-2), file de tours basée sur la
  vitesse (initiative par manche), sélection de cible, coût de ressource. 22 tests OK.
- ⬜ **Lot 4 — Effets de statut.** Buffs/debuffs, poison/brûlure/etc. (effets génériques data-driven),
  durée, résolution en fin de tour.
- ⬜ **Lot 5 — Classes & progression.** Classes jouables data-driven, montée de niveau, courbe d'XP,
  déblocage de compétences par palier.
- ⬜ **Lot 6 — Stats & formules.** Stats dérivées (attaque/défense/crit/esquive), formule de dégâts
  centralisée et testée, RNG déterministe pour les tests.
- ⬜ **Lot 7 — Inventaire & équipement.** Slots d'équipement, modificateurs de stats, UI inventaire
  mobile, objets consommables en combat.
- ⬜ **Lot 8 — Sauvegarde robuste & migrations.** Plusieurs slots, migration de version, gestion des
  saves corrompues, sauvegarde auto.

## Phase B — Contenu & monde (lots 9–18)

- ⬜ **Lot 9 — Système de zones.** Plusieurs zones reliées, transitions, points d'intérêt, retour ville.
- ⬜ **Lot 10 — Tables de rencontre & spawns.** Rencontres pondérées par zone, niveaux d'ennemis.
- ⬜ **Lot 11 — Bestiaire.** Catalogue de monstres data-driven, familles d'ennemis, résistances.
- ⬜ **Lot 12 — Boss.** Combats de boss avec phases et mécaniques scriptées par données.
- ⬜ **Lot 13 — Donjons.** Donjons modulaires (salles enchaînées), progression, récompense de fin.
- ⬜ **Lot 14 — Loot avancé.** Raretés, affixes/modificateurs aléatoires sur objets, tables par source.
- ⬜ **Lot 15 — Boutique & économie.** Monnaie, marchands, achat/vente, prix data-driven.
- ⬜ **Lot 16 — Ville / base du joueur.** Hub central, PNJ de services (forge, soin, stockage).
- ⬜ **Lot 17 — Quêtes.** Système de quêtes data-driven (objectifs, suivi, récompenses, journal).
- ⬜ **Lot 18 — Dialogues.** Moteur de dialogues à choix, conditions, drapeaux de progression.

## Phase C — Systèmes RPG avancés (lots 19–28)

- ⬜ **Lot 19 — Arbre de compétences / talents.** Progression de spécialisation par classe.
- ⬜ **Lot 20 — Familiers / compagnons.** Créatures persistantes recrutables, leur propre progression.
- ⬜ **Lot 21 — Combat avec familiers.** Intégration des compagnons en combat, IA d'allié simple.
- ⬜ **Lot 22 — Artisanat / forge.** Recettes, ressources, amélioration d'équipement.
- ⬜ **Lot 23 — Collecte & ressources.** Récolte dans les zones, nœuds de ressources.
- ⬜ **Lot 24 — Enchantements / gemmes.** Améliorations modulaires d'équipement.
- ⬜ **Lot 25 — Multi-classe / reclassement.** Changement/combinaison de classes, règles d'équilibrage.
- ⬜ **Lot 26 — Statut élémentaire & affinités.** Système d'éléments (faiblesses/résistances) original.
- ⬜ **Lot 27 — Compétences passives & auras.** Effets permanents data-driven.
- ⬜ **Lot 28 — Équilibrage & courbes.** Outils internes d'équilibrage, tableurs de stats générés.

## Phase D — Contenu de fin de jeu & rejouabilité (lots 29–34)

- ⬜ **Lot 29 — Donjons à étages / sans fin.** Difficulté croissante, récompenses paliers.
- ⬜ **Lot 30 — Évènements aléatoires.** Rencontres et évènements de zone procéduraux.
- ⬜ **Lot 31 — Défis quotidiens / objectifs.** Tâches répétables, récompenses.
- ⬜ **Lot 32 — Collections / succès.** Bestiaire complété, succès, récompenses de complétion.
- ⬜ **Lot 33 — Modes de difficulté.** Réglages de difficulté, new game+.
- ⬜ **Lot 34 — Génération procédurale de zones.** Zones modulaires assemblées aléatoirement.

## Phase E — Finition, UX mobile & robustesse (lots 35–40)

- ⬜ **Lot 35 — UX mobile.** Réglages tactiles, tailles de cibles, retours haptiques/visuels, options.
- ⬜ **Lot 36 — Audio.** Bus audio, musiques/SFX originaux, mixage, réglages volume.
- ⬜ **Lot 37 — Performance mobile.** Profilage iPhone 13, budgets de nodes/draw calls, optimisations.
- ⬜ **Lot 38 — Localisation.** Système i18n (FR/EN), extraction des chaînes.
- ⬜ **Lot 39 — Tutoriel & onboarding.** Première partie guidée, infobulles.
- ⬜ **Lot 40 — Polissage & build de démo.** Écrans titre/crédits, équilibrage final, build Web stable.

---

## Hors périmètre (à rediscuter explicitement, non engagé)
Multijoueur temps réel, serveur de jeu, raids en ligne, monde ouvert unique chargé d'un bloc.

## Statut courant
Lot 0 (rails) ✅ — Lot 1 🚧 en cours.
