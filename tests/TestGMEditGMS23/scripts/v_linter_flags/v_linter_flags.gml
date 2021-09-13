function v_linter_flags() {
	var v/*:int*/;
	v = 1;
	v = ""; ///want_warn
	/// @lint all false
	v = ""; ///note: OK!
	/// @lint all default
	v = ""; ///want_warn
}