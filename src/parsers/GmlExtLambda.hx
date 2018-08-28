package parsers;
import editors.EditCode;
import electron.FileWrap;
import gml.GmlVersion;
import gml.Project;
import gml.file.GmlFile;
import gmx.SfGmx;
import js.RegExp;
import tools.Dictionary;
import ui.Preferences;
import yy.YyExtension;
import yy.YyGUID;
using tools.NativeString;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlExtLambda {
	private static inline var lfPrefix = "__lf_";
	public static inline var extensionName = "gmedit_lambda";
	public static var errorText:String;
	public static function rxExtScript(name:String):RegExp {
		return new RegExp('((?:^|\n)#define $name\r?\n)([\\s\\S]*?)($|\r?\n#define)');
	}
	static var rxLambdaArgsSp = new RegExp("^([ \t]*)([\\s\\S]*)([ \t]*)$");
	static var rxLambdaPre = new RegExp("^"
		+ "(//!#lambda" // -> has meta?
			+ "([ \t]*)(\\$|\\w+)" // -> namePre, name
			+ "([ \t]*)(?:\\(([ \t]*)\\$([ \t]*)\\))?" // -> argsPre, args0, args1
		+ ".*\r?\n)"
		+ "(?:#args\\b[ \t]*(.+)\r?\n)?" // -> argsData
	+ "([ \t]*\\{[\\s\\S]*)$");
	//
	static function pre_1(edit:EditCode, code:String, data:GmlExtLambdaPre) {
		var project = data.project;
		var lambdaMap = project.lambdaMap;
		var version = data.version;
		var list = data.list;
		var map = data.map;
		//
		var q = new GmlReader(code);
		var row = 0;
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: q.skipStringAuto(c, version);
				default: if (c.isIdent0()) {
					q.skipIdent1();
					var s = q.substring(p, q.pos);
					if (lambdaMap[s]) {
						if (data.gml == null) data.gml = FileWrap.readTextFileSync(project.lambdaGml);
						var mt = rxExtScript(s).exec(data.gml);
						if (mt == null) continue;
						var impl = mt[2];
						impl = GmlExtArgs.pre(impl);
						mt = rxLambdaPre.exec(impl);
						if (mt == null) continue;
						flush(p);
						var laCode = mt[8];
						laCode = pre_1(edit, laCode, data);
						out += "#lambda" + mt[2] + (mt[3] != "$" ? mt[3] : "")
							+ mt[4] + (mt[7] != null ? "(" + mt[5] + mt[7] + mt[6] + ")" : "")
							+ laCode;
						list.push(s);
						map.set(s, laCode);
						start = q.pos;
					}
				};
			}
		}
		flush(q.pos);
		return out;
	}
	public static function pre(edit:EditCode, code:String):String {
		var pj = Project.current;
		if (!Preferences.current.lambdaMagic) return code;
		if (pj.lambdaGml == null) return code;
		if (edit.file.path == pj.lambdaGml) return code;
		var d:GmlExtLambdaPre = {
			project: pj,
			version: pj.version,
			list: [],
			map: new Dictionary(),
			gml: null,
		};
		var out = pre_1(edit, code, d);
		edit.lambdaList = d.list;
		edit.lambdaMap = d.map;
		return out;
	}
	//
	static function post_1(edit:EditCode, code:String, prefix:String, data:GmlExtLambdaPost) {
		var project = data.project;
		var version = data.version;
		var list0 = data.list0;
		var map0 = data.map0;
		var list1 = data.list1;
		var map1 = data.map1;
		//
		var q = new GmlReader(code);
		var row = 0;
		var out = "";
		var start = 0;
		function flush(till:Int) {
			out += q.substring(start, till);
		}
		inline function error(s:String):String {
			errorText = '[row $row]: ' + s;
			return null;
		}
		//
		function proc():String {
			var p0 = q.pos;
			q.skipSpaces0();
			var p:Int;
			var laName = null;
			var laNamePre = "";
			//
			if (q.peek().isIdent0()) {
				p = q.pos;
				q.skipIdent1();
				laNamePre = q.substring(p0, p);
				laName = q.substring(p, q.pos);
				p0 = q.pos;
				q.skipSpaces0();
			}
			//
			var laArgs = null;
			var laArgsPre = "";
			if (q.peek() == "(".code) {
				p = q.pos + 1;
				var depth = 0;
				while (q.loop) {
					var c = q.read();
					switch (c) {
						case "(".code: depth++;
						case ")".code: if (--depth <= 0) { q.pos -= 1; break; }
						case "/".code: switch (q.peek()) {
							case "/".code: q.skipLine();
							case "*".code: q.skip(); q.skipComment();
							default:
						};
						case "\r".code, "\n".code: return error("Expected a closing `)`");
						case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
						default:
					}
				}
				if (q.loop) {
					laArgsPre = q.substring(p0, p - 1);
					laArgs = q.substring(p, q.pos);
					q.skip();
					p0 = q.pos;
					q.skipSpaces0();
				} else return error("Expected a closing `)`");
			}
			//
			if (q.peek() == "{".code) {
				p = q.pos + 1;
				var depth = 0;
				while (q.loop) {
					var c = q.read();
					switch (c) {
						case "{".code: depth++;
						case "}".code: if (--depth <= 0) { q.pos -= 1; break; }
						case "/".code: switch (q.peek()) {
							case "/".code: q.skipLine();
							case "*".code: q.skip(); q.skipComment();
							default:
						};
						case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
						default:
					}
				}
				if (!q.loop) return error("Expected a closing `}`");
				q.skip();
				var laCode = q.substring(p0, q.pos);
				//
				var laArgsMt;
				if (laArgs != null) {
					laArgsMt = rxLambdaArgsSp.exec(laArgs);
					laCode = '#args $laArgs\n' + laCode;
					laCode = GmlExtArgs.post(laCode);
					if (laCode == null) return error("Arguments error:\n" + GmlExtArgs.errorText);
				} else laArgsMt = null;
				//
				laCode = '//!#lambda'
					+ laNamePre + (laName != null ? laName : "$")
					+ laArgsPre + (laArgsMt != null ? "(" + laArgsMt[1] + "$" + laArgsMt[3] + ")" : "")
					+ "\n" + laCode;
				// pick an unoccupied name:
				var laFull_0 = lfPrefix + prefix + "_" + (laName != null ? laName : "");
				var laFull_i = 0;
				var laFull:String;
				do {
					laFull = laFull_0;
					if (laFull_i > 0) laFull += laFull_i;
					laFull_i += 1;
				} while (map1.exists(laFull) // not taken by another thing in same script
					// and not taken by something from outside this script:
					|| !map0.exists(laFull) && project.lambdaMap.exists(laFull)
				);
				//
				laCode = post_1(edit, laCode, laFull.substring(lfPrefix.length), data);
				if (laCode == null) return null;
				//
				list1.push(laFull);
				map1.set(laFull, laCode);
				return laFull;
			} else {
				var opts = ["{code}"];
				if (laName != null) opts.push("name");
				if (laArgs != null) opts.push("(args)");
				if (opts.length > 1) {
					var optl = opts.pop();
					return error('Expected a ${opts.join(", ")} or $optl.');
				} else return error('Expected a ${opts[0]}.');
			}
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: q.skipLine();
					case "*".code: q.skip(); row += q.skipComment();
					default:
				};
				case '"'.code, "'".code, "`".code, "@".code: row += q.skipStringAuto(c, version);
				case "#".code: {
					q.skipIdent1();
					var hash = q.substring(p, q.pos);
					if (hash == "#lambda") {
						var full = proc();
						if (full == null) return null;
						flush(p);
						out += full;
						start = q.pos;
					} else if (p == 0 || q.get(p - 1) == "\n".code) switch (hash) {
						case "#define", "#event", "#moment": {
							q.skipSpaces0();
							var p1 = q.pos;
							switch (hash) {
								case "#define": {
									q.skipIdent1();
									prefix = q.substring(p1, q.pos);
								};
								case "#event": {
									q.skipEventName();
									prefix = edit.file.name + "_" + q.substring(p1, q.pos).replace(":", "_");
								};
								case "#moment": {
									q.skipIdent1();
									prefix = edit.file.name + "_" + q.substring(p1, q.pos);
								};
							}
						};
						default: q.pos = p + 1;
					} else q.pos = p + 1;
				};
			}
		}
		flush(q.pos);
		return out;
	}
	static function postGMS1(d:GmlExtLambdaPost) {
		var pj = d.project;
		var ext = FileWrap.readGmxFileSync(pj.lambdaExt);
		var file:SfGmx = null;
		for (f in ext.find("files").findAll("file")) {
			file = f; break;
		}
		var fns:SfGmx = file.find("functions");
		var extz = false;
		for (s in d.list0) if (!d.map1.exists(s)) {
			extz = true;
			for (f in fns.findAll("function")) if (f.findText("name") == s) {
				fns.removeChild(f);
				break;
			}
		}
		function makeFn(s:String) {
			var fn = new SfGmx("function");
			fn.addTextChild("name", s);
			fn.addTextChild("externalName", s);
			fn.addTextChild("kind", "11");
			fn.addTextChild("help", "");
			fn.addTextChild("returnType", "2");
			fn.addTextChild("argCount", "-1");
			fn.addChild(new SfGmx("args"));
			return fn;
		}
		for (s in d.list1) if (!d.map0.exists(s)) {
			var skip = false;
			for (fn in fns.findAll("function")) if (fn.findText("name") == s) {
				skip = true; break;
			}
			if (skip) continue;
			extz = true;
			fns.addChild(makeFn(s));
		}
		if (file.findText("init") == "") {
			file.find("init").text = lfPrefix;
			fns.children.unshift(makeFn(lfPrefix));
			extz = true;
			d.checkInit = true;
		}
		if (extz) FileWrap.writeTextFileSync(pj.lambdaExt, ext.toGmxString());
	}
	static function postGMS2(d:GmlExtLambdaPost) {
		var pj = d.project;
		var ext:YyExtension = FileWrap.readJsonFileSync(pj.lambdaExt);
		var file = ext.files[0];
		var fns:Array<YyExtensionFunc> = file.functions;
		var order = file.order;
		var extz = false;
		for (s in d.list0) if (!d.map1.exists(s)) {
			extz = true;
			for (f in fns) if (f.name == s) {
				fns.remove(f);
				order.remove(f.id);
				break;
			}
		}
		function makeFn(s:String) {
			return {
				id: new YyGUID(),
				modelName: "GMExtensionFunction",
				mvc: "1.0",
				argCount: -1,
				args: [],
				externalName: s,
				help: "",
				hidden: true,
				kind: 11,
				name: s,
				returnType: 2,
			};
		}
		for (s in d.list1) if (!d.map0.exists(s)) {
			var skip = false;
			for (fn in fns) if (fn.name == s) {
				skip = true;
				break;
			}
			if (skip) continue;
			extz = true;
			var fn = makeFn(s);
			order.push(fn.id);
			fns.push(fn);
		}
		if (file.init == "") {
			file.init = lfPrefix;
			var fn = makeFn(lfPrefix);
			order.unshift(fn.id);
			fns.unshift(fn);
			extz = true;
			d.checkInit = true;
		}
		if (extz) FileWrap.writeJsonFileSync(pj.lambdaExt, ext);
	}
	public static function post(edit:EditCode, code:String):String {
		if (!Preferences.current.lambdaMagic) return code;
		var hasLambda = code.indexOf("#lambda") >= 0;
		if (!hasLambda && edit.lambdaList.length == 0) return code;
		//
		var pj = Project.current;
		var data:GmlExtLambdaPost = {
			project: pj,
			version: pj.version,
			list0: edit.lambdaList,
			map0: edit.lambdaMap,
			list1: [],
			map1: new Dictionary(),
			checkInit: false,
		};
		var out = hasLambda ? post_1(edit, code, edit.file.name, data) : code;
		if (data.list0.length != 0 || data.list1.length != 0) {
			switch (pj.version) {
				case v1, v2: {}; // OK!
				default: {
					errorText = "Lambdas are not supported for this version of GM.";
					return null;
				};
			}
			if (pj.lambdaExt == null || pj.lambdaGml == null) {
				errorText = 'Please add an extension called `$extensionName` to the project,'
					+ " add a placeholder GML file to it, and reload (Ctrl+R) in GMEdit.";
				return null;
			}
			//
			var gml:String = null;
			inline function prepare():Void {
				if (gml == null) gml = FileWrap.readTextFileSync(pj.lambdaGml);
			}
			//
			if (data.checkInit) {
				prepare();
				if (!(new RegExp('#define $lfPrefix\\b')).test(gml)) {
					gml = '#define $lfPrefix\n'
						+ '// https://bugs.yoyogames.com/view.php?id=29984\n'
						+ gml;
				}
			}
			var remList = [];
			var setList = [];
			for (s in data.list0) {
				var s1 = data.map1[s];
				if (s1 == null) {
					remList.push(s);
				} else if (s1 != data.map0[s]) {
					setList.push(s);
				}
			}
			for (s in data.list1) if (!data.map0.exists(s)) {
				setList.push(s);
			}
			var changed = remList.length > 0 || setList.length > 0;
			if (changed) {
				var gml = FileWrap.readTextFileSync(pj.lambdaGml);
				for (s in remList) {
					gml = gml.replaceExt(rxExtScript(s), "$3");
					pj.lambdaMap.remove(s);
				}
				for (s in setList) {
					pj.lambdaMap.set(s, true);
					var add = true;
					gml = gml.replaceExt(rxExtScript(s), function(_, s0, c, s1) {
						trace(s0, c, s1);
						add = false;
						return s0 + data.map1[s] + s1;
					});
					if (add) {
						if (gml != "") gml += "\n";
						gml += '#define $s\n' + data.map1[s];
					}
				}
				FileWrap.writeTextFileSync(pj.lambdaGml, gml);
			}
			edit.lambdaList = data.list1;
			edit.lambdaMap = data.map1;
			//
			if (changed) switch (pj.version) {
				case v1: postGMS1(data);
				case v2: postGMS2(data);
				default: {
					errorText = "Lambdas are not supported in this version of GM.";
					return null;
				};
			}
		}
		return out;
	}
}
private typedef GmlExtLambdaPre = {
	project:Project,
	version:GmlVersion,
	list:Array<String>,
	map:Dictionary<String>,
	gml:String,
}
private typedef GmlExtLambdaPost = {
	project:Project,
	version:GmlVersion,
	list0:Array<String>,
	map0:Dictionary<String>,
	list1:Array<String>,
	map1:Dictionary<String>,
	checkInit:Bool,
}
