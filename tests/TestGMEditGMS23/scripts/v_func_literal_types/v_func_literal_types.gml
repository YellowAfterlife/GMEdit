function v_func_literal_types() {
	let arr = [1, 2, 3];
	array_sort(arr, function(a, b) { return a - b; });
	array_sort(arr, function(a, b) { }); ///want_warn
	array_sort(arr, function(a/*:int*/, b/*:int*/) { return a - b; });
	array_sort(arr, function(a/*:int*/, b/*:int*/)/*->int*/ { return a - b; });
	array_sort(arr, function(a/*:int*/, b/*:int*/) { }); ///want_warn
	array_sort(arr, function(a/*:int*/, b/*:int*/)/*->int*/ { }); ///want_warn
	array_sort(arr, function(a, b)/*->string*/ { return ":)" }); ///want_warn
	array_sort(arr, function(a/*:string*/, b/*:string*/)/*->int*/ { return a - b }); ///want_warn
	array_sort(arr, function(a/*:string*/, b/*:string*/)/*->int*/ { return 0 }); ///want_warn
}