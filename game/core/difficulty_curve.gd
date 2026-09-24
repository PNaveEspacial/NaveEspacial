class_name DifficultyCurve
extends RefCounted
## Pure function of wave number to difficulty outputs (design D9). Every
## output is non-decreasing as the wave number increases, and every output
## that has a configured cap never exceeds it.

var _params: DifficultyParams


func _init(params: DifficultyParams) -> void:
	_params = params


## Spawn budget available to [code]WaveComposer[/code] for this wave.
func budget(wave: int) -> float:
	return _params.budget_base + _params.budget_growth * pow(wave - 1, _params.budget_exponent)


## Maximum concurrent enemies allowed, capped at [member DifficultyParams.max_alive_cap].
func max_alive(wave: int) -> int:
	var value := _params.max_alive_base + _params.max_alive_per_wave * (wave - 1)
	return mini(value, _params.max_alive_cap)


## HP multiplier applied to spawned enemies this wave.
func hp_multiplier(wave: int) -> float:
	return 1.0 + _params.hp_growth * (wave - 1)


## Move-speed multiplier applied to spawned enemies, capped at
## [member DifficultyParams.speed_cap].
func speed_multiplier(wave: int) -> float:
	var value := 1.0 + _params.speed_growth * (wave - 1)
	return minf(value, _params.speed_cap)


## Wave duration in seconds, capped at [member DifficultyParams.duration_cap].
func wave_duration_s(wave: int) -> float:
	var value := _params.duration_base + _params.duration_per_wave * (wave - 1)
	return minf(value, _params.duration_cap)


## Relative spawn weight for [param enemy] at [param wave]. Returns 0 before
## [member EnemyData.unlock_wave] is reached.
func type_weight(enemy: EnemyData, wave: int) -> float:
	if wave < enemy.unlock_wave:
		return 0.0
	return enemy.spawn_weight
