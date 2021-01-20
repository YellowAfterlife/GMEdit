/// @implements {IInterface}
function Class1() constructor {};

/// @param {IInterface} parent
function Class2(_parent) constructor {};

function v_doc_implements() {
	var par/*:Class1*/ = new Class1();
	var something = new Class2(par);
}