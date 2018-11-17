package parsers;
import ace.AceWrap;
import ace.extern.*;
import ace.AceMacro.jsRx;
import editors.EditCode;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.GmlLocals;
import gml.GmlVersion;
import gml.Project;
import gml.file.GmlFile;
import gml.file.GmlFileKind;
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
	public static var defaultMap:Dictionary<GmlExtLambda> = new Dictionary();
	public static var currentMap:Dictionary<GmlExtLambda> = defaultMap;
	public static var seekData:GmlSeekData = new GmlSeekData();
	public static var seekPath:String = "";
	//
	public var comp:AceAutoCompleteItems = [];
	public var kind:Dictionary<String> = new Dictionary();
	public var docs:Dictionary<GmlFuncDoc> = new Dictionary();
	private var remap:Dictionary<String> = new Dictionary();
	public function new() {
		
	}
	//
	
	// todo: ticket #
	public static var useVars:Bool = false;
	public static inline var lfPrefix = "__lf_";
	public static inline var lcPrefix = "__lc_";
	public static var rxlfPrefix:RegExp = new RegExp("^__lf_");
	public static var rxlcPrefix:RegExp = new RegExp("^__lc_");
	public static var rxPrefix:RegExp = new RegExp("^__(?:lf|lc)_");
	public static var rxlfInit:RegExp = new RegExp('(^#define $lfPrefix\r?\n)([\\s\\S]*?)($|\\s*\r?\n#define)');
	
	/** An ode to strange workarounds */
	public static function prefixSwap(name:String):String {
		if(name.charCodeAt(0) == "_".code
		&& name.charCodeAt(1) == "_".code
		&& name.charCodeAt(2) == "l".code) {
			switch (name.charCodeAt(3)) {
				case "f".code: return "__lc" + name.substring(4);
				case "c".code: return "__lf" + name.substring(4);
				default: return name;
			}
		} else return name;
	}
	
	public static inline var extensionName = "gmedit_lambda";
	
	public static var errorText:String;
	public static function rxExtScript(name:String):RegExp {
		if (useVars) name = name.replaceExt(rxlfPrefix, lcPrefix);
		return new RegExp('((?:^|\n)#define $name\r?\n)([\\s\\S]*?)($|\r?\n#define)');
	}
	static var rxLambdaArgsSp = new RegExp("^([ \t]*)([\\s\\S]*)([ \t]*)$");
	static var rxLambdaPre = new RegExp("^"
		+ "(?:///.*\r?\n)?"
		+ "(//!#lambda" // -> has meta?
			+ "([ \t]*)(\\$|\\w+)" // -> namePre, name
			+ "([ \t]*)(?:\\(([ \t]*)\\$([ \t]*)\\))?" // -> argsPre, args0, args1
		+ ".*\r?\n)"
		+ "(?:#args\\b[ \t]*(.+)\r?\n)?" // -> argsData
	+ "([ \t]*\\{[\\s\\S]*)$");
	static var rxLambdaDef = new RegExp("^/\\*!#lamdef (\\w+)\\*/");
	//
	public static function preImpl(code:String, data:GmlExtLambdaPre) {
		var project = data.project;
		var lambdaMap = project.lambdaMap;
		var version = data.version;
		var list = data.list;
		var map = data.map;
		var scope = data.scope;
		//
		var q = new GmlReader(code);
		var row = 0;
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		function proc(s:String, def:String, p:Int) {
			// fetch lambda script:
			if (data.gml == null) data.gml = FileWrap.readTextFileSync(project.lambdaGml);
			var mt = rxExtScript(s).exec(data.gml);
			if (mt == null) return false;
			// convert #args (if used) and match extras:
			var impl = mt[2];
			impl = GmlExtArgs.pre(impl);
			mt = rxLambdaPre.exec(impl);
			if (mt == null) return false;
			// form the magic code:
			flush(p);
			var laName = mt[3];
			var laArgs = (mt[7] != null ? "(" + mt[5] + mt[7] + mt[6] + ")" : "");
			if (laName != "$") {
				scope.remap.set(s, laName);
				scope.kind.set(laName, "lambda.function");
				scope.comp.push(new AceAutoCompleteItem(laName, "lambda",
					laArgs != "" ? laName + laArgs : null));
				scope.docs.set(laName, GmlFuncDoc.parse(laName + laArgs));
			}
			var laCode = mt[8];
			laCode = preImpl(laCode, data);
			out += def + mt[2] + (laName != "$" ? laName : "")
				+ mt[4] + laArgs + laCode;
			list.push(s);
			map.set(s, laCode);
			return true;
		}
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
				case "#".code: {
					var ctx = q.readContextName(null);
					if (ctx != null) {
						scope = new GmlExtLambda();
						data.scopes.set(ctx, scope);
						data.scope = scope;
					}
				};
				case "{".code: {
					if (q.substring(q.pos, q.pos + 10) == "/*!#lamdef") {
						var p1 = q.source.indexOf("}", q.pos);
						if (p1 < 0) continue;
						var mt = rxLambdaDef.exec(q.substring(p + 1, p1));
						if (mt == null) continue;
						if (proc(mt[1], "#lamdef", p)) {
							q.pos = p1 + 1;
							start = q.pos;
						}
					}
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var s = q.substring(p, q.pos);
					if (!lambdaMap[s]) continue;
					//
					var rs = scope.remap[s];
					if (rs != null) {
						flush(p);
						out += rs;
						start = q.pos;
						continue;
					}
					//
					if (proc(s, "#lambda", p)) {
						start = q.pos;
					}
				};
			}
		}
		flush(q.pos);
		return out;
	}
	public static function preInit(pj:Project):GmlExtLambdaPre {
		var scopes = new Dictionary();
		var scope = new GmlExtLambda();
		scopes.set("", scope);
		return {
			project: pj,
			version: pj.version,
			list: [],
			map: new Dictionary(),
			scopes: scopes,
			scope: scope,
			gml: null,
		};
	}
	public static function pre(edit:EditCode, code:String):String {
		var pj = Project.current;
		if (!Preferences.current.lambdaMagic) return code;
		if (pj.lambdaGml == null) return code;
		if (edit.file.path == pj.lambdaGml) return code;
		var d = preInit(pj);
		var out = preImpl(code, d);
		edit.lambdaList = d.list;
		edit.lambdaMap = d.map;
		edit.lambdas = d.scopes;
		return out;
	}
	//
	static function post_1(fileName:String, code:String, prefix:String, data:GmlExtLambdaPost) {
		var project = data.project;
		var version = data.version;
		var list0 = data.list0;
		var map0 = data.map0;
		var list1 = data.list1;
		var map1 = data.map1;
		var scope = data.scope;
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
				var laArgsMt, laArgsDoc;
				if (laArgs != null) {
					laArgsMt = rxLambdaArgsSp.exec(laArgs);
					laCode = '#args $laArgs\n' + laCode;
					laCode = GmlExtArgs.post(laCode);
					laArgsDoc = laArgs;
					if (laCode == null) return error("Arguments error:\n" + GmlExtArgs.errorText);
				} else {
					laArgsMt = null;
					laArgsDoc = GmlFuncDoc.autoArgs(laCode);
				}
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
				laCode = '/// $laFull($laArgsDoc)\n'
					+ '//!#lambda'
					+ laNamePre + (laName != null ? laName : "$")
					+ laArgsPre + (laArgsMt != null ? "(" + laArgsMt[1] + "$" + laArgsMt[3] + ")" : "")
					+ "\n" + laCode;
				//
				if (laName != null) {
					if (scope.remap.exists(laName)) return error(
						'There\'s already a lambda named $laName in this scope!');
					scope.remap.set(laName, laFull);
					scope.kind.set(laName, "lambda.function");
					scope.comp.push(new AceAutoCompleteItem(laName, "lambda",
						laArgs != null ? '$laName($laArgs)' : null));
					scope.docs.set(laName, GmlFuncDoc.parse(laName + '(${laArgs!=null?laArgs:""})'));
				}
				//
				laCode = post_1(fileName, laCode, laFull.substring(lfPrefix.length), data);
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
					var isDef = hash == "#lamdef";
					if (isDef || hash == "#lambda") {
						var full = proc();
						if (full == null) return null;
						flush(p);
						if (isDef) {
							out += '{/*!#lamdef $full*/}';
						} else out += full;
						start = q.pos;
					}
					else if (p == 0 || q.get(p - 1) == "\n".code) switch (hash) {
						case "#define", "#event", "#moment": {
							q.skipSpaces0();
							var p1 = q.pos;
							var ct:String;
							inline function ct_proc():Void {
								ct = q.substring(p1, q.pos);
							}
							scope = new GmlExtLambda();
							data.scope = scope;
							switch (hash) {
								case "#define": {
									q.skipIdent1();
									ct_proc();
									prefix = ct;
								};
								case "#event": {
									q.skipEventName();
									ct_proc();
									prefix = fileName + "_" + ct.replace(":", "_");
								};
								case "#moment": {
									q.skipIdent1();
									ct_proc();
									prefix = fileName + "_" + ct;
								};
								default: ct = null;
							}
							data.scopes.set(ct, scope);
						};
						default: q.pos = p + 1;
					} else q.pos = p + 1;
				};
				case _ if (c.isIdent0()): {
					q.skipIdent1();
					var s = q.substring(p, q.pos);
					var rs = scope.remap[s];
					if (rs != null) {
						// make sure we don't do inst.lf -> inst.__lf__:
						var z = true;
						var p1 = p;
						while (--p1 >= 0) switch (q.get(p1)) {
							case " ".code, "\t".code, "\r".code, "\n".code: {};
							case ".".code: z = false; break;
							default: break;
						}
						if (z) {
							flush(p);
							out += rs;
							start = q.pos;
						}
					}
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
		var mcs:SfGmx = file.find("constants");
		var extz = false;
		for (s in d.list0) if (!d.map1.exists(s)) {
			extz = true;
			if (useVars) {
				for (mc in mcs.findAll("constant")) if (mc.findText("name") == s) {
					mcs.removeChild(mc);
					break;
				}
				s = s.replaceExt(rxlfPrefix, lcPrefix);
			}
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
			if (useVars) {
				for (mc in mcs.findAll("constant")) if (mc.findText("name") == s) {
					skip = true; break;
				}
				if (skip) continue;
				var mc = new SfGmx("constant");
				mc.addTextChild("name", s);
				mc.addTextChild("value", "global.g" + s);
				mc.addTextChild("hidden", "-1");
				mcs.addChild(mc);
				s = s.replaceExt(rxlfPrefix, lcPrefix);
			}
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
		var mcs:Array<YyExtensionMacro> = file.constants;
		var order = file.order;
		var extz = false;
		var i:Int;
		for (s in d.list0) if (!d.map1.exists(s)) {
			extz = true;
			//
			if (useVars) {
				i = mcs.length;
				while (--i >= 0) {
					var mc = mcs[i];
					if (mc.constantName != s) continue;
					mcs.splice(i, 1);
					break;
				}
				s = s.replaceExt(rxlfPrefix, lcPrefix);
			}
			i = fns.length;
			while (--i >= 0) {
				var fn = fns[i];
				if (fn.name != s) continue;
				order.remove(fn.id);
				fns.splice(i, 1);
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
			if (useVars) {
				for (mc in mcs) if (mc.constantName == s) {
					skip = true;
					break;
				}
				if (skip) continue;
				mcs.push({
					id: new YyGUID(),
					modelName: "GMExtensionConstant",
					mvc: "1.0",
					constantName: s,
					hidden: true,
					value: "global.g" + s
				});
				s = s.replaceExt(rxlfPrefix, lcPrefix);
			}
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
	
	/**
	 * Returns whether a code-string has #lambda/#lamdef
	 * Not a warranty of lambda magic being actually used.
	 */
	public static inline function hasHashLambda(s:String) {
		return s.contains("#lambda") || s.contains("#lamdef");
	}
	public static function postImpl(code:String, data:GmlExtLambdaPost):String {
		if (!Preferences.current.lambdaMagic) return code;
		var hasLambda = data.hasLambda;
		if (hasLambda == null) {
			hasLambda = hasHashLambda(code);
			data.hasLambda = hasLambda;
		}
		// had no lambdas before and clearly has no lambdas?:
		if (!hasLambda && data.list0.length == 0) return code;
		var out = hasLambda ? post_1(data.name, code, data.name, data) : code;
		if (out == null) return null; // syntax error
		var pj = data.project;
		// had no lambdas and still has no actual lambdas?:
		if (data.list0.length == 0 && data.list1.length == 0) return out;
		switch (pj.version) { // verify that we can at all
			case v1, v2: {}; // OK!
			default: {
				errorText = "Lambdas are not supported for this version of GM.";
				return null;
			};
		}
		if (pj.lambdaExt == null || pj.lambdaGml == null) {
			errorText = 'Please add an extension called `$extensionName` to the project,'
				+ " add a placeholder GML file to it, and reload (Ctrl+R) in GMEdit.";
			if (pj.version == GmlVersion.v1) errorText += "\n\nAs this is GMS1, you'll also need to reload the project after you save a file with lambdas for the first time. Sorry about that.";
			return null;
		}
		//
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
		//
		var gml:String = null;
		inline function prepare():Void {
			if (gml == null) gml = FileWrap.readTextFileSync(pj.lambdaGml);
		}
		// apply extension changes if lambdas were added/removed:
		if (changed) switch (pj.version) {
			case v1: postGMS1(data);
			case v2: postGMS2(data);
			default: {
				errorText = "Lambdas are not supported in this version of GM.";
				return null;
			};
		}
		// ensure that the extension has an init function:
		if (data.checkInit) {
			prepare();
			if (!(new RegExp('^#define $lfPrefix$', 'm')).test(gml)) {
				gml = '#define $lfPrefix\n'
					+ '// https://bugs.yoyogames.com/view.php?id=29984'
					+ (gml != "" ? "\n" + gml : "");
			}
		}
		// apply changes to the GML file:
		if (changed) {
			prepare();
			for (s in remList) {
				gml = gml.replaceExt(rxExtScript(s), "$3");
				gml = gml.replaceExt(new RegExp('\n$s = .+'), "");
				pj.lambdaMap.remove(s);
				GmlAPI.extDoc.remove(s);
				seekData.locals.remove(s);
			}
			for (s in setList) {
				pj.lambdaMap.set(s, true);
				var scr = data.map1[s];
				var locals = new GmlLocals();
				seekData.locals.set(s, locals);
				GmlSeeker.runSyncImpl(seekPath, scr, s, seekData, locals, GmlFileKind.LambdaGML);
				readDefs_1(scr); // maybe change map1 to have code+docs pairs later
				var add = true;
				gml = gml.replaceExt(rxExtScript(s), function(_, s0, c, s1) {
					add = false;
					return s0 + scr + s1;
				});
				if (add) {
					if (gml != "") gml += "\n";
					var scrName = s;
					if (useVars) {
						scrName = s.replaceExt(rxlfPrefix, lcPrefix);
						gml = gml.replaceExt(rxlfInit, function(_, s0, init, s1) {
							return '$s0$init\n$s = asset_get_index("$scrName");$s1';
						});
					}
					gml += '#define $scrName\n' + scr;
				}
			}
			FileWrap.writeTextFileSync(pj.lambdaGml, gml);
		}
		return out;
	}
	public static function postInit(name:String,
		pj:Project, lambdaList:Array<String>, lambdaMap:Dictionary<String>
	):GmlExtLambdaPost {
		var scopes = new Dictionary();
		var scope = new GmlExtLambda();
		scopes.set("", scope);
		return {
			name: name,
			project: pj,
			version: pj.version,
			list0: lambdaList,
			map0: lambdaMap,
			list1: [],
			map1: new Dictionary(),
			scopes: scopes,
			scope: scope,
			checkInit: false,
			hasLambda: null,
		};
	}
	public static function post(edit:EditCode, code:String):String {
		if (!Preferences.current.lambdaMagic) return code;
		var hasLambda = hasHashLambda(code);
		if (!hasLambda && edit.lambdaList.length == 0) return code;
		var data = postInit(edit.file.name, Project.current, edit.lambdaList, edit.lambdaMap);
		data.hasLambda = hasLambda;
		var out = postImpl(code, data);
		edit.lambdas = data.scopes;
		edit.lambdaList = data.list1;
		edit.lambdaMap = data.map1;
		return out;
	}
	static var readDefs_rx = new RegExp('^///\\s*(($lfPrefix\\w+).+)', "gm");
	static function readDefs_1(code:String) {
		var rx = readDefs_rx, mt;
		rx.lastIndex = 0;
		mt = rx.exec(code);
		while (mt != null) {
			GmlAPI.extDoc.set(mt[2], GmlFuncDoc.parse(mt[1]));
			mt = rx.exec(code);
		}
	}
	/** loads up definitions from a file */
	public static function readDefs(path:String) {
		try {
			var code = FileWrap.readTextFileSync(path);
			useVars = code.indexOf("//!usevars") >= 0;
			GmlSeeker.runSync(path, code, "", GmlFileKind.LambdaGML);
			seekPath = path;
			seekData = GmlSeekData.map[path];
			if (useVars) {
				var locals = seekData.locals;
				for (fd in locals.keys()) {
					if (fd.startsWith(lcPrefix)) {
						var v = locals[fd];
						locals.remove(fd);
						locals.set(lfPrefix + fd.substring(lcPrefix.length), v);
					}
				}
			}
		} catch (e:Dynamic) {
			
		}
		FileWrap.readTextFile(path, function(e, code:String) {
			if (e != null) return;
			readDefs_1(code);
		});
	}
}
typedef GmlExtLambdaPre = {
	project:Project,
	version:GmlVersion,
	list:Array<String>,
	map:Dictionary<String>,
	gml:String,
	scopes:Dictionary<GmlExtLambda>,
	scope:GmlExtLambda,
}
typedef GmlExtLambdaPost = {
	name:String,
	project:Project,
	version:GmlVersion,
	list0:Array<String>,
	map0:Dictionary<String>,
	list1:Array<String>,
	map1:Dictionary<String>,
	checkInit:Bool,
	scopes:Dictionary<GmlExtLambda>,
	scope:GmlExtLambda,
	hasLambda:Null<Bool>,
}
