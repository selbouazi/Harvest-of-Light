class_name BossPhase
extends Resource

## La fase empieza cuando la vida baja de este porcentaje (1.0 = desde el principio).
@export_range(0.0, 1.0) var hp_threshold: float = 1.0
@export var attacks: Array[AttackData] = []
@export var speed_mult: float = 1.0
