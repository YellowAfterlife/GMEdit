function v_ternary_ident() {
	var v = true, z = true;
	v = z ? true : false;
	v = z ? 10 : 0;
	v = z ? noone : obj_test;
	v = z ? obj_test : noone;
}