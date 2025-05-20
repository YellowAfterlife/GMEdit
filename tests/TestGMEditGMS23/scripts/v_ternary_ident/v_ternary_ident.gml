function v_ternary_ident() {
	let z = true;
	var v;
	v = z ? true : false;
	v = z ? 10 : 0;
	v = z ? noone : obj_test;
	v = z ? obj_test : noone;
	
	//
	let a = "", b = "", c = "";
	c = !z ? a : b;
}