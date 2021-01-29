package synext;
import electron.FileSystem;
import file.kind.KGml;
import editors.EditCode;
import ace.AceMacro;
import ace.extern.*;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlEnum;
import gml.GmlFuncDoc;
import gml.GmlImports;
import gml.GmlLocals;
import gml.Project;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import haxe.io.Path;
import js.lib.RegExp;
import tools.Aliases;
import tools.Dictionary;
import tools.JsTools;
import ui.Preferences;
import parsers.GmlSeekData;
import parsers.GmlReader;
import parsers.GmlReaderExt;
import parsers.GmlReader.SkipVarsData;
using tools.NativeString;
using tools.NativeObject;
using tools.NativeArray;

/**
 * `#import` magic
 * @author YellowAfterlife
 */
class GmlExtImport {
	public static var inst:GmlExtImportWrap = new GmlExtImportWrap();
	
	private static var rxImport = new RegExp((
		"^#import[ \t]+(?:"
			+ "([\\w.]+\\*?)" // com.pkg[.*] -> $1
			+ "(?:"
				+ "[ \t]+(?:in|as)"
				+ "[ \t]+(\\w+)" // alias -> $2
				+ "(?:([:\\.])(\\w+)?)?" // .name|:name -> $3,$4
			+ ")?"
			+ "[ \t]*(?:[\r\n]|$)" // EOL
		//+ "|([\\w]\\(.*\\))[ \t]+(?:in|as)[ \t]+([\\w]\\(.*\\))" // func(...) in func(...)
	+ ")"), "");
	private static var rxImportFile = new RegExp("^#import[ \t]+(\"[^\"]*\"|'[^']*')", "");
	
	private static inline var rsLocalType_c = "[ \t]*:[ \t]*";
	
	/** `Type` or `Type<Param>` */
	private static inline var rsLocalType_t = "\\w+(?:[ \t]*<.*?>)?";
	
	/** matches `:Type` (inc. comment-closured), adds a group for `Type` */
	public static inline var rsLocalType = ('(?:'
		+ '(?=\\/\\*$rsLocalType_c$rsLocalType_t\\*\\/)\\/\\*|' // permit `/*:Type*/`
		+ '(?!$rsLocalType_c$rsLocalType_t\\*\\/)' // forbid `:Type*/`
	+ ')$rsLocalType_c($rsLocalType_t)(?:\\*\\/)?');
	
	public static var rxLocalType = new RegExp("^" + rsLocalType + "$");
	private static var rxPeriod = new RegExp("\\.", "g");
	
	static var rxHasHint = new RegExp("///\\s+@hint");
	
	/** `var a:T`, `#args a:T`, `var a, b:T` */
	private static var rxHasTypePost = new RegExp("(?:" + [
		"(?:var|let|const)\\s+",
		"#args\\s+",
		",\\s*",
		"\\(\\s*",
	].join("|") + ")\\w+:");
	
	/** Ditto but accounting for `/*:Type` */
	private static var rxHasTypePre = new RegExp("(?:" + [
		"(?:var|let|const)\\s+",
		"#args\\s+", // shouldn't be needed tbh
		",\\s*",
		"\\(\\s*",
	].join("|") + ")\\w+"
		+ "(?:/\\*)?" // opt: comment start
	+ ":");
	
