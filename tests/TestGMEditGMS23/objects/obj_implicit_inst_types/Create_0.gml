a_number = 1;
a_number = undefined; ///want_warn "Can't cast undefined to number"
a_string = "hi!";
a_string = undefined; ///want_warn "Can't cast undefined to string"
a_bool = true;
a_bool = ""; ///want_warn "Can't cast string to bool"
an_array = [];
an_array = 0; ///want_warn "Can't cast number to array"
a_point = new CastPoint();
a_point = 0; ///want_warn "Can't cast number to CastPoint"
a_func = function(b, c) {}
a_func = 0; ///want_warn "Can't cast number to function"
a_buffer = buffer_create(1, buffer_fixed, 1);
a_buffer = 0; ///want_warn
an_inst = instance_create_depth(0, 0, 0, obj_one); ///note: gets typed as just `object`
an_inst = 0; ///want_warn
a_map = ds_map_create();
a_map = 0; ///want_warn
an_array2 = array_create(0, 1); ///note: gets typed to just `array`
an_array2 = 0; ///want_warn
a_sprite = spr_blank;
a_sprite2 = -1 /*#as sprite*/;
if (false) {
	a_sprite = 0; ///want_warn
	a_sprite2 = spr_blank;
	a_sprite2 = 0; ///want_warn
}
if (a_bool) {
	a_nested_number = 2;
}
var i;
i = my_number;
i = not_my_number; ///want_warn
i = post_with;