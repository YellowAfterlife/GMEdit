/// @interface
function v_common_namespace_names() {
	sprite = -1; ///note: shouldn't show as namespace
	var spr/*:sprite*/ = -1; ///note: doesn't highlight - side effect
	sprite2 = -1; /// @is {sprite} - should highlight in {}
	
	camera = camera_create(); /// @is {camera} - should highlight in {}	
	
	weak_reference = -1; ///note: uncommon name - can highlight
}