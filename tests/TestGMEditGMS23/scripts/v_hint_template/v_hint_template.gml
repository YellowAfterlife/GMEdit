/// @hint new HintArray<T>(size:int, value:T)
/// @hint HintArray<T>:push(...values:T)
/// @hint HintArray<T>:pop()->T
/// @hint HintArray<T>:fwd<X>(a:T, b:X)->X

function v_hint_template() {
	var v/*:HintArray<int>*/ = new HintArray(4, "");
	v.push(0);
	v.push(""); // want warn
	var i/*:int*/ = v.pop();
	var s/*:string*/ = v.pop(); // want warn
	i = v.fwd(1, ""); // want warn
}