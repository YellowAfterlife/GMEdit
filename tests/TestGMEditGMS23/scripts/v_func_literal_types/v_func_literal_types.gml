function v_func_literal_types() {
	let arr = [1, 2, 3];
	array_sort(arr, function(a, b) { return a - b; });
	array_sort(arr, function(a, b) { }); // should warn
	array_sort(arr, function(a/*:int*/, b/*:int*/) { return a - b; });
	array_sort(arr, function(a/*:int*/, b/*:int*/)/*->int*/ { return a - b; });
	array_sort(arr, function(a/*:int*/, b/*:int*/) { }); // should warn
	array_sort(arr, function(a/*:int*/, b/*:int*/)/*->int*/ { }); // should warn
	array_sort(arr, function(a, b)/*->string*/ { return ":)" }); // should warn
	array_sort(arr, function(a/*:string*/, b/*:string*/)/*->int*/ { return a - b }); // should warn
	array_sort(arr, function(a/*:string*/, b/*:string*/)/*->int*/ { return 0 }); // should warn
}