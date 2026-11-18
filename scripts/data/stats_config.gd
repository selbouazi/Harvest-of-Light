class_name StatsConfig
extends Resource
## Tabla de progresión (decisiones #7 y #8). Tunear editando data/stats/default_stats.tres.
## Slice: incrementos fijos por nivel. El reparto libre se reintroduce solo si el slice lo pide.

@export_group("Nivel")
@export var max_level: int = 15
@export var xp_base: int = 60
@export var xp_growth: float = 1.35

@export_group("Vida")
@export var base_hp: int = 100
@export var hp_per_level: int = 8

@export_group("Fuerza")
@export var base_damage: float = 12.0
@export var damage_per_level: float = 1.2

@export_group("Defensa (viene del equipo)")
@export var defense_k: float = 50.0
@export var defense_cap: float = 0.6

@export_group("Luz y curación")
## Reserva fija, no ligada a Magia (I1).
@export var light_max: float = 99.0
@export var light_per_hit: float = 11.0
## Tope anti-sustain: luz máxima que se puede ganar por segundo.
@export var light_gain_cap_per_s: float = 22.0
@export var heal_cost: float = 33.0
@export var heal_ratio: float = 0.33
@export var heal_channel_s: float = 0.9


func xp_to_next(level: int) -> int:
	return roundi(xp_base * pow(xp_growth, level - 1))


func max_hp_at(level: int) -> int:
	return base_hp + hp_per_level * (clampi(level, 1, max_level) - 1)


func damage_at(level: int) -> float:
	return base_damage + damage_per_level * (clampi(level, 1, max_level) - 1)


func heal_amount(max_hp: int) -> int:
	return roundi(max_hp * heal_ratio)
