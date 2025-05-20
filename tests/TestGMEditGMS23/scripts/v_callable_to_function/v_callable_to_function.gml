// A callable type should cast to function<...> where appropriate
/// @hint Sorter:(a:string, b:string)->int
function v_callable() {
	let a1 = [1, 2, 3];
	let a2 = ["1", "2", "3"];
	var sorter/*:Sorter*/ = /*#cast*/ function() /*=>*/ {return 0};
	array_sort(a1, sorter); ///want_warn
	array_sort(a2, sorter); ///note: OK!
}