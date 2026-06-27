class_name RNG
extends RefCounted
## Générateur aléatoire encapsulé, optionnellement déterministe (utile pour les tests).

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

func randi_range(a: int, b: int) -> int:
	return _rng.randi_range(a, b)

func randf() -> float:
	return _rng.randf()

## Tirage pondéré : entries = [{ "weight": int, ... }]. Renvoie l'index choisi, ou -1.
func weighted_pick(entries: Array) -> int:
	var total := 0
	for e in entries:
		total += int(e.get("weight", 0))
	if total <= 0:
		return -1
	var roll := _rng.randi_range(1, total)
	var acc := 0
	for i in entries.size():
		acc += int(entries[i].get("weight", 0))
		if roll <= acc:
			return i
	return entries.size() - 1
