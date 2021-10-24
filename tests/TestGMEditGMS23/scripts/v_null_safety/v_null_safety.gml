function v_null_safety() {
	var ni/*:int?*/ = undefined;
	var i/*:int*/;
	i = ni; ///want_warn
	if (ni != undefined) {
		i = ni; ///note: OK!
	} else {
		i = ni; ///want_warn - known to be undefined
	}
	if (ni == undefined) {
		i = ni; ///want_warn - known to be undefined
	} else {
		i = ni; ///note: OK!
	}
	i = ni; ///want_warn - not in a safe branch anymore
	i = ni != undefined ? ni : 0; ///note: OK!
	i = ni <> undefined ? ni : 0; ///note: OK!
	i = ni == undefined ? ni : 0; ///want_warn
	i = ni = undefined ? ni : 0; ///want_warn
}