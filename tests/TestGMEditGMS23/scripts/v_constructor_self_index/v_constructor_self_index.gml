function v_constructor_self_index(myVar) constructor {
	var v;
	flatVar = 0;
	self.myVar = 1;
	other.otherVar = 2;
	v = flatVar;
	v = self.myVar;
	v = otherVar; ///want_warn assigned to `other`, not us
	v = self.otherVar; ///want_warn ditto
	static getMyVar = function() {
		return self.myVar;
	}
	static getOtherVar = function() {
		return otherVar; ///want_warn ditto
	}
}