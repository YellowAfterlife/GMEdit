/// @template K,V
function TMap() constructor {
	obj = {}; /// @is {struct}
	/// @param {K} key
	/// @param {V} val
	static set = function(key, val) {
		
	}
	
	/// @template T
	/// @param {T} val
	/// @returns {T}
	static ret = function(val) {
		return val;
	}
}

/// @template T
function TList(size/*:int*/, val/*:T*/) constructor {
	
}

function tlt_templates() {
	var m/*:TMap<int, string>*/ = new TMap();
	m.set(1, 2); // want "can't cast string to number for arg1"
	var i/*:int*/ = m.ret(""); // want "can't cast string to int"
	
	var l/*:TList<int>*/ = new TList(4, ""); // want "Can't cast TList<string> to TList<int>"
}