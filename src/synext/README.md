# synext/

Various GMEdit-specific syntax extensions and pre/post-processors.

For adding your own syntax extensions from a plugin, you can do
```js
var SyntaxExtension = $gmedit["synext.SyntaxExtension"];
function MySynExt() {}
MySynExt.prototype = GMEdit.extend(SyntaxExtension.prototype, {
	check: function(editor, code) {
		// figure out if there's any work to do based on editor here
		return true;
	},
	preproc: function(editor, code) {
		// pre-process code here (make it look nice)
		return true;
	},
	postproc: function(editor, code) {
		// post-process code here (make it back into valid GML)
		return true;
	}
});
$gmedit["file.kind.KGml"].syntaxExtensions.push(new MySynExt());
```