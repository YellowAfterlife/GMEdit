function v_func_blank_args_1(a/*:string*/, b/*:int?*/, c/*:int?*/, d/*:string*/) {}
function v_func_blank_args_2(a/*:int?*/, b/*:string*/) {}
/// @param {string} first
/// @param {int?} ...rest
function v_func_blank_args_rest() {}
function v_func_blank_args() {
	v_func_blank_args_1("", 1, 1, "");
	v_func_blank_args_1("", 1,, "");
	v_func_blank_args_1("",,, "");
	v_func_blank_args_2(1, "");
	v_func_blank_args_2(, "");
	v_func_blank_args_rest("hi");
	v_func_blank_args_rest("hi", 1);
	v_func_blank_args_rest("hi",, 1);
	v_func_blank_args_rest("hi",,1,, 2);
}