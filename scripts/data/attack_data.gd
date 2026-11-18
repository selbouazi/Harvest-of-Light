class_name AttackData
extends Resource
## Un ataque = telegrafía + activo + recuperación. La telegrafía nunca baja del mínimo legible.

const MIN_TELEGRAPH_S := 0.35

@export var id: StringName
@export var animation: StringName
@export var damage: int = 20
@export var damage_type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
@export var telegraph_s: float = 0.6
@export var active_s: float = 0.2
@export var recovery_s: float = 0.6
@export var weight: float = 1.0


func effective_telegraph() -> float:
	return maxf(telegraph_s, MIN_TELEGRAPH_S)
