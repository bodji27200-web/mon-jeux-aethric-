# assets/ — images du jeu

Dépose ici tes images **originales** (générées par toi). Le moteur les charge automatiquement
via le champ correspondant dans les fichiers de `data/`. Si une image manque, le jeu affiche un
placeholder (il ne plante pas).

## Où va quoi
- `assets/zones/`    → fonds de zone (paysages). Format conseillé : **PNG**, paysage ou portrait,
  ~1500 px de large minimum. Affiché en plein écran (recadré pour remplir le portrait).
- `assets/sprites/`  → personnages, ennemis, boss. **PNG avec fond transparent**, ~256–512 px.

## Comment relier une image à un contenu
Dans le fichier data correspondant, mets le chemin `res://assets/...` :

- Zone (`data/zones/xxx.json`)      → `"background": "res://assets/zones/ma_zone.png"`
- Classe (`data/classes/xxx.json`)  → `"sprite": "res://assets/sprites/mon_heros.png"`
- Monstre (`data/monsters/xxx.json`)→ `"sprite": "res://assets/sprites/mon_ennemi.png"`

## Workflow simple
1. Tu génères une image (ChatGPT, etc.) — **contenu 100% original**.
2. Tu me l'envoies dans le chat (ou tu l'ajoutes dans le bon dossier).
3. Je la place dans `assets/`, je relie le bon champ data, je push.
4. Le lien jouable se met à jour tout seul. ✅

> Règle : uniquement des images **originales**. On n'importe jamais d'assets extraits d'un autre jeu.
