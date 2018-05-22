package parsers;
import ace.AceWrap.AceAutoCompleteItems;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.Project;
import haxe.io.Path;
import js.RegExp;
import tools.Dictionary;
import ui.Preferences;
using tools.NativeString;
using tools.NativeObject;
using tools.NativeArray;

/**
 * `#import` magic
 * @author YellowAfterlife
 */
class GmlExtImport {
	private static var rxImport = new RegExp((
		"^#import[ \t]+"
		+ "([\\w.]+\\*?)" // com.pkg[.*]
		+ "(?:[ \t]+(?:in|as)[ \t]+(\\w+)(?:\\.(\\w+))?)?" // in name
	), "");
	private static var rxImportFile = new RegExp("^#import[ \t]+(\"[^\"]*\"|'[^']*')", "");
	private static var rxPeriod = new RegExp("\\.", "g");
	public static var errorText:String;
	//
	static function parseRules(imp:GmlImports, mt:Array<String>) {
		var path = mt[1];
		var alias = mt[2];
		var flat:String;
		var flen:Int;
		var short:String;
		var check:Dictionary<String>->AceAutoCompleteItems->Void;
		var errors = "";
		if (path.endsWith("*")) {
			flat = path.substring(0, path.length - 1).replaceExt(rxPeriod, "_");
			flen = flat.length;
			function check(
				kind:Dictionary<String>, comp:AceAutoCompleteItems, docs:Dictionary<GmlFuncDoc>
			) {
				kind.forField(function(fd) {
					if (fd.startsWith(flat)) {
						var comps = comp.filter(function(comp) {
							return comp.name == fd;
						});
						short = fd.substring(flen);
						imp.add(fd, short, kind[fd], comps[0], docs[fd], alias);
					}
				});
			}
			check(GmlAPI.stdKind, GmlAPI.stdComp, GmlAPI.stdDoc);
			check(GmlAPI.extKind, GmlAPI.extComp, GmlAPI.extDoc);
			check(GmlAPI.gmlKind, GmlAPI.gmlComp, GmlAPI.gmlDoc);
		} else if (path.startsWith("global.")) {
			flat = path.substring(7);
			var ns:String = null;
			if (alias == null) {
				alias = flat;
			} else if (mt[3] != null) {
				ns = alias;
				alias = mt[3];
			}
			var comp = new ace.AceWrap.AceAutoCompleteItem(path, "global");
			imp.add(path, alias, "globalfield", comp, null, ns);
		} else {
			flat = path.replaceExt(rxPeriod, "_");
			var ns:String = null;
			if (alias == null) {
				var p = path.lastIndexOf(".");
				if (p < 0) return;
				alias = flat.substring(p + 1);
			} else if (mt[3] != null) {
				ns = alias;
				alias = mt[3];
			}
			function check(
				kind:Dictionary<String>, comp:AceAutoCompleteItems, docs:Dictionary<GmlFuncDoc>
			) {
				var fdk = kind[flat];
				if (fdk == null) return false;
				var comps = comp.filter(function(comp) {
					return comp.name == flat;
				});
				imp.add(flat, alias, fdk, comps[0], docs[flat], ns);
				return true;
			}
			if(!check(GmlAPI.stdKind, GmlAPI.stdComp, GmlAPI.stdDoc)
			&& !check(GmlAPI.extKind, GmlAPI.extComp, GmlAPI.extDoc)
			&& !check(GmlAPI.gmlKind, GmlAPI.gmlComp, GmlAPI.gmlDoc)
			) {
				errors += "Couldn't find " + flat + "\n";
			}
		}
	}
	static function parseFile(
		imp:GmlImports, rel:String, found:Dictionary<Bool>, cache:Dictionary<String>
	) {
		var fp = Path.withoutExtension(rel.toLowerCase());
		if (found[fp]) return true;
		var code = cache[rel];
		if (code == null) {
			var full = Path.join([Project.current.dir, "#import", rel]);
			if (!FileWrap.existsSync(full)) {
				full += ".gml";
				if (!FileWrap.existsSync(full)) return false;
			}
			code = FileWrap.readTextFileSync(full);
			cache.set(rel, code);
		}
		found.set(fp, true);
		var q = new GmlReader(code);
		var version = GmlAPI.version;
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "import") {
							var txt = q.substring(p + 3, q.pos);
							parseLine(imp, txt, found, cache);
						}
					};
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					q.skipStringAuto(c, version);
				};
				default: { };
			}
		}
		//
		return true;
	}
	static function parseLine(
		imp:GmlImports, txt:String, found:Dictionary<Bool>, cache:Dictionary<String>
	) {
		var mt = rxImport.exec(txt);
		if (mt != null) {
			parseRules(imp, mt);
			return true;
		}
		mt = rxImportFile.exec(txt);
		if (mt != null) {
			var rel = mt[1];
			parseFile(imp, rel.substring(1, rel.length - 1), found, cache);
			return true;
		}
		return false;
	}
	public static function pre(code:String, path:String) {
		inline function cancel() {
			var data = GmlSeekData.map[path];
			if (data != null) data.imports = null;
			return code;
		}
		if (!Preferences.current.importMagic) return cancel();
		var globalPath = Path.join([Project.current.dir, "#import", "global.gml"]);
		var globalExists = FileWrap.existsSync(globalPath);
		if (code.indexOf("//!#import") < 0 && !globalExists) return cancel();
		var cache = new Dictionary<String>();
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		var imp = new GmlImports();
		var imps = new Dictionary<GmlImports>();
		var files = new Dictionary<Bool>();
		if (globalExists) parseFile(imp, "global.gml", files, cache);
		imps.set("", imp);
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "import") {
							var txt = q.substring(p + 3, q.pos);
							if (parseLine(imp, txt, files, cache)) {
								flush(p);
								out += txt;
								start = q.pos;
							}
						}
					};
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					q.skipStringAuto(c, version);
				};
				case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
					var ctx = q.readContextName(null);
					if (ctx != null) {
						imp = new GmlImports();
						imps.set(ctx, imp);
						files = new Dictionary();
						if (globalExists) parseFile(imp, "global.gml", files, cache);
					}
				};
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						var ident = q.substring(p, q.pos);
						var next:String = null;
						if (ident != "global") {
							next = imp.shorten[ident];
						} else if (imp.hasGlobal) {
							q.skipSpaces0();
							if (q.peek() == ".".code) {
								q.skip();
								q.skipSpaces0();
								var p1 = q.pos;
								q.skipIdent1();
								next = imp.shortenGlobal[q.substring(p1, q.pos)];
							}
						}
						if (next != null) {
							flush(p);
							out += next;
							start = q.pos;
						}
					}
				};
			}
		}
		flush(q.pos);
		var data = GmlSeekData.map[path];
		if (data == null && version == live) {
			data = new GmlSeekData();
			GmlSeekData.map.set(path, data);
		}
		if (data != null) data.imports = imps;
		return out;
	}
	public static var post_numImports = 0;
	public static function post(code:String, path:String) {
		if (!Preferences.current.importMagic) {
			post_numImports = 0;
			return code;
		}
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		var data = GmlSeekData.map[path];
		var imps = data != null ? data.imports : null;
		var imp = imps != null ? imps[""] : null;
		var impc = 0;
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "import") {
							flush(p + 3);
							out += " ";
							start = p + 3;
						}
						q.skipLine();
					};
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: {
					q.skipStringAuto(c, version);
				};
				case "#".code: {
					if (q.substr(p + 1, 6) == "import") {
						q.skipLine();
						var txt = q.substring(p, q.pos);
						if (rxImport.test(txt) || rxImportFile.test(txt)) {
							flush(p);
							out += "//!" + txt;
							start = q.pos;
							impc += 1;
						}
					} else if (p == 0 || q.get(p - 1) == "\n".code) {
						var ctx = q.readContextName(null);
						if (ctx != null) {
							imp = imps != null ? imps[ctx] : null;
						}
					};
				};
				default: {
					if (c.isIdent0() && imp != null) {
						var dot = -1;
						while (q.loop) {
							c = q.peek();
							if (c.isIdent1()) {
								q.skip();
							} else if (c == ".".code) {
								if (dot == -1) {
									dot = q.pos;
									q.skip();
								} else break;
							} else break;
						}
						var id = imp.longen[q.substring(p, q.pos)];
						if (id != null) {
							flush(p);
							out += id;
							start = q.pos;
						} else if (dot != -1) {
							id = imp.longen[q.substring(p, dot)];
							if (id != null) {
								flush(p);
								out += id;
								start = dot;
								q.pos = dot;
							}
						}
					}
				};
			}
		}
		post_numImports = impc;
		flush(q.pos);
		return out;
	}
}
