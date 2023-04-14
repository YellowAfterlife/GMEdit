function IInterface() constructor {
	parent = /*#cast*/ undefined /*#as IInterface*/;
}

/// @implements {IInterface}
function Class1() constructor {
	
};

/// @implements {IInterface}
/// @param {IInterface} _parent
function Class2(_parent) constructor {
	x = 0;
	parent.parent = _parent;
	with (parent) {
		// `.` should show `parent` field
		// TODO: `with (_parent)` will not show fields because mini-linter didn't index the rest of the function
	}
	with (_parent /*#as IInterface*/) {
		// but this'll work
	}
};

function v_doc_implements() {
	var par/*:Class1*/ = new Class1();
	var something = new Class2(par);
}