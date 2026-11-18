class_name TestCase
extends RefCounted
## Base mínima de tests (API parecida a GUT para poder migrar: assert_eq, assert_true...).
## Cada método que empieza por `test_` es un test.

var failures: Array[String] = []
var current_test := ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func assert_true(cond: bool, msg := "") -> void:
	if not cond:
		_fail("se esperaba true. " + msg)


func assert_false(cond: bool, msg := "") -> void:
	if cond:
		_fail("se esperaba false. " + msg)


func assert_eq(got: Variant, expected: Variant, msg := "") -> void:
	if got != expected:
		_fail("esperado <%s>, obtenido <%s>. %s" % [expected, got, msg])


func assert_almost_eq(got: float, expected: float, eps := 0.0001, msg := "") -> void:
	if absf(got - expected) > eps:
		_fail("esperado ≈%s, obtenido %s. %s" % [expected, got, msg])


func assert_between(got: float, lo: float, hi: float, msg := "") -> void:
	if got < lo or got > hi:
		_fail("%s fuera de [%s, %s]. %s" % [got, lo, hi, msg])


func _fail(msg: String) -> void:
	failures.append("%s: %s" % [current_test, msg])
