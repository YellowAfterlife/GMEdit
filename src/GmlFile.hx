package;
import js.html.Element;
import ace.AceWrap;
import gmx.*;

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
	public function load() {
		var src = Main.nodefs.readFileSync(path, "utf8");
		var gmx:SfGmx, out:String, errors:String;
		switch (kind) {
			case Normal: code = src;
			case GmxObject: {
				gmx = SfGmx.parse(src);
				out = "";
				errors = "";
				for (evOuter in gmx.findAll("events")) {
					var events = evOuter.findAll("event");
					events.sort(function(a:SfGmx, b:SfGmx) {
						var atype = Std.parseInt(a.get("eventtype"));
						var btype = Std.parseInt(b.get("eventtype"));
						if (atype != btype) return atype - btype;
						//
						var aname = a.get("ename");
						var bname = b.get("ename");
						if (aname != null || bname != null) {
							return untyped aname < bname ? 1 : -1;
						}
						//
						var anumb = Std.parseInt(a.get("enumb"));
						var bnumb = Std.parseInt(b.get("enumb"));
						return anumb - bnumb;
					});
					for (event in events) {
						var type = Std.parseInt(event.get("eventtype"));
						var ename = event.get("ename");
						var numb:Int = ename == null ? Std.parseInt(event.get("enumb")) : null;
						if (out != "") out += "\n";
						var name = GmxEvent.toString(type, numb, ename);
						out += "#define " + name;
						var actions = event.findAll("action");
						function addAction(action:SfGmx, head:Bool) {
							if (head) out += "\n\n";
							if(action.findText("libid") != "1"
							|| action.findText("id") != "603"
							|| action.findText("useapplyto") != "-1") {
								errors += "Can't read non-code block in " + name;
								return;
							}
							var code = action.find("arguments").find("argument").find("string").text;
							if (head && !StringTools.startsWith(code, "///")) {
								out += "///\n";
							}
							out += code;
						}
						if (actions.length != 0) {
							out += "\n";
							addAction(actions[0], false);
							for (i in 1 ... actions.length) {
								addAction(actions[i], true);
							}
						}
					}
				}
				if (errors != "") {
					code = errors;
				} else code = out;
			};
			case GmxProjectMacros, GmxConfigMacros: {
				gmx = SfGmx.parse(src);
				out = "// note: only #macro definitions here are saved";
				if (kind == GmxConfigMacros) {
					gmx = gmx.find("ConfigConstants");
				}
				if (gmx != null) for (mcrParent in gmx.findAll("constants"))
				for (mcrNode in mcrParent.findAll("constant")) {
					var name = mcrNode.get("name");
					var expr = mcrNode.text;
					out += '\n#macro $name $expr';
				}
				code = out;
			};
		}
	}
	//
	public function save() {
		changed = false;
		session.getUndoManager().markClean();
		//
		
		//
	}
}
@:fakeEnum(Int) enum GmlFileKind {
	Normal;
	GmxObject;
	GmxProjectMacros;
	GmxConfigMacros;
}
