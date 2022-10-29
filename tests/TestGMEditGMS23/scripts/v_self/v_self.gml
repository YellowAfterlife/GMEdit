function SelfStruct() constructor {
	field = 0;
	
	static internalFunc = function() {
		in_self_struct_context();
	}
}

function NotSelfStruct() constructor {
	static internalFunc = function() {
		in_self_struct_context();  ///want_warn not the right context
	}
}

function InheritsSelfStruct() : SelfStruct() constructor {
	static internalFunc = function() {
		in_self_struct_context();
	}
}

///@self {SelfStruct}
function in_self_struct_context() {
	field = 0;
	not_a_field = 0; ///want_warn not a field
}

function v_self_struct() {
	let self_struct = new SelfStruct();
	with (self_struct) {
		in_self_struct_context();
	}
	let other_struct = new NotSelfStruct();
	with (other_struct) {
		in_self_struct_context(); ///want_warn not the right context
	}
	let inherit_struct = new InheritsSelfStruct();
	with (inherit_struct) {
		in_self_struct_context();
	}
}


/// To be called with the object
///@self {obj_self_object}
function in_self_object_context() {
	field = 0;
	not_a_field = 0; ///want_warn not a field
}


function in_self_object() {
	with (obj_self_object) {
		in_self_object_context();
	}
	with (obj_not_self_object) {
		in_self_object_context(); ///want_warn not the right context
	}
}