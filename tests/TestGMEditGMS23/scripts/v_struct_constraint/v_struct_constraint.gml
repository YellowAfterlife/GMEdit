function v_struct_constraint_1() constructor {
	//
}
function v_struct_constraint() {
	var q/*:struct*/;
	q = 0; ///want_warn
	q = ""; ///want_warn
	q = {};
	q = new v_struct_constraint_1();
}