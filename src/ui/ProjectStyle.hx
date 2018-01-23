package ui;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.RegExp;
import js.html.LinkElement;
using tools.NativeString;
using tools.HtmlTools;

/**
 * Manages per-project custom CSS
 * @author YellowAfterlife
 */
class ProjectStyle {
	public static var link:LinkElement;
	public static function reload() {
		var path = Project.current.path + ".css";
		if (FileSystem.existsSync(path)) {
			link.href = "file:///" + path + "?t=" + Date.now().getTime();
		} else link.href = "";
	}
	public static function setItemThumb(data:{
		thumb:String,
		ident:String,
		kind:String,
		rel:String,
	}) {
		var thumb = data.thumb;
		thumb = Path.normalize(thumb);
		var pjdir = Path.normalize(Project.current.dir);
		if (thumb.startsWith(pjdir)) {
			thumb = "." + thumb.substring(pjdir.length);
		} else thumb = "file:///" + thumb;
		//
		var path = Project.current.path + ".css";
		var sel:String;
		switch (data.kind) {
			case null: {
				sel = '.treeview .dir[' + TreeView.attrRel + '="'
					+ data.rel.escapeProp() + '"] > .header';
			};
			case "datafile", "extfile", "config": {
				sel = '.treeview .item[' + TreeView.attrRel + '="'
					+ data.rel.escapeProp() + '"]';
			};
			default: {
				sel = '.treeview .item[' + TreeView.attrIdent + '="'
					+ data.ident.escapeProp() + '"]';
			};
		}
		function proc(text:String) {
			var r0 = sel + ':before { background: url("';
			var r1 = '") center/contain no-repeat; }';
			var rx = new RegExp('^' + r0.escapeRx() + '.+' + r1.escapeRx() + '$', 'gm');
			var next = r0 + thumb.escapeProp() + r1;
			var found = false;
			text = text.replaceExt(rx, function(s) {
				found = true;
				return next;
			});
			if (!found) {
				if (text != "") text += "\n";
				text += next;
			}
			FileSystem.writeFileSync(path, text);
			reload();
		}
		if (!FileSystem.existsSync(path)) {
			proc("");
		} else FileSystem.readTextFile(path, function(err, txt) {
			if (err == null) proc(txt);
		});
	}
	public static function init() {
		link = Main.document.querySelectorAuto("#project-style");
	}
}
