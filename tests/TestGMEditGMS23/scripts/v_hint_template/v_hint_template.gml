/// @hint new HintArray<T>(size:int, value:T)
/// @hint HintArray<T>:push(...values:T)
/// @hint HintArray<T>:pop()->T
/// @hint HintArray<T>:fwd<X>(a:T, b:X)->X
/// @hint {T} HintArray<T>:defValue

function v_hint_template() {
	var v/*:HintArray<int>*/ = new HintArray(4, ""); // want warn - casting <string> to <int>
	var i/*:int*/, s/*:string*/;
	v.push(0);
	v.push(""); // want warn
	i = v.pop();
	s = v.pop(); // want warn
	i = v.fwd(1, 0);
	i = v.fwd(1, ""); // want warn
	i = v.defValue;
	s = v.defValue; // want warn
}