// note: you need a theme with rainbow brackets enabled to test this
function v_is_highlight() constructor {
	value1 = new Class1();      /// @is {Class1<Class1<Class1>>}
    value2 = new Class1();      /// @is {Class1<Class1<Class1>>}
    value3 = new Class1();      /// @is {Class1<Class1<Class1>>}
    {
    	hey = 1; ///want_warn
    }
}