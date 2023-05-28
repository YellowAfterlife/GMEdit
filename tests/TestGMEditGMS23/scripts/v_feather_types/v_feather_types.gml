function v_feather_types() {
	v_feather_types_1(spr_blank);
	v_feather_types_1(obj_test); ///want_warn
	var l/*:ds_list<number>*/ = v_feather_types_2();
	var ls/*:ds_list<string>*/ = v_feather_types_2(); ///want_warn
}

/// @param {Asset.GMSprite} sprite
function v_feather_types_1(_sprite) {
	
}

/// @returns {Id.DsList<Real>}
function v_feather_types_2() {
	return ds_list_create();
}