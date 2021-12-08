function v_anon_structs() {
	var a/*:{i:int, s:string}*/;
	a = 0; ///want_warn
	a = {i:1, s:""};
	a = {i:2, s:2}; ///want_warn
	a.i += 1;
	a.s += 1; ///want_warn
	
	/// @typedef {{x:number, y:number}} anon_vec2
	var v2/*:anon_vec2*/;// = {x:1, y:2};
	v2 = {x:1}; ///want_warn
	v2 = {z:1}; ///want_warn
	v2 = {x:1, y:2, z:3}; ///note: allowed
}