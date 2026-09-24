class_name FireCadence
extends RefCounted
## Pure, frame-rate-independent fire-rate accumulator (design D12).
##
## Call [method tick] once per physics frame with the elapsed [param delta]
## and whether fire is currently held. The cooldown decays every call, but
## only ever fires shots while [param held] is true, and never goes
## negative while released -- so releasing and re-pressing never "banks"
## shots into a burst. The very first held call fires immediately, because
## the cooldown starts at [code]0.0[/code].

## Hard cap on shots reported per [method tick] call, matching the maximum
## multishot fan the design allows in one frame.
const MAX_SHOTS_PER_TICK := 3

var _cooldown: float = 0.0


## Advances the accumulator by [param delta] seconds at [param
## shots_per_second]. Returns how many shots fired this call (0 to
## [constant MAX_SHOTS_PER_TICK]).
func tick(delta: float, held: bool, shots_per_second: float) -> int:
	_cooldown -= delta
	var fired := 0
	if held:
		var interval := 1.0 / shots_per_second
		while _cooldown <= 0.0 and fired < MAX_SHOTS_PER_TICK:
			fired += 1
			_cooldown += interval
	else:
		_cooldown = max(_cooldown, 0.0)
	return fired
