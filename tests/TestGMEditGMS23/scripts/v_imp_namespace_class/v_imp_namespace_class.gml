function namespace_Class() constructor {};

/// @hint namespace_Class:hello()->void
//!#import namespace.*
var something/*:namespace_Class*/ = new namespace_Class();
something.hello();

function v_imp_namespace_class(_arg/*:namespace_Class*/)/*->namespace_Class*/ {
	let _c = new namespace_Class();
	return _arg;
	return _c;
	return 0; // want warn
}
function v_imp_namespace_class_1(_arg/*:int*/)/*->int*/ {
	let _c = new namespace_Class();
	return _arg;
	return _c; // want warn
	return 0;
}