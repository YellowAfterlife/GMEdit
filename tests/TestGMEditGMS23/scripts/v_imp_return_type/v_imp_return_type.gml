function get_1()/*->int*/ {
	return 1;
}
function get_a1()/*->array<int>*/ {
	return [2];
	return 2; ///want_warn
}
function ImpReturnCtr() constructor {
	static toString = function() /*=>*/ {
		return "ImpReturnCtr!";
	}
	static test = function()/*->int*/ {
		return undefined; ///want_warn
	}
}
if (false) {
	let q = new ImpReturnCtr();
	var s/*:string*/, i/*:int*/;
	
	s = q.toString();
	// can't auto-detect return types for now
	
	s = q.test(); ///ww
	i = q.test();
}

function v_imp_return_type() {
	var v/*:string*/ = get_1(); ///want_warn
}