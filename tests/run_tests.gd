extends SceneTree
## Runner: godot --headless --path . -s res://tests/run_tests.gd
## Sale con código 1 si algún test falla (lo usa la CI).


func _initialize() -> void:
	var total := 0
	var failed: Array[String] = []
	var dir := DirAccess.open("res://tests")
	var files := Array(dir.get_files()).filter(
		func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd")
	files.sort()
	for file: String in files:
		var script: GDScript = load("res://tests/" + file)
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var tc: TestCase = script.new()
			tc.current_test = "%s::%s" % [file, name]
			tc.before_each()
			tc.call(name)
			tc.after_each()
			total += 1
			if tc.failures.is_empty():
				print("  ok   ", tc.current_test)
			else:
				for f in tc.failures:
					print("  FAIL ", f)
				failed.append_array(tc.failures)
	print("\n%d tests, %d fallos" % [total, failed.size()])
	quit(1 if not failed.is_empty() else 0)
