function v_func_arg_values_1(a) {}
function v_func_arg_values_1o(a=1) {}
function v_func_arg_values_2(a, b) {}
function v_func_arg_values_2o(a, b=1) {}
function v_func_arg_values() {
	v_func_arg_values_1(); ///want_warn
	v_func_arg_values_1o();
	v_func_arg_values_2(0); ///want_warn
	v_func_arg_values_2o(0);
}