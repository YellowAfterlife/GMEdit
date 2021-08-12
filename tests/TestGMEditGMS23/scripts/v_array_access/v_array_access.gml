function v_array_access() {
	var i/*:int*/, v/*:any*/, o/*:object*/;
	
	var a1/*:int[]*/ = [];
	i = a1[0];
	i = a1[0, 0]; ///want_warn
	i = a1[0][0]; ///want_warn
	
	var a2/*:int[][]*/ = [[]];
	i = a2[0]; ///want_warn
	i = a2[0, 0];
	i = a2[0][0];
	
	var a3/*:int[][][]*/ = [[[]]];
	i = a3[0]; ///want_warn
	i = a3[0, 0]; ///want_warn
	i = a3[0][0]; ///want_warn
	i = a3[0][0][0];
	i = a3[0, 0][0];
	i = a3[0][0, 0];
	
	var c2/*:ckarray<object, ckarray<object, int>>*/ = /*#cast*/ [];
	i = c2[obj_test]; ///want_warn
	i = c2[obj_test, obj_test];
	i = c2[obj_test][obj_test];
}