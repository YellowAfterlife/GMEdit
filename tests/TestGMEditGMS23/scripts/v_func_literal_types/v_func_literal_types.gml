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
	
	let fii = function(a/*:int*/, b/*:int*/) {}
	fii(1, 2);
	fii("a", "b"); ///want_warn
	
	let firs/*:function<int, rest<string>, void>*/ = /*#cast*/ function() {}
	firs(); ///want_warn
	firs("no"); ///want_warn
	firs(1, "a");
	firs(1, "a", "b");
	firs(1, 2); ///want_warn
	firs(1, "2", 3); ///want_warn
	
	v_string_split("");
}
function v_string_split(str/*:string*/, sep = ",") {}