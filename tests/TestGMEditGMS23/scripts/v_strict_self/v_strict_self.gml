function v_strict_self() {
	var a = 1;
	leak = 2; ///want_warn
}
/// @interface
function v_strict_self_itf() {
	var a = 1;
	ok = 2; ///note: allowed - it's an interface
}

function v_strict_self_ctr() constructor {
	ctrv = 2;
	v_strict_self_ctr_itf(); /// @implements
}

/// @interface
/// @self {v_strict_self_ctr}
function v_strict_self_ctr_itf() {
	var a = 1;
	ok = 2; ///note: allowed - from interface
	var b = ctrv;
	ctrv += 3; ///note: allowed - from constructor
}