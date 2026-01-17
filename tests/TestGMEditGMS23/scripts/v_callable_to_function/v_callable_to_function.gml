// A callable type should cast to function<...> where appropriate
/// @hint Sorter:(a:string, b:string)->int
/// @hint SorterT<T>:(a:T, b:T)->int
/// @hint CallableRetT<T>:(a:T, b:int)->T
function v_callable() {
	let a1 = [1, 2, 3];
	let a2 = ["1", "2", "3"];
	
	var sorter/*:Sorter*/ = /*#cast*/ function() /*=>*/ {return 0};
	array_sort(a1, sorter); ///want_warn
	array_sort(a2, sorter); ///note: OK!
	
	var sorterT/*:SorterT<int>*/;
	array_sort(a2, sorterT); ///want_warn
	array_sort(a1, sorterT); ///note: OK!
	
	var callableRetT/*:CallableRetT<string>*/;
	let callableRet = callableRetT("1", "a"); ///want_warn
	var num/*:int*/ = callableRet; ///want_warn
	array_map(a1, callableRetT); ///want_warn
	array_map(a2, callableRetT); ///note: OK!
}
}