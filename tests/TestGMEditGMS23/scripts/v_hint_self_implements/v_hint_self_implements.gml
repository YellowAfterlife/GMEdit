function v_hint_self_implements() constructor {
	name = "me";
	v_hint_self_implements_extras(); /// @implements
}
/// @interface
/// @self {v_hint_self_implements}
function v_hint_self_implements_extras() {
	orig_name = name;
	some = 1;
	var t = missing; ///ww
	func = function() /*=>*/ {};
}