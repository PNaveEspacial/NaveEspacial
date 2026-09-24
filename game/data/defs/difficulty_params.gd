class_name DifficultyParams
extends Resource
## Tunable parameters driving [DifficultyCurve] (design D9). Every value
## here is a pure input; the curve itself guarantees non-decreasing,
## capped outputs as the wave number increases.

## Base spawn budget spent by [code]WaveComposer[/code] at wave 1.
@export var budget_base: float = 10.0
## Per-wave budget growth multiplier, applied via [member budget_exponent].
@export var budget_growth: float = 4.0
## Exponent controlling how quickly the budget accelerates with wave number.
@export var budget_exponent: float = 1.15

## Maximum concurrent enemies allowed at wave 1.
@export var max_alive_base: int = 8
## Additional concurrent enemies allowed per wave past 1.
@export var max_alive_per_wave: int = 2
## Hard cap on concurrent enemies, regardless of wave number.
@export var max_alive_cap: int = 48

## Fractional HP multiplier growth applied per wave past 1.
@export var hp_growth: float = 0.12

## Fractional move-speed multiplier growth applied per wave past 1.
@export var speed_growth: float = 0.02
## Hard cap on the speed multiplier, regardless of wave number.
@export var speed_cap: float = 1.6

## Wave duration, in seconds, at wave 1.
@export var duration_base: float = 20.0
## Additional wave duration, in seconds, granted per wave past 1.
@export var duration_per_wave: float = 1.5
## Hard cap on wave duration, in seconds, regardless of wave number.
@export var duration_cap: float = 60.0
