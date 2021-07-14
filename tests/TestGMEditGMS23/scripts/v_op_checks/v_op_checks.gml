function v_op_checks() {
	var i/*:int*/, s/*:string*/, z/*:bool*/, d;
	
	i += 1;
	i += ""; ///want_warn - rhs
	i -= 1;
	s += "";
	s += 1; ///want_warn - rhs
	s -= ""; ///want_warn
	z = i && 0;
	z = i && s; ///want_warn
	z = i && (s == "");
	
	i = -i;
	i = ~i;
	i = !i;
	s = -s; ///want_warn
	s = ~s; ///want_warn
	s = !s; ///want_warn
	
	i = 1 + 2;
	i = "a" + "b"; ///want_warn - result
	s = "a" + "b";
	s = 1 + 2; ///want_warn - result
	
	d = 1 + "b"; ///want_warn - mismatch
	d = "a" + 2; ///want_warn - mismatch
	d = "a" - "b"; ///want_warn
	d = 1 << 2;
	d = 1 == "a"; // allowed
	d = 1 < "a"; ///want_warn
	
	d = choose(1, 2, 3) + "b"; ///want_warn
	s = string(choose(1, 2, 3)) + "b";
	
	let zi = z ? i : undefined;
	i = zi; ///want_warn - zi is null<int>
	let zi2 = z ? undefined : i;
	i = zi2; ///want_warn - zi2 is null<int>
}