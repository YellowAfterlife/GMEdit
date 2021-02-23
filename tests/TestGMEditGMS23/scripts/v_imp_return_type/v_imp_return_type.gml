function get_1()/*->int*/ {
	return 1;
}
function get_a1()/*->array<int>*/ {
	return [2];
	return 2; ///want_warn
}
function ImpReturnCtr() constructor {
	static test = function()/*->int*/ {
		return undefined; ///want_warn
	}
}
function v_imp_return_type() {
	var v/*:string*/ = get_1(); ///want_warn
}