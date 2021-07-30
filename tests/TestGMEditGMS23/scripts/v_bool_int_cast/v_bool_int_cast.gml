function v_bool_int_cast() {
	var i/*:int*/, z/*:bool*/;
	i = z; ///want_warn
	z = i; ///want_warn
	z = i > 0;
	i = z ? 1 : 0;
	z = bool(i);
	z = i /*#as bool*/;
	i = z /*#as int*/;
}