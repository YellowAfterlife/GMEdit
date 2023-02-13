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
	
	/// @static
	static create = function()/*->TMap*/ {
		return new TMap();
	}
	///note: TMap.| should only show create()
	
	var _create/*:function<TMap>*/ = TMap.create; ///note: OK!
	var _create_v/*:function<void>*/ = TMap.create; ///want_warn
	var _amiss = TMap.amiss; ///want_warn
}

/// @template T
function TList(size/*:int*/, val/*:T*/) constructor {
	
}

function tlt_templates() {
	var m/*:TMap<int, string>*/ = new TMap();
	m.set(1, 2); ///want_warn "can't cast string to number for arg1"
	var i/*:int*/ = m.ret(""); ///want_warn "can't cast string to int"
	
	var l/*:TList<int>*/ = new TList(4, ""); ///want_warn "Can't cast TList<string> to TList<int>"
}