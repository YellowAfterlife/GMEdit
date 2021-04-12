globalvar nc_val; nc_val = undefined;
/// @param value
/// @returns {bool} Whether the value is non-null
function nc_set(v) {
	nc_val = v;
	return v != undefined && v != noone;
}

#macro let var
#macro const var