	public static var errorText:String;
	//
	static function parseRules(imp:GmlImports, mt:Array<String>, out:GmlExtImportRules) {
		var path = mt[1];
		var alias = mt[2];
		var nsOnly = mt[3] == ":";
		var flat:String;
		var flen:Int;
		var short:String;
		var check:Dictionary<String>->AceAutoCompleteItems->Void;
		var errors = "";
		//
		var add_cache:GmlImportsCache;
		inline function add(long:String, short:String, kind:String, comp:AceAutoCompleteItem,
			doc:GmlFuncDoc, ?space:String, ?spaceOnly:Bool
		):Void {
			if (out != null) {
				add_cache = {};
				out.push(Import(long, short, kind, comp, doc, space, spaceOnly, add_cache));
			} else add_cache = null;
			imp.add(long, short, kind, comp, doc, space, spaceOnly, add_cache);
		}
		if (path == "_") {
			var field = mt[4];
			if (field != null) {
				var comp = new AceAutoCompleteItem(field, "field");
				var ns = alias;
				if (out != null) {
					add_cache = {};
					out.push(FieldHint(field, comp, null, ns, nsOnly, add_cache));
				} else add_cache = null;
				imp.addFieldHint(field, comp, null, ns, nsOnly, add_cache);
			} else if (alias != null) {
				imp.ensureNamespace(alias);
				if (out != null) out.push(EnsureNS(alias));
			}
		}
		else if (path.endsWith("*")) { // #import pkg.*
			flat = path.substring(0, path.length - 1).replaceExt(rxPeriod, "_");
			flen = flat.length;
			function check(
				kind:Dictionary<String>, autoCompleteItems:AceAutoCompleteItems, docs:Dictionary<GmlFuncDoc>
			) {
				kind.forField(function(fd) {
					if (fd.startsWith(flat) && fd != flat) {
						var autoCompleteItem:AceAutoCompleteItem = null;
						for (item in autoCompleteItems) if (item.name == fd) {
							autoCompleteItem = item;
							break;
						}
						short = fd.substring(flen);
						add(fd, short, kind[fd], autoCompleteItem, docs[fd], alias, nsOnly);
					}
				});
			}
			check(GmlAPI.stdKind, GmlAPI.stdComp, GmlAPI.stdDoc);
			check(GmlAPI.extKind, GmlAPI.extComp, GmlAPI.extDoc);
			check(GmlAPI.gmlKind, GmlAPI.gmlComp, GmlAPI.gmlDoc);
		}
		else if (path.startsWith("global.")) { // #import global.fd
			flat = path.substring(7);
			var ns:String = null;
			if (alias == null) {
				alias = flat;
			} else if (mt[3] != null) {
				ns = alias;
				alias = mt[3];
			}
			var comp = new AceAutoCompleteItem(path, "global");
			add(path, alias, "globalfield", comp, null, ns);
		}
		else { // #import ident
			flat = path.replaceExt(rxPeriod, "_");
			var ns:String = null;
			if (alias == null) {
				var p = path.lastIndexOf(".");
				if (p < 0) return;
				alias = flat.substring(p + 1);
			} else if (mt[4] != null) {
				ns = alias;
				alias = mt[4];
			}
			function check(
				kind:Dictionary<String>, comp:AceAutoCompleteItems, docs:Dictionary<GmlFuncDoc>
			) {
				var fdk = kind[flat];
				if (fdk == null) return false;
				var comps = comp.filter(function(comp) {
					return comp.name == flat;
				});
				add(flat, alias, fdk, comps[0], docs[flat], ns, nsOnly);
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
		imp:GmlImports, rel:String, found:Dictionary<Bool>, cache:GmlExtImportRuleCache
	) {
		var fp = Path.withoutExtension(rel.toLowerCase());
		if (found[fp]) return true; // (we've seen this one already)
		//
		var rules:GmlExtImportRules;
		if (cache != null) {
			rules = cache[rel];
			if (rules != null) {
				for (rule in rules) switch (rule) {
					case EnsureNS(s): imp.ensureNamespace(s);
					case Import(long, short, kind, comp, doc, space, spaceOnly, cache): {
						imp.add(long, short, kind, comp, doc, space, spaceOnly, cache);
					};
					case FieldHint(field, comp, doc, space, isInst, cache): {
						imp.addFieldHint(field, comp, doc, space, isInst, cache);
					};
				}
				return true;
			} else {
				rules = [];
				cache.set(rel, rules);
			}
		} else rules = null;
		//Main.console.log("parse", rel);
		//
		var full = Path.join([Project.current.dir, "#import", rel]);
		if (!FileWrap.existsSync(full)) {
			full += ".gml";
			if (!FileWrap.existsSync(full)) return false;
		}
		var code = FileWrap.readTextFileSync(full);
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
						if (q.get(p + 2) == "/".code) {
							var i = p + 3;
							while (q.get(i).isSpace0()) i++;
							if (q.get(i) == "@".code
								&& q.substring(i + 1, i + 5) == "hint"
								&& !q.get(i + 5).isIdent1_ni()
							) {
								var txt = q.substring(i + 5, q.pos);
								parseHint(imp, txt, found, cache, null);
							}
						}
						else if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "import") {
							var txt = q.substring(p + 3, q.pos);
							parseLine(imp, txt, found, cache, rules);
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
	
	/**
	 * Takes an "#import ..." string and parses it, adding rules
	 */
	static function parseLine(
		imp:GmlImports, txt:String, found:Dictionary<Bool>,
		cache:GmlExtImportRuleCache, rules:GmlExtImportRules
	) {
		var mt = rxImport.exec(txt);
		if (mt != null) {
			parseRules(imp, mt, rules);
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
	
	static var parseHint_rx:RegExp = new RegExp("^\\s+"
		+ "(\\w+)([.:])(\\w+)" // Class.staticField, Class:instField
		+ "(\\(.*?\\)\\S*)?" // $4 -> function arguments, if any
		+ "(?:\\s+)?" // $5 -> rest
	+ "");
	static function parseHint(
		imp:GmlImports, txt:String, found:Dictionary<Bool>,
		cache:GmlExtImportRuleCache, rules:GmlExtImportRules
	) {
		var mt = parseHint_rx.exec(txt);
		if (mt != null) {
			var ns = mt[1];
			var isInst = mt[2] == ":";
			var field = mt[3];
			var args = mt[4];
			var info = mt[5];
			//
			var doc:GmlFuncDoc = null;
			if (args != null) {
				args = GmlFuncDoc.patchArrow(args);
				var fa = field + args;
				doc = GmlFuncDoc.parse(fa);
				info = NativeString.nzcct(fa, "\n", info);
			}
			var comp = new AceAutoCompleteItem(field, "field", info);
			var add_cache:GmlImportsCache;
			if (rules != null) {
				add_cache = {};
				rules.push(FieldHint(field, comp, doc, ns, isInst, add_cache));
			} else add_cache = null;
			imp.addFieldHint(field, comp, doc, ns, isInst, add_cache);
			//
			return true;
		}
		return false;
	}
	
	/** `var v:Enum`, "v[Enum.field]" -> "v.field" */
	static function pre_mapIdent_local(q:GmlReader, imp:GmlImports, ident:String, typeName:String, p0:Int):String {
		var ns = imp.namespaces[typeName];
		var e:GmlEnum;
		if (ns == null) {
			e = GmlAPI.gmlEnums[typeName];
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
			if (index1 != typeName) return null; // must be <enum name>
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
		var tn = t.getNamespace();
		if (tn != null) {
			next = pre_mapIdent_local(q, imp, ident, tn, p0);
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
				if (selfType == null) { // array_create(Enum.sizeof) -> Enum()
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
					//
					return tools.JsTools.or(imp.shorten[selfEnumName], selfEnumName) + "()";
				}
				var stn = selfType.getNamespace();
				if (stn == null) break;
				var selfNs = imp.namespaces[stn];
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
	static var pre_needsCache:RegExp = new RegExp("\n#(?:define|event|moment|target)\\b");
	public static function pre(code:GmlCode, path:String):GmlCode {
		var seekData = GmlSeekData.map[path];
		inline function cancel() {
			if (seekData != null) seekData.imports = null;
			return code;
		}
		if (!Preferences.current.importMagic) return cancel();
		var globalPath = Path.join([Project.current.dir, "#import", "global.gml"]);
		var globalExists = FileSystem.canSync && FileWrap.existsSync(globalPath);
		if (code.indexOf("//!#import") < 0
			&& !rxHasTypePre.test(code)
			&& !globalExists
			&& !rxHasHint.test(code)
		) return cancel();
		var needsCache = pre_needsCache.test(code);
		var cache:GmlExtImportRuleCache = needsCache ? new Dictionary() : null;
		var version = GmlAPI.version;
		var q = new GmlReader(code);
		var out = "";
		var start = 0;
		inline function flush(till:Int) {
			out += q.substring(start, till);
		}
		//
		var imp = new GmlImports();
		var cubDepth = 0;
		var imps = new Dictionary<GmlImports>();
		var files = new Dictionary<Bool>();
		if (globalExists) parseFile(imp, "global.gml", files, cache);
		imps.set("", imp);
		//
		var canFn = version.hasFunctionLiterals();
		function procFunc(isTopLevel:Bool):Void {
			q.skipSpaces1();
			var c = q.peek();
			var p:Int;
			if (c.isIdent0()) {
				p = q.pos;
				q.skipIdent1();
				if (isTopLevel) {
					var fname = q.substring(p, q.pos);
					imp = new GmlImports();
					imps.set(fname, imp);
					files = new Dictionary();
					if (globalExists) parseFile(imp, "global.gml", files, cache);
					q.skipSpaces1_local();
					c = q.peek();
				}
			}
			if (c == "(".code) {
				q.skip();
				var argName:String = null;
				while (q.loop) {
					c = q.read();
					switch (c) {
						case ")".code:
							q.skipSpaces1_local();
							if (q.substr(q.pos, 4) == "/*->") {
								var tcStart = q.pos;
								q.skipComment();
								if (q.substr(q.pos - 2, 2) == "*/") {
									flush(tcStart);
									out += q.substring(tcStart + 2, q.pos - 2);
									start = q.pos;
								}
							}
							break;
						case "/".code: switch (q.peek()) {
							case "/".code: q.skipLine();
							case "*".code: {
								q.skip();
								p = q.peek() == ":".code ? q.pos + 1 : -1;
								q.skipComment();
								if (p < 0 || argName == null) continue;
								var cmtEnd = q.pos;
								q.pos = p;
								q.skipType();
								q.skipSpaces1x(cmtEnd);
								if (q.pos == cmtEnd - 2) {
									var typeStr = q.substring(p, cmtEnd - 2);
									var type = GmlTypeDef.parse(typeStr);
									if (type != null) {
										flush(p - 3);
										out += ":" + typeStr;
										imp.localTypes[argName] = type;
										start = cmtEnd;
									}
								}
								q.pos = cmtEnd;
							}
							default:
						};
						case '"'.code, "'".code, "`".code, "@".code: {
							q.skipStringAuto(c, version);
						};
						case ",".code: argName = null;
						case _ if (c.isIdent0()): {
							p = q.pos - 1;
							q.skipIdent1();
							argName = q.substring(p, q.pos);
						}
						default:
					}
				} // while (q.loop), can continue
			}
		}
		//
		while (q.loop) {
			var p = q.pos;
			var c = q.read();
			switch (c) {
				case "/".code: switch (q.peek()) {
					case "/".code: {
						q.skipLine();
						if (q.get(p + 2) == "/".code) {
							var i = p + 3;
							while (q.get(i).isSpace0()) i++;
							if (q.get(i) == "@".code
								&& q.substring(i + 1, i + 5) == "hint"
								&& !q.get(i + 5).isIdent1_ni()
							) {
								var txt = q.substring(i + 5, q.pos);
								parseHint(imp, txt, files, cache, null);
							}
						}
						else if (q.get(p + 2) == "!".code
						&& q.get(p + 3) == "#".code
						&& q.substr(p + 4, 6) == "import") {
							var txt = q.substring(p + 3, q.pos);
							if (parseLine(imp, txt, files, cache, null)) {
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
				case "{".code: cubDepth++;
				case "}".code: cubDepth--;
				default: {
					if (c.isIdent0()) {
						q.skipIdent1();
						var p1 = q.pos;
						var ident = q.substring(p, p1);
						var next:String = null;
						if (canFn && ident == "function") {
							procFunc(cubDepth == 0);
							continue;
						}
						//
						var mcr = GmlAPI.gmlMacros[ident];
						if (mcr != null && mcr.expr == "var") ident = "var";
						//
						if (ident == "var"
							|| ident == "args" && q.get(p - 1) == "#".code
						) {
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
								if (d.typeStr != null) {
									imp.localTypes.set(d.name, d.type);
									var tn = d.type.getNamespace();
									if (imp.kind[tn] == "enum") {
										// convert enum to namespace if used as one
										imp.ensureNamespace(tn);
									}
									out += ":" + d.typeStr;
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
										case "{".code: cubDepth++;
										case "}".code: cubDepth--;
										case '"'.code, "'".code, "`".code, "@".code: {
											q.skipStringAuto(c, version);
										};
										default: if (c.isIdent0()) {
											q.skipIdent1();
											var id = q.substring(p0, q.pos);
											if (canFn && id == "function") {
												procFunc(cubDepth == 0);
											} else {
												var idn = pre_mapIdent(imp, q, id, p0);
												if (idn != null) {
													flush(p0);
													out += idn;
													start = q.pos;
												}
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
		if (seekData == null && version.config.indexingMode == Local) {
			seekData = new GmlSeekData(null);
			GmlSeekData.map.set(path, seekData);
		}
		if (seekData != null) seekData.imports = imps;
		return out;
	}
	
	public static var post_numImports = 0;
	static var post_procIdent_p1:Int = 0;
	static var post_procIdent_peeker:GmlReaderExt = new GmlReaderExt("", gml.GmlVersion.none);
	/**
	 * @param	reader
	 * @param	imp
	 * @param	p0	`¦Type.field`
	 * @param	dot	`Type¦.field` (-1 if none)
	 * @param	full "Type.field"
	 */
	static function post_procIdent(reader:GmlReaderExt, imp:GmlImports, p0:Int, dot:Int, full:String) {
		var p1 = reader.pos; // `Type.field¦`
		var one:String = dot != -1 ? reader.substring(p0, dot) : null;
		var peeker = post_procIdent_peeker;
		var onePrefix = "";
		
		// `new Type` -> `Type.create`:
		if (full == "new") {
			peeker.setTo(reader);
			peeker.skipSpaces1();
			var typePos = peeker.pos;
			var typeFirst = peeker.read();
			if (typeFirst.isIdent0()) { // `new T¦ype`
				peeker.skipIdent1();
				one = peeker.substring(typePos, peeker.pos); // -> "Type"
				onePrefix = peeker.substring(p0, typePos);
				reader.setTo(peeker);
				full = one + ".create";
				dot = reader.pos;
				p1 = reader.pos;
			}
		}
		
		// `typedVar.method(...)` -> `func(typedVar, ...)`,
		// `typedVar.field` -> `typedVar[fieldId]`:
		var type = dot != -1 ? imp.localTypes[one] : null;
		var tn = type.getNamespace();
		if (tn != null) {
			var ns = imp.namespaces[tn], en:GmlEnum;
			var ind:String = null;
			var fd = reader.substring(dot + 1, p1);
			if (ns != null) {
				ind = ns.longen[fd];
				en = null;
			} else {
				en = GmlAPI.gmlEnums[tn];
				if (en != null && en.items.exists(fd)) ind = tn + '.' + fd;
			}
			//
			if (ind != null) {
				peeker.setTo(reader);
				peeker.skipSpaces1();
				if (peeker.read() == "(".code) {
					reader.setTo(peeker);
					peeker.skipSpaces0();
					var argPre = peeker.peek() != ")".code ? ", " : "";
					post_procIdent_p1 = reader.pos;
					return ind + "(" + one + argPre;
				} else { // `typedVar.field`
					post_procIdent_p1 = p1;
					return one + (reader.checkWrites(p0, p1) ? '[@' : '[') + ind + ']';
				}
			}
			else if (en != null || ns != null && ns.isSealed) {
				if (errorText != "") errorText += "\n";
				errorText += reader.getPos(dot + 1).toString() + ' Could not find field $fd in '
					+ (ns != null ? 'namespace' : en != null ? 'enum' : 'unknown type')
					+ ' ' + tn + '.';
				return null;
			}
		}
		
		// `Enum()` -> `array_create(Enum.lastItem)`:
		var id = imp.longen[full];
		var en = dot == -1 ? GmlAPI.gmlEnums[tools.JsTools.or(id, full)] : null;
		if (en != null) do {
			peeker.setTo(reader);
			peeker.skipSpaces1();
			if (peeker.read() != "(".code) break;
			peeker.skipSpaces1();
			if (peeker.read() != ")".code) break;
			reader.setTo(peeker);
			post_procIdent_p1 = reader.pos;
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
				return onePrefix + id;
			}
		}
		return null;
	}
	public static function post(code:GmlCode, path:String):GmlCode {
		errorText = "";
		if (!Preferences.current.importMagic) {
			post_numImports = 0;
			return code;
		}
		var version = GmlAPI.version;
		var q = new GmlReaderExt(code);
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
		var mayHaveType = imps != null || rxHasTypePost.test(code);
		if (imp == null && mayHaveType) imp = new GmlImports();
		var cubDepth = 0;
		//
		var canFunc = version.hasFunctionLiterals();
		function procFunc(isTopLevel:Bool):Void {
			q.skipSpaces1_local();
			var c = q.peek();
			
			if (c.isIdent0()) { // function <name>
				var nameStart = q.pos;
				q.skipIdent1();
				
				if (isTopLevel) {
					var name = q.substring(nameStart, q.pos);
					imp = imps != null ? imps[name] : null;
					if (imp == null && mayHaveType) imp = new GmlImports();
				}
				
				q.skipSpaces1_local();
				c = q.peek();
			}
			
			if (c == "(".code) while (q.loopLocal) {
				c = q.read();
				switch (c) {
					case ")".code:
						q.skipSpaces1_local();
						if (q.substr(q.pos, 2) == "->") {
							var tsStart = q.pos;
							q.pos += 2;
							if (q.skipType()) {
								flush(tsStart);
								out += "/*" + q.substring(tsStart, q.pos) + "*/";
								start = q.pos;
							} else q.pos = tsStart;
						}
						break;
					case "/".code: switch (q.peek()) {
						case "/".code: q.skipLine();
						case "*".code: q.skip(); q.skipComment();
						default:
					};
					case '"'.code, "'".code, "`".code, "@".code:
						q.skipStringAuto(c, version);
					case ":".code:
						var tp = q.pos - 1;
						if (!q.skipType()) continue;
						flush(tp);
						out += "/*" + q.substring(tp, q.pos) + "*/";
						start = q.pos;
				}
			}
		}
		//
		var dotStart:Int, dotPos:Int, dotFull:String;
		function readDotPair() {
			dotStart = q.pos;
			dotPos = -1;
			while (q.loop) {
				var c = q.peek();
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
				case "{".code: cubDepth++;
				case "}".code: cubDepth--;
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
							if (imp == null && mayHaveType) imp = new GmlImports();
						} else q.pos = p + 1;
					};
				};
				case _ if (c.isIdent0() && imp != null): {
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
					if (canFunc && dotFull == "function") {
						procFunc(cubDepth == 0);
						continue;
					}
					//
					var mcr = GmlAPI.gmlMacros[dotFull];
					if (mcr != null && mcr.expr == "var") dotFull = "var";
					//
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
							if (d.typeStr != null) {
								out += isVar ? "/*:" + d.typeStr + "*/" : ":" + d.typeStr;
								impc += 1;
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
									case "{".code: cubDepth++;
									case "}".code: cubDepth--;
									default: if (c.isIdent0()) {
										q.pos -= 1;
										readDotPair();
										if (dotFull == "function" && canFunc) {
											procFunc(cubDepth == 0);
										} else procIdent();
									};
								}
							}
							q.pos = p;
						}, version, !isVar);
					} else procIdent();
					if (errorText != "") return null;
				};
				default:
			} // switch
		} // loop
		post_numImports = impc;
		flush(q.pos);
		return out;
	}
}
private enum GmlExtImportRule {
	EnsureNS(name:String);
	Import(long:String, short:String, kind:String, comp:AceAutoCompleteItem,
		doc:GmlFuncDoc, space:String, spaceOnly:Bool, cache:GmlImportsCache);
	FieldHint(field:String, comp:AceAutoCompleteItem, doc:GmlFuncDoc,
		space:String, isInst:Bool, cache:GmlImportsCache);
}
private typedef GmlExtImportRules = Array<GmlExtImportRule>;
private typedef GmlExtImportRuleCache = Dictionary<GmlExtImportRules>;

class GmlExtImportWrap extends SyntaxExtension {
	public function new() {
		super("#import", "#import magic");
	}
	override public function check(editor:EditCode, code:String):Bool {
		return editor.file.path != null && (cast editor.kind:file.kind.KGml).canImport;
	}
	override public function preproc(editor:EditCode, code:String):String {
		code = GmlExtImport.pre(code, editor.file.path);
		if (code == null) message = GmlExtImport.errorText;
		return code;
	}
	override public function postproc(editor:EditCode, code:String):String {
		var pair = editor.postpImport(code);
		if (pair == null) return null;
		code = pair.val;
		if (pair.sessionChanged) {
			(cast editor.kind:KGml).saveSessionChanged = true;
		}
		return code;
	}
}