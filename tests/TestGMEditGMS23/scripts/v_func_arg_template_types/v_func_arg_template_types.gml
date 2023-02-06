/// @template T1
/// @param {T1} v1
/// @param {function<T1;bool>} fn
function v_func_arg_template_types_1(v1, fn) {}
function v_func_arg_template_types() {
	// funny little things, these template parameters
	
	v_func_arg_template_types_1(1, function(i/*:int*/) /*=>*/ {return true});
	
	// you expect this to warn:
	v_func_arg_template_types_1(1, function(s/*:string*/) /*=>*/ {return true}); ///want_warn
	
	// and probably this too
	v_func_arg_template_types_1(1, function(i/*:int*/) /*=>*/ {}); ///want_warn
	
	// but we also want to apply the template parameters to function arguments
	// *inside* the function if they have no types specified.
	// pretty weird code, probably some edge cases that I can't think of right now.
	v_func_arg_template_types_1(1, function(i) /*=>*/ {
		// `i` is number now
		i += "uh oh"; ///want_warn
		return true;
	});
}