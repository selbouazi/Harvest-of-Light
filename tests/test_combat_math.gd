extends TestCase


func test_resistencias_nunca_bajan_de_0_5_ni_superan_1_5() -> void:
	assert_eq(CombatMath.clamp_resistance(0.0), 0.5)
	assert_eq(CombatMath.clamp_resistance(3.0), 1.5)
	assert_eq(CombatMath.clamp_resistance(1.2), 1.2)


func test_defensa_con_retornos_decrecientes_y_tope() -> void:
	assert_eq(CombatMath.defense_reduction(0.0, 50.0, 0.6), 0.0)
	assert_almost_eq(CombatMath.defense_reduction(50.0, 50.0, 0.6), 0.5)
	assert_almost_eq(CombatMath.defense_reduction(10000.0, 50.0, 0.6), 0.6)
	var a := CombatMath.defense_reduction(25.0, 50.0, 0.9)
	var b := CombatMath.defense_reduction(50.0, 50.0, 0.9)
	var c := CombatMath.defense_reduction(75.0, 50.0, 0.9)
	assert_true(b - a > c - b, "cada punto de defensa debe valer menos que el anterior")


func test_dano_minimo_es_1() -> void:
	assert_eq(CombatMath.final_damage(0.1, 0.5, 1000.0, 50.0, 0.6), 1)


func test_golpes_aguantados() -> void:
	assert_eq(CombatMath.hits_to_die(100, 15), 7)
	assert_eq(CombatMath.hits_to_die(100, 20), 5)
	assert_true(CombatMath.within_contract(100, 15))
	assert_false(CombatMath.within_contract(100, 30))


func test_xp_decae_con_repeticion_hasta_un_suelo() -> void:
	assert_eq(CombatMath.xp_with_decay(100, 0), 100)
	assert_eq(CombatMath.xp_with_decay(100, 1), 50)
	assert_eq(CombatMath.xp_with_decay(100, 20), 10)
