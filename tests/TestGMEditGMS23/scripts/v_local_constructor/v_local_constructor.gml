function v_local_constructor_0(i/*:int*/) {
	
}
function v_local_constructor_1(i/*:int*/) constructor {
	
}
function v_local_constructor_2(ctr/*:constructor<int, any>*/) {
	return new ctr(1);
	return new ctr(""); ///want_warn
}
function v_local_constructor() {
	var q;
	let fun = function(b/*:int*/) {
		return b + 1;
	}
	q = fun(1);
	q = fun(""); ///want_warn
	q = new fun(1); ///want_warn
	//
	let ctr = function(a/*:int*/) constructor {
		index = a + 1;
	}
	q = ctr(1); ///want_warn
	q = new ctr(1);
	q = new ctr(""); ///want_warn
	//
	let ctr_1 = v_local_constructor_1;
	c = ctr_1(1); ///want_warn
	c = new ctr_1(1);
	
	//
	v_local_constructor_2(v_local_constructor_1);
	v_local_constructor_2(v_local_constructor_0); ///want_warn
}