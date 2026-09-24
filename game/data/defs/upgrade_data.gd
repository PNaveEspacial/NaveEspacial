class_name UpgradeData
extends Resource
## Data-driven upgrade offered at level-up (design D14). Applying it adds
## [member heal_amount] HP, [member score_bonus_per_level] x current level
## to the score, and every [StatModifier] in [member modifiers].

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var desc_key: StringName = &""
@export var icon: Texture2D

## Relative likelihood this upgrade is offered; see [UpgradeRoller].
@export var weight: float = 1.0

## Maximum number of times this upgrade may be picked in one run. 0 means
## uncapped (an always-eligible filler, per design D14).
@export var max_stacks: int = 5

@export var modifiers: Array[StatModifier] = []
@export var heal_amount: int = 0
@export var score_bonus_per_level: int = 0
