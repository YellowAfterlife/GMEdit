package gml;
import electron.FileSystem;
import js.html.Element;
import ace.AceWrap;
import gmx.*;
import Main.document;
import haxe.io.Path;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlFile {
	public static var next:GmlFile = null;
	public static var current:GmlFile = null;
	//
	public var name:String;
	public var path:String;
	public var code:String;
	public var kind:GmlFileKind = Normal;
	public var session:AceSession;
	public var tabEl:Element;
	public var changed(get, set):Bool;
	private var __changed:Bool = false;
	private inline function get_changed() {
		return __changed;
	}
	private function set_changed(z:Bool) {
		if (__changed != z) {
			__changed = z;
			if (z) {
				tabEl.classList.add("chrome-tab-changed");
			} else {
				tabEl.classList.remove("chrome-tab-changed");
			}
		}
		return z;
	}
	//
	public function new(name:String, path:String, kind:GmlFileKind) {
		this.name = name;
		this.path = path;
		this.kind = kind;
		load();
		session = new AceSession(code, "ace/mode/gml");
		session.setUndoManager(new AceUndoManager());
	}
	//
	public static function open(name:String, path:String) {
		// see if there's an existing tab for this:
		for (tabEl in ui.ChromeTabs.element.querySelectorEls('.chrome-tab')) {
			var gmlFile:GmlFile = untyped tabEl.gmlFile;
			if (gmlFile != null && gmlFile.path == path) {
				tabEl.click();
				return;
			}
		}
		// determine what to do with the file:
		var kind:GmlFileKind;
		var ext = Path.extension(path).toLowerCase();
		switch (ext) {
			case "gml": kind = Normal;
			case "gmx": {
				ext = Path.extension(Path.withoutExtension(path)).toLowerCase();
				kind = switch (ext) {
					case "object": GmxObjectEvents;
					case "project": GmxProjectMacros;
					case "config": GmxConfigMacros;
					default: Extern;
				}
			};
			default: kind = Extern;
		}
		//
		if (kind != Extern) {
			// addTab doesn't return the new tab so we bind it up in the "active tab change" event:
			gml.GmlFile.next = new gml.GmlFile(name, path, kind);
			ui.ChromeTabs.addTab(name);
		} else {
			electron.Electron.shell.openItem(path);
		}
	}
	//
	public function load() {
		var src = FileSystem.readTextFileSync(path);
		var gmx:SfGmx, out:String, errors:String;
		switch (kind) {
			case Normal, Extern: code = src;
			case GmxObjectEvents: {
				gmx = SfGmx.parse(src);
				out = GmxObject.getCode(gmx);
				if (out == null) {
					code = GmxObject.errorText;
				} else code = out;
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				code = GmxProject.getMacroCode(gmx, kind == GmxConfigMacros);
			};
		}
	}
	//
	public function save() {
		var val = session.getValue();
		//
		var out:String, src:String, gmx:SfGmx;
		switch (kind) {
			case Normal, Extern: out = val;
			case GmxObjectEvents: {
				gmx = FileSystem.readGmxFileSync(path);
				if (!GmxObject.updateCode(gmx, val)) {
					Main.window.alert("Can't update GMX:\n" + GmxObject.errorText);
				}
				out = gmx.toGmxString();
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = FileSystem.readGmxFileSync(path);
				GmxProject.setMacroCode(gmx, val, kind == GmxConfigMacros);
				out = gmx.toGmxString();
			};
			default: {
				return;
			};
		}
		//
		//session.setValue(out);
		FileSystem.writeFileSync(path, out);
		changed = false;
		session.getUndoManager().markClean();
	}
}
@:fakeEnum(Int) enum GmlFileKind {
	Extern;
	Normal;
	GmxObjectEvents;
	GmxProjectMacros;
	GmxConfigMacros;
}
