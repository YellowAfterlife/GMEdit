function v_tuples() {
	var t/*:tuple<int, string>*/ = [1, "hi"];
	t = [2, "3"];
	t = [1, 2]; ///want_warn
	t = [1]; ///want_warn - too few items
	t = [1, "2", 3]; ///want_warn - too many items
	
	t[0] = 1;
	t[0] = "1"; ///want_warn
	
	t[@0] = 1;
	t[@0] = "1"; ///want_warn
	
	var i/*:int*/, s/*:string*/;
	i = t[0];
	s = t[0]; ///want_warn
	s = t[1];
	i = t[1]; ///want_warn
	
	var tups/*:tuple<int, string>[]*/ = [
		[1, "2"],
		[3, 4], ///want_warn
		[5], ///want_warn
	];
}