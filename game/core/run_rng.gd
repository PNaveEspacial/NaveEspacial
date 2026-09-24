class_name RunRng
extends RefCounted
## Seeded run RNG with named, independently-derived sub-streams (design D8).
##
## A master [RandomNumberGenerator] is seeded with [param master_seed]. Each
## [enum Stream] value draws two [code]randi()[/code] values from the master
## RNG, in enum order, and combines them into a non-negative 63-bit seed for
## that stream's own [RandomNumberGenerator]. Streams are derived once, up
## front, so appending a new [enum Stream] value never perturbs existing
## streams, and a variable number of draws from one stream (for example
## rejection sampling in [constant Stream.SPAWNS]) never shifts another
## stream's derived seed.

## Append-only: adding a value here must not reorder the existing ones,
## because their derivation order determines their seeds.
enum Stream { WAVES, SPAWNS, UPGRADES, AI, DROPS }

var _seed: int
var _streams: Dictionary = {}


func _init(master_seed: int) -> void:
	_seed = master_seed
	var master := RandomNumberGenerator.new()
	master.seed = master_seed
	for stream_id in Stream.values():
		var hi := master.randi()
		var lo := master.randi()
		var rng := RandomNumberGenerator.new()
		rng.seed = _combine(hi, lo)
		_streams[stream_id] = rng


## The master seed this instance was constructed with.
func get_seed() -> int:
	return _seed


## Returns the [RandomNumberGenerator] for the given [enum Stream].
func stream(id: Stream) -> RandomNumberGenerator:
	return _streams[id]


## Combines two 32-bit draws into a non-negative 63-bit seed, per D8.
static func _combine(hi: int, lo: int) -> int:
	return (hi << 31) ^ lo
