function namespace_Class() constructor {};

// note: the following should not be shortened since it is before the #import:
/// @hint new namespace_Class()
// furthermore, `#import namespace.*`` will not work for classes that have no definitions yet
//!#import namespace.*
/// @hint namespace_Class:hello()->void
/// @hint namespace_Class:copy()->namespace_Class
if (false) {
	var something/*:namespace_Class*/ = new namespace_Class();
	something.hello();
}

function v_imp_namespace_class(_arg/*:namespace_Class*/)/*->namespace_Class*/ {
	let _c = new namespace_Class();
	return _arg;
	return _c;
	return 0; ///want_warn
}
function v_imp_namespace_class_1(_arg/*:int*/)/*->int*/ {
	let _c = new namespace_Class();
	return _arg;
	return _c; ///want_warn
	return 0;
}
/// @param {namespace_Class} _arg
/// @returns {namespace_Class}
function v_imp_namespace_class_2(_arg) {
	let _c = new namespace_Class();
	return _arg;
	return _c;
	return 0; ///want_warn
}
