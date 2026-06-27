class_name Assets
extends RefCounted
## Chargement d'images tolérant : renvoie la texture si le fichier existe, sinon null.
## Permet d'intégrer les images du projet sans risque de crash quand un asset manque encore.

## Charge une texture depuis un chemin res:// (ex. "res://assets/zones/clairiere_bg.png").
## Renvoie null si le chemin est vide ou si la ressource n'existe pas (-> le code appelant
## affiche alors un placeholder).
static func texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	var res: Variant = load(path)
	if res is Texture2D:
		return res
	return null
