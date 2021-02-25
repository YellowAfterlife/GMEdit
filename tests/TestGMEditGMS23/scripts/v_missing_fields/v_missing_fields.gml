function MissingFields() constructor {
	one = 1;
	two = 2;
}
function MissingFieldsChild() : MissingFields() constructor {
	MissingFieldsExtras(); /// @implements
	four = 4;
}
/// @interface
function MissingFieldsExtras() {
	extra = 5;
}
function v_missing_fields() {
	var m/*:MissingFields*/ = new MissingFields();
	m.one = 1;
	m.two = 2;
	m.miss = 3; ///want_warn
	var c/*:MissingFieldsChild*/ = new MissingFieldsChild();
	c.one = 1;
	c.miss = 3; ///want_warn
	c.four = 4;
}
/// @self {MissingFieldsChild}
function v_missing_fields_self() {
	self.one = 1;
	one = 1;
	self.extra = 5;
	extra = 5;
	self.miss = 3; ///want_warn
	miss = 3; ///want_warn
}