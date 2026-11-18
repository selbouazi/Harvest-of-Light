class_name CombatMath
## Fórmulas puras, sin estado: fáciles de testear (tests/test_combat_math.gd).
## Los números concretos viven en StatsConfig (data/stats/*.tres), no aquí.


static func clamp_resistance(mult: float) -> float:
	return clampf(mult, DamageTypes.RESIST_MIN, DamageTypes.RESIST_MAX)


## Reducción de daño con retornos decrecientes: D / (D + K), con tope.
static func defense_reduction(defense: float, k: float, cap: float) -> float:
	if defense <= 0.0:
		return 0.0
	return minf(defense / (defense + k), cap)


static func final_damage(base: float, resist_mult: float, defense: float, k: float, cap: float) -> int:
	var d := base * clamp_resistance(resist_mult) * (1.0 - defense_reduction(defense, k, cap))
	return maxi(1, roundi(d))


## Métrica de diseño (K3): golpes que aguanta el jugador. Sustituye a "poder = suma de stats".
static func hits_to_die(max_hp: int, hit_damage: int) -> int:
	if hit_damage <= 0:
		return 0x7FFFFFFF
	return ceili(float(max_hp) / float(hit_damage))


## ¿Está el encuentro dentro del contrato? A nivel esperado: 6–8 golpes.
static func within_contract(max_hp: int, hit_damage: int, lo: int = 6, hi: int = 8) -> bool:
	var h := hits_to_die(max_hp, hit_damage)
	return h >= lo and h <= hi


## La XP decae con la repetición (anti-grinding, se conserva del GDD).
static func xp_with_decay(base_xp: int, times_killed: int, decay: float = 0.5, floor_ratio: float = 0.1) -> int:
	var ratio := maxf(pow(decay, times_killed), floor_ratio)
	return maxi(0, roundi(base_xp * ratio))
