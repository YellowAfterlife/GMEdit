function v_constructor_method_arrow_types_1() constructor {
	str = "hi!"; /// @is {string}
	static func = function(i/*:int*/)/*->int*/ {
		return "oh"; // want warn
	}
}
function v_constructor_method_arrow_types() {
	let v = new v_constructor_method_arrow_types_1();
	v.str = 0; // want warn
	var s/*:string*/ = v.func(0); // want warn
}