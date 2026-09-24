class_name NodePool
extends Node
## Scene-local pool of reusable nodes (design D10). Bounded by [member
## max_size], so a long-running session cannot grow the scene tree without
## limit; the pool's lifetime equals the run, so restarting the scene frees
## everything cleanly.
##
## Pooled scenes implement the pooled-node contract: [code]activate(params:
## Dictionary)[/code] transitions a node from inactive to active (position,
## [method Node.reset_physics_interpolation], and any per-spawn state), and
## [code]deactivate()[/code] transitions it back to inactive. Both are the
## pooled scene's own responsibility, so this pool only tracks which
## instances are free and connects each instance's [signal
## despawn_requested] once, letting a pooled node request its own release.
## That release is deferred ([method Callable.call_deferred]), so a request
## made from inside a physics callback never mutates the tree mid-callback.

## The scene to instantiate. Its root must implement [code]activate(params:
## Dictionary)[/code], [code]deactivate()[/code], and emit [signal
## despawn_requested].
@export var scene: PackedScene

## Where new instances are added. Defaults to this pool node itself when
## left empty.
@export var container_path: NodePath

## Instances created immediately in [method _ready], before any [method
## acquire] call.
@export var prewarm: int = 0

## Hard cap on how many instances this pool will ever create.
@export var max_size: int = 32

var _available: Array[Node] = []
var _spawned_count: int = 0
var _container: Node


func _ready() -> void:
	_container = get_node(container_path) if not container_path.is_empty() else self
	for i in range(prewarm):
		_available.append(_create())


## Returns an inactive pooled node ready for [code]activate(params)[/code],
## or [code]null[/code] when the pool is at [member max_size] with no free
## instance. Callers are expected to skip the spawn on [code]null[/code]
## (design D10: skip the shot, cap enemy spawns, and so on).
func acquire() -> Node:
	if not _available.is_empty():
		return _available.pop_back()
	if _spawned_count < max_size:
		return _create()
	return null


## Deactivates [param node] and returns it to the free list.
func release(node: Node) -> void:
	node.deactivate()
	_available.append(node)


func _create() -> Node:
	var node: Node = scene.instantiate()
	_container.add_child(node)
	_spawned_count += 1
	node.deactivate()
	node.despawn_requested.connect(_on_despawn_requested.bind(node))
	return node


func _on_despawn_requested(node: Node) -> void:
	release.call_deferred(node)
