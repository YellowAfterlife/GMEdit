/// @hint LastParamRet<T:function>:(func:T, ...params:params_of_nl<T>)->last_param_of<T>
/// @hint LastParamRet<T:function>:invoke(func:T, ...params:params_of_nl<T>)->last_param_of<T>

/// @template {CustomKeyArray} T
/// @param {T} ckarray
/// @param {last_param_of<T>} value
function v_last_param_of_test() {
	
}

function v_last_param_of() {
	// last param in return
	let test1/*:LastParamRet*/;
	let one = test1.invoke(round, 0);
	string_digits(one);	///want_warn
	round(one); ///note: OK!
	
	let test2/*:LastParamRet<function<string,int,string>>*/;
	let two = test2(string_char_at, "h", 0); ///note: OK!
	round(two); ///want_warn
	string_digits(two);	///note: OK!
	
	// last param in arg
	let ck/*:ckarray<instance,string>*/;
	v_last_param_of_test(sprite_get_nineslice(spr_blank).tilemode, 0); ///want_warn
	v_last_param_of_test(ck, 0); ///want_warn
	v_last_param_of_test(ck, "hello"); ///note: OK!
}