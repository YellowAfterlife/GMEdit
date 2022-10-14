function v_constructor_function_redefinitions() constructor {
	static f1 = function() {
		let v = 0;
		v += 1;
		v += ""; ///want_warn
		array_push(v, 1); ///want_warn
	}
	static f2 = function() {
		let v = "hi!";
		v += 1; ///want_warn
		v += "";
		array_push(v, 1); ///want_warn
	}
	static f3 = function() {
		let v = [];
		v += 1; ///want_warn
		v += ""; ///want_warn
		array_push(v, 1);
	}
}