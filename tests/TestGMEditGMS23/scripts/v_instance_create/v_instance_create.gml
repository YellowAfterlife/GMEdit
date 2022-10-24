function v_instance_create() {
	instance_create_depth(0, 0, 0, obj_variable_definitions);
	instance_create_depth(0, 0, 0, obj_variable_definitions, {});
	instance_create_depth(0, 0, 0, obj_variable_definitions, { a_real: 1 });
	instance_create_depth(0, 0, 0, obj_variable_definitions, { missing_var: 1 }); ///want_warn
}