assert(coro_goto(), "abd", "coro_goto");
function coro_goto() {
	var l_label = 0;
	while (true) switch (l_label) {
	case 0/* [L2,c22] begin */:
		var s = "a";
	case 1/* [L4,c2] A */:
		s += "b";
		l_label = 2/* B */; continue;
		s += "c";
	case 2/* [L8,c2] B */:
		s += "d";
		return s;
	default/* [L12,c39] end */: exit;
	}
}

// @gmcr {"mode":"constructor","yieldScripts":[]}

/*//!#gmcr
#gmcr
function coro_goto() {
	var s = "a";
	label A:
	s += "b";
	goto B;
	s += "c";
	label B:
	s += "d";
	return s;
}
assert(coro_goto(), "abd", "coro_goto")
//!#gmcr*/
