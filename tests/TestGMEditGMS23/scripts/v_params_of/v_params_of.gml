/// @template {function} T
/// @param {T} func 
/// @param {params_of_nl<T>} ...args 
function v_params_of_test() {
	
}
function v_params_of() {
	let fii = function(i/*:int*/)/*->int*/ {
		return 1;
	};
	v_params_of_test(fii, 1);
	v_params_of_test(fii, ""); ///want_warn
	//
	let fisi = function(i/*:int*/, s/*:string*/)/*->int*/ {
		return 2;
	};
	v_params_of_test(fisi, 1, "e");
	v_params_of_test(fisi, ""); ///want_warn
	v_params_of_test(fisi, 1, 1); ///want_warn
	//
	v_params_of_test(function() /*=>*/ {});
	v_params_of_test(function() /*=>*/ {}, 0); ///want_warn
	v_params_of_test(function() /*=>*/ {return 1});
	v_params_of_test(function() /*=>*/ {return 1}, 0); ///want_warn
}