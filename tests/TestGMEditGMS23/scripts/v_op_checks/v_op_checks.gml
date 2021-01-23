function v_op_checks() {
	var i/*:int*/, s/*:string*/, z/*:bool*/, d;
	
	i += 1;
	i += ""; // want warn - rhs
	i -= 1;
	s += "";
	s += 1; // want warn - rhs
	s -= ""; // want warn
	z = i && 0;
	z = i && s; // want warn
	z = i && (s == "");
	
	i = -i;
	i = ~i;
	i = !i;
	s = -s; // want warn
	s = ~s; // want warn
	s = !s; // want warn
	
	i = 1 + 2;
	i = "a" + "b"; // want warn - result
	s = "a" + "b";
	s = 1 + 2; // want warn - result
	
	d = 1 + "b"; // want warn - mismatch
	d = "a" + 2; // want warn - mismatch
	d = "a" - "b"; // want warn
	d = 1 << 2;
	d = 1 == "a"; // allowed
	d = 1 < "a"; // want warn
	
	d = choose(1, 2, 3) + "b"; // want warn
	s = string(choose(1, 2, 3)) + "b";
}