function CastPoint() constructor {
	x = 0; /// @is {number}
	y = 0; /// @is {number}
}
function v_cast_as() {
	var zi/*:int?*/ = 1;
	var i/*:int*/ = zi; // want warn
	i = /*#cast*/ zi;
	i = zi /*#as int*/;
	var s/*:string*/ = zi /*#as string*/; // want warn
	if (false) {
		var p/*:CastPoint*/ = (/*#cast*/ zi /*#as CastPoint*/); // incorrect, but allowed
		p = (/*#cast*/ (1 + 2) /*#as CastPoint*/); // ditto
		var px = /*#cast*/ zi /*#as CastPoint*/.x // should offer completion
	}
	
	var si/*:int|string*/ = 0;
	i = si; // want warn
	i = si /*#as int*/; // allowed - explicit cast
	s = si; // want warn
	s = si /*#as string*/; // allowed - explicit cast
}