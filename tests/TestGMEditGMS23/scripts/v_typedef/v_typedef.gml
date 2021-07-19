function v_typedef() {
	/// @typedef {int} inty
	var i/*:int*/, s/*:string*/;
	var myi/*:inty*/ = 1;
	i = myi;
	s = myi; ///want_warn
	
	/// @typedef {ds_map<string, T>} string_map<T>
	var mymap/*:string_map<int>*/ = ds_map_create();
	var s_map/*:ds_map<string, int>*/ = mymap;
	var i_map/*:ds_map<int, int>*/ = mymap; ///want_warn
	mymap[?"hi"] = 1;
	mymap[?"hi"] = "2"; ///want_warn
	mymap[?0] = 1; ///want_warn
	
	/// @typedef {tuple<x:int, y:int>} tvec2
	var tv2/*:tvec2*/ = [1, 2];
	tv2 = ["1", "2"]; ///want_warn
	
	/// @typedef {function<left:T, right:T, int>} fcomparator
	var f/*:fcomparator<int>*/ = function(a, b) { return a - b }
	// typing f() should show argument "names" inside.
}