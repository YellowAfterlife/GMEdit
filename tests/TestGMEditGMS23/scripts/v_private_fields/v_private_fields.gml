globalvar __hidden_gv; ///note: should not show in generic auto-completion
function v_private_fields() constructor {
	global.__hidden_g = 1; ///note: should not show in `global.` auto-completion
	
	__private = 1;
	public = 2;
	self.__private = 1;
	self.public = 2;
	///note: type `.` to verify that __private is not in completion
}