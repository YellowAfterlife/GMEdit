package parsers;
import ace.AceMacro;
import ace.extern.*;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlLocals;
import gml.Project;
import haxe.io.Path;
import js.RegExp;
import tools.Dictionary;
import ui.Preferences;
import parsers.GmlReader.SkipVarsData;
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
	public static inline var rsLocalType = "/\\*[ \t]*:[ \t]*(\\w+(?:<.*?>)?)\\*/";
	public static var rxLocalType = new RegExp("^" + rsLocalType + "$");
	private static var rxPeriod = new RegExp("\\.", "g");
	private static var rxHasType = new RegExp("(?:\\w/\\*:|var.+?\\w:|#args.+?\\w:)", "");
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
			var comp = new ace.extern.AceAutoCompleteItem(path, "global");
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
	/** `var v:Enum`, "v[Enum.field]" -> "v.field" */
	static function pre_mapIdent_local(q:GmlReader, imp:GmlImports, ident:String, t:String, p0:Int):String {
		var ns:GmlNamespace = imp.namespaces[t];
		var e:GmlEnum;
		if (ns == null) {
			e = GmlAPI.gmlEnums[t];
			if (e == null) return null;
		} else e = null;
		// spaces between `$id` and `[`
		q.skipSpaces0();
		var preSpaceEnd = q.pos;
		// `[` or `[@`:
		if (q.read() != "[".code) return null;
		var acc = q.peek() == "@".code;
		if (acc) q.skip();
		// spaces before the index:
		var posIndexPre = q.pos;
		q.skipSpaces0();
		// index (Enum.field for enums, full for namespaces):
		var posIndexStart = q.pos;
		q.skipIdent1();
		var index1:String = q.substring(posIndexStart, q.pos);
		var indexField:String, indexDot:Int;
		if (ns != null) {
			indexField = ns.shorten[index1];
			if (indexField == null) {
				if (q.read() != ".".code) return null;
				q.skipIdent1();
				indexField = ns.shorten[q.substring(posIndexStart, q.pos)];
				if (indexField == null) return null; // must be a member of namespace
			}
		} else {
			if (index1 != t) return null; // must be <enum name>
			if (q.read() != ".".code) return null;
			var indexDot = q.pos;
			q.skipIdent1();
			indexField = q.substring(indexDot, q.pos);
			if (!e.items.exists(indexField)) return null; // must be member of enum
		}
		if (q.read() != "]".code) return null;
		// [] for reading, [@] for writing:
		if (acc != q.checkWrites(p0, q.pos)) return null;
		// whew,
		return ident + "." + indexField;
	}
	static function pre_mapIdent(imp:GmlImports, q:GmlReader, ident:String, p0:Int):String {
		var next:String = null;
		var t = imp.localTypes[ident];
		var p1:Int = q.pos;
		if (t != null) {
			next = pre_mapIdent_local(q, imp, ident, t, p0);
			if (next == null) q.pos = p1;
		} else if (ident != "global") {
			next = imp.shorten[ident];
			// `var v:T` .. `func(v, 0)` -> `v.func(0)`
			// `enum T { x, y, sizeof }` .. `array_create(T.sizeof)` -> `T()`
			// `thing_create(` -> `Thing.create(` -> `new Thing(`
			do {
				q.skipSpaces1();
				if (q.read() != "(".code) break;
				if (next != null && next.endsWith(".create")) { // Thing.create -> new Thing
					return "new " + next.substring(0, next.length - 7) + "(";
				}
				// `func(¦ v`:
				q.skipSpaces1();
				if (!q.peek().isIdent0()) break;
				var selfPos = q.pos;
				q.skipIdent1();
				// no `func(v¦[`:
				if (q.peek() == "[".code) break;
				// ident -> type -> namespace -> method name:
				var self = q.substring(selfPos, q.pos);
				var selfType = imp.localTypes[self];
				if (selfType == null) {
					if (ident != "array_create") break;
					var selfEnumName = self;
					var selfEnum = GmlAPI.gmlEnums[selfEnumName];
					if (selfEnum == null) {
						selfEnumName = imp.shorten[self];
						selfEnum = GmlAPI.gmlEnums[selfEnumName];
					}
					if (selfEnum == null) break;
					if (q.read() != ".".code) break;
					var selfDot = q.pos;
					q.skipIdent1();
					if (q.substring(selfDot, q.pos) != selfEnum.lastItem) break;
					q.skipSpaces1();
					if (q.read() != ")".code) break;
					return selfEnumName + "()";
					break;
				}
				var selfNs = imp.namespaces[selfType];
				if (selfNs == null) break;
				var selfFunc = selfNs.shorten[ident];
				if (selfFunc == null) break;
				var selfEnd = q.pos;
				// `func(v¦, 1)` -> `func(v, ¦1)`:
				q.skipSpaces1();
				if (q.read() == ",".code) {
					q.skipSpaces1();
				} else q.pos = selfEnd;
				// OK!
				return self + "." + selfFunc + "(";
			} while (false);
			q.pos = p1;
		} else if (imp.hasGlobal) {
			q.skipSpaces0();
			if (q.peek() == ".".code) {
				q.skip();
				q.skipSpaces0();
				p1 = q.pos;
				q.skipIdent1();
				next = imp.shortenGlobal[q.substring(p1, q.pos)];
			}
		}
		return next;
	}
	public static function pre(code:String, path:String) {
		var seekData = GmlSeekData.map[path];
		inline function cancel() {
			if (seekData != null) seekData.imports = null;
			return code;
		}
		if (!Preferences.current.importMagic) return cancel();
		var globalPath = Path.join([Project.current.dir, "#import", "global.gml"]);
		var globalExists = FileWrap.existsSync(globalPath);
		if (code.indexOf("//!#import") < 0
			&& !rxHasType.test(code)
			&& !globalExists
		) return cancel();
		var seekLocals = seekData != null ? seekData.locals : null;
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
					} else q.pos = p + 1;
				};
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						var p1 = q.pos;
						var ident = q.substring(p, p1);
						var next:String = null;
						if (ident == "var" || ident == "args" && q.get(p - 1) == "#".code) {
							var isVar = ident == "var";
							next = isVar ? imp.shorten[ident] : null;
							if (next != null) {
								flush(p);
								out += next;
								start = q.pos;
								next = null;
							}
							q.skipVars(function(d:SkipVarsData) {
								var p = q.pos;
								flush(d.type0);
								if (d.type != null) {
									imp.localTypes.set(d.name, d.type);
									out += ":" + d.type;
								}
								out += q.substring(d.type1, d.expr0);
								q.pos = d.expr0;
								start = q.pos;
								while (q.pos < d.expr1) {
									var p0 = q.pos;
									var c = q.read();
									switch (c) {
										case "/".code: switch (q.peek()) {
											case "/".code: q.skipLine();
											case "*".code: q.skip(); q.skipComment();
											default:
										};
										case '"'.code, "'".code, "`".code, "@".code: {
											q.skipStringAuto(c, version);
										};
										default: if (c.isIdent0()) {
											q.skipIdent1();
											var id = q.substring(p0, q.pos);
											var idn = pre_mapIdent(imp, q, id, p0);
											if (idn != null) {
												flush(p0);
												out += idn;
												start = q.pos;
											}
										};
									}
								}
								q.pos = p;
							}, version, !isVar);
						}
						else next = pre_mapIdent(imp, q, ident, p1);
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
		if (seekData == null && version == live) {
			seekData = new GmlSeekData();
			GmlSeekData.map.set(path, seekData);
		}
		if (seekData != null) seekData.imports = imps;
		return out;
	}
	
	public static var post_numImports = 0;
	static var post_procIdent_p1:Int = 0;
	static function post_procIdent(q:GmlReader, imp:GmlImports, p0:Int, dot:Int, full:String) {
		var p1 = q.pos;
		var one:String = dot != -1 ? q.substring(p0, dot) : null;
		if (full == "new") {
			q.skipSpaces1();
			var typePos = q.pos;
			if (q.read().isIdent0()) {
				q.skipIdent1();
				one = q.substring(typePos, q.pos);
				full = one + ".create";
				dot = q.pos;
				p1 = q.pos;
			} else q.pos = p1;
		}
		var type = dot != -1 ? imp.localTypes[one] : null;
		if (type != null) {
			var ns:GmlNamespace = imp.namespaces[type], en:GmlEnum;
			var ind:String = null;
			var fd = q.substring(dot + 1, p1);
			if (ns != null) {
				ind = ns.longen[fd];
				en = null;
			} else {
				en = GmlAPI.gmlEnums[type];
				if (en != null && en.items.exists(fd)) ind = type + '.' + fd;
			}
			if (ind != null) {
				q.skipSpaces1();
				if (q.read() == "(".code) {
					var argPos = q.pos;
					q.skipSpaces0();
					var argPre = q.peek() != ")".code ? ", " : "";
					q.pos = argPos;
					post_procIdent_p1 = argPos;
					return ind + "(" + one + argPre;
				} else q.pos = p1;
				post_procIdent_p1 = p1;
				return one + (q.checkWrites(p0, p1) ? '[@' : '[') + ind + ']';
			} else if (en != null || ns != null && ns.isStruct) {
				if (errorText != "") errorText += "\n";
				errorText += q.getPos(dot + 1).toString() + ' Could not find field $fd in '
					+ (ns != null ? 'namespace' : en != null ? 'enum' : 'unknown type')
					+ ' ' + type + '.';
				return null;
			}
		}
		//
		var id = imp.longen[full];
		var en = dot == -1 ? GmlAPI.gmlEnums[AceMacro.jsOr(id, full)] : null;
		if (en != null) do {
			q.skipSpaces1();
			if (q.read() != "(".code) break;
			q.skipSpaces1();
			if (q.read() != ")".code) break;
			post_procIdent_p1 = q.pos;
			return "array_create(" + en.name + "." + en.lastItem + ")";
		} while (false);
		//
		if (id != null) {
			post_procIdent_p1 = p1;
			return id;
		}
		//
		if (one != null) {
			id = imp.longen[one];
			if (id != null) {
				post_procIdent_p1 = dot;
				return id;
			}
		}
		return null;
	}
	public static function post(code:String, path:String) {
		errorText = "";
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
						} else q.pos = p + 1;
					};
				};
				default: {
					if (c.isIdent0() && imp != null) {
						//
						var dotStart:Int, dotPos:Int, dotFull:String;
						inline function readDotPair() {
							dotStart = q.pos;
							dotPos = -1;
							while (q.loop) {
								c = q.peek();
								if (c.isIdent1()) {
									q.skip();
								} else if (c == ".".code) {
									if (dotPos == -1) {
										dotPos = q.pos;
										q.skip();
									} else break;
								} else break;
							}
							dotFull = q.substring(dotStart, q.pos);
						}
						//
						var procIdent_next:String;
						inline function procIdent() {
							procIdent_next = post_procIdent(q, imp, dotStart, dotPos, dotFull);
							if (procIdent_next != null) {
								flush(dotStart);
								out += procIdent_next;
								start = post_procIdent_p1;
							}
						}
						//
						q.pos -= 1;
						readDotPair();
						if (dotFull == "var" || dotFull == "args" && q.get(p - 1) == "#".code) {
							var isVar = dotFull == "var";
							procIdent_next = isVar ? imp.longen["var"] : null;
							if (procIdent_next != null) {
								flush(p);
								out += procIdent_next;
								start = q.pos;
							}
							q.skipVars(function(d:SkipVarsData) {
								var p = q.pos;
								flush(d.type0);
								if (d.type != null) {
									out += isVar ? "/*:" + d.type + "*/" : ":" + d.type;
								}
								out += q.substring(d.type1, d.expr0);
								q.pos = d.expr0;
								start = q.pos;
								while (q.pos < d.expr1) {
									var p1 = q.pos;
									var c = q.read();
									switch (c) {
										case "/".code: switch (q.peek()) {
											case "/".code: q.skipLine();
											case "*".code: q.skip(); q.skipComment();
											default:
										};
										case '"'.code, "'".code, "`".code, "@".code: {
											q.skipStringAuto(c, version);
										};
										default: if (c.isIdent0()) {
											q.pos -= 1;
											readDotPair();
											procIdent();
										};
									}
								}
								q.pos = p;
							}, version, !isVar);
						} else procIdent();
						if (errorText != "") return null;
					} // c.isIdent && imp
				}; // default
			} // switch
		} // loop
		post_numImports = impc;
		flush(q.pos);
		return out;
	}
}
