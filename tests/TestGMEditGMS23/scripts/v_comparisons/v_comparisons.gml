function v_comparisons() {
	var a;
	a = (0 == 1);
	a = ("1" == "0");
	a = (0 == "0"); // allowed comparison
	a = ("1" == 0);
	a = ({} == 0);
	a = (undefined == 0);
	
	
	a = (os_device == os_type); ///want_warn uncomparable types
	a = (os_device == os_ios); ///want_warn uncompareable types
	
	a = (os_type == os_ios);
	var b/*:os_type*/ = os_ios;
	var c/*:os_device*/ = os_ios; ///want_warn uncompareable types

	
	a = (os_device == 0); // allowed for now, there's too many edge cases to deal with
}