function v_method() {
	let a = function(_a/*:int*/) {}
	let b = function(_b/*:string*/) {}
	a = method({}, a);
	a = method({}, b); ///want_warn
	b = method({}, a); ///want_warn
	b = method({}, b);
	let c = method({}, v_method);
	let d = method({}, 0); ///want_warn
}