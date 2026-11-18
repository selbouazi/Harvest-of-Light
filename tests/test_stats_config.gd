extends TestCase

var cfg: StatsConfig


func before_each() -> void:
	cfg = load("res://data/stats/default_stats.tres")


func test_vida_y_dano_crecen_y_se_limitan_al_nivel_maximo() -> void:
	assert_true(cfg.max_hp_at(2) > cfg.max_hp_at(1))
	assert_eq(cfg.max_hp_at(cfg.max_level + 10), cfg.max_hp_at(cfg.max_level))
	assert_true(cfg.damage_at(5) > cfg.damage_at(1))


func test_un_nivel_no_cambia_el_dano_mas_de_un_15_por_ciento() -> void:
	for lv in range(1, cfg.max_level):
		var ratio := cfg.damage_at(lv + 1) / cfg.damage_at(lv)
		assert_true(ratio <= 1.15, "nivel %d → %d: +%d%%" % [lv, lv + 1, roundi((ratio - 1.0) * 100.0)])


func test_curva_xp_monotona() -> void:
	for lv in range(1, cfg.max_level):
		assert_true(cfg.xp_to_next(lv + 1) > cfg.xp_to_next(lv))


func test_curacion_cuesta_un_tercio_de_la_reserva() -> void:
	assert_eq(cfg.heal_amount(100), 33)
	assert_true(cfg.light_max / cfg.heal_cost >= 3.0, "debe caber al menos 3 curaciones")


func test_stats_maximas_no_mueven_golpes_aguantados_mas_del_40_por_ciento() -> void:
	# Contrato K3: un golpe calibrado a 7 golpes a nivel 1 no debe pasar de ~10 a nivel máximo esperado de la región.
	var hit := 15
	var base := CombatMath.hits_to_die(cfg.max_hp_at(1), hit)
	var region_end := CombatMath.hits_to_die(cfg.max_hp_at(5), hit)
	assert_true(float(region_end) / float(base) <= 1.4)
