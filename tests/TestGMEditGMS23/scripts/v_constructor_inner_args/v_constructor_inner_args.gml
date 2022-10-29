function c_constructor_inner_args(_name) constructor {
	name = _name;
	static some = function() {
		var a = argument[0];
	}
}
function c_constructor_inner_args2() constructor {
	static some = function() {
		var a = argument[0];
	}
	name = argument_count > 0 ? argument[0] : ":)";
}
function v_constructor_inner_args() {
	var c = new c_constructor_inner_args(); ///want_warn
	var c2 = new c_constructor_inner_args2(); ///note: actually uses argument[]
}