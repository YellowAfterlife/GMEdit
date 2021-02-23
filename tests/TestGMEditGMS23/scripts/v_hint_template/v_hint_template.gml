/// @hint new HintArray<T>(size:int, value:T)
/// @hint HintArray<T>:push(...values:T)
/// @hint HintArray<T>:pop()->T
/// @hint HintArray<T>:fwd<X>(a:T, b:X)->X
/// @hint {T} HintArray<T>:defValue
/// @hint HintArray.create<T>(size:int, ?value:T)->HintArray<T>
/// @hint HintArray<T>.create2(size:int, ?value:T)->HintArray<T>

function v_hint_template() {
	var arr/*:HintArray<int>*/;
	arr = new HintArray(4, 0);
	arr = new HintArray(4, ""); ///want_warn - casting <string> to <int>
	
	arr = HintArray.create(4, 1);
	arr = HintArray.create(4, ""); ///want_warn
	
	arr = HintArray.create2(4, 1);
	arr = HintArray.create2(4, ""); ///want_warn
	
	var i/*:int*/, s/*:string*/;
	arr.push(0);
	arr.push(""); ///want_warn
	i = arr.pop();
	s = arr.pop(); ///want_warn
	i = arr.fwd(1, 0);
	i = arr.fwd(1, ""); ///want_warn
	i = arr.defValue;
	s = arr.defValue; ///want_warn
}