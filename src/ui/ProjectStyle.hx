package ui;
import electron.FileSystem;
import gml.Project;
import haxe.io.Path;
import js.RegExp;
import js.html.LinkElement;
import js.html.StyleElement;
using tools.NativeString;
using tools.HtmlTools;

/**
 * Manages per-project custom CSS
 * @author YellowAfterlife
 */
class ProjectStyle {
	public static var link:LinkElement;
	public static var style:StyleElement;
	public static inline function getPath() {
		return Project.current.path + ".css";
	}
	public static function reload() {
		var pj = Project.current;
		if (pj.path != "") {
			if (pj.isVirtual) {
				var cssPath = pj.name + ".css";
				if (pj.existsSync(cssPath)) {
					style.innerHTML = pj.readTextFileSync(cssPath);
				} else style.innerHTML = "";
				link.href = "";
			} else {
				var path = getPath();
				if (FileSystem.existsSync(path)) {
					link.href = "file:///" + path + "?t=" + Date.now().getTime();
				} else link.href = "";
				style.innerHTML = "";
			}
		} else {
			link.href = "";
			style.innerHTML = "";
		}
	}
	public static function setItemThumb(data:{
		thumb:String,
		ident:String,
		kind:String,
		rel:String,
		suffix:String,
	}) {
		var thumb = data.thumb;
		if (thumb != null) {
			thumb = Path.normalize(thumb);
			var pjdir = Path.normalize(Project.current.dir);
			if (thumb.startsWith(pjdir)) {
				thumb = "." + thumb.substring(pjdir.length);
			} else thumb = "file:///" + thumb;
		}
		//
		var path = getPath();
		var sel:String;
		var sfx = data.suffix;
		switch (data.kind) {
			case null: {
				sel = '.treeview .dir[' + TreeView.attrRel + '="'
					+ data.rel.escapeProp() + '"]$sfx > .header';
			};
			case "datafile", "extfile", "config": {
				sel = '.treeview .item[' + TreeView.attrRel + '="'
					+ data.rel.escapeProp() + '"]' + sfx;
			};
			default: {
				sel = '.treeview .item[' + TreeView.attrIdent + '="'
					+ data.ident.escapeProp() + '"]' + sfx;
			};
		}
		function proc(text:String) {
			var r0 = sel + ':before { background: url("';
			var r1 = '") center/contain no-repeat; }';
			var rx = new RegExp('^' + r0.escapeRx() + '.+' + r1.escapeRx() + '$', 'gm');
			var next = thumb != null ? r0 + thumb.escapeProp() + r1 : "";
			var found = false;
			text = text.replaceExt(rx, function(s) {
				found = true;
				return next;
			});
			if (!found && next != "") {
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
		style = Main.document.querySelectorAuto("#project-style-inline");
	}
}
