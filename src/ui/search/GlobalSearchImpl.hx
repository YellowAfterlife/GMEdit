package ui.search;
import ace.extern.AcePos;
import file.kind.gml.KGmlSearchResults;
import gml.file.GmlFile;
import tools.GmlCodeTools;
import tools.JsTools;
import ui.GlobalSearch;
import ui.search.GlobalSeachData;
import gml.GmlVersion;
import gml.Project;
import parsers.GmlReader;
import synext.GmlExtLambda;
import haxe.Constraints.Function;
import js.lib.RegExp;
import js.Syntax;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GlobalSearchImpl {
	public static function offsetToPos(code:String, till:Int, rowStart:Int):AcePos {
		var pos:Int;
		if (till < rowStart) {
			pos = code.lastIndexOf("\n", till);
			return { column: till - (pos + 1), row: -1 };
		}
		var row = 0;
		pos = code.indexOf("\n", rowStart);
		while (pos <= till && pos >= 0) {
			row += 1;
			rowStart = pos + 1;
			pos = code.indexOf("\n", rowStart);
		}
		return { column: till - rowStart, row: row };
	}
	
	public static function run(opt:GlobalSearchOpt, ?finish:Void->Void) {
		var pj = Project.current;
		var version = pj.version;
		if (version == GmlVersion.none) return;
		var showPaths = version.config.searchMode == "directory";
		var term:String, rx:RegExp;
		if (Std.is(opt.find, RegExp)) {
			rx = opt.find;
			if (!rx.global) {
				Main.console.warn("This is not a /g regexp and you are potentially in trouble.");
			}
			term = rx.toString();
		} else {
			term = opt.find;
			var eterm = NativeString.escapeRx(term);
			var eopt:String = opt.matchCase ? "g" : "ig";
			if (opt.wholeWord) {
				if (JsTools.rx(~/^\/\//).test(term)) {
					eterm += "$";
					eopt += "m";
				} else {
					if (JsTools.rx(~/^\w/).test(term)) eterm = "\\b" + eterm;
					if (JsTools.rx(~/\w$/).test(term)) eterm = eterm + "\\b";
				}
			}
			rx = new RegExp(eterm, eopt);
		}
		if (term == "") return;
		var results = "";
		var found = 0;
		var checkRefKind = opt.checkRefKind;
		var repl:Dynamic = opt.replaceBy;
		var filterFn:Function = opt.findFilter;
		var lineFilter = opt.lineFilter;
		var ctxFilter = opt.headerFilter;
		var ctxFilterFn:GlobalSearchCtxFilter = Syntax.typeof(ctxFilter) == "function" ? ctxFilter : null;
		var ctxFilterRx:RegExp = Std.is(ctxFilter, RegExp) ? ctxFilter : null;
		var allowDotPrefix:Bool = !opt.noDotPrefix;
		var isRepl = repl != null;
		var isReplFn = Syntax.typeof(repl) == "function";
		var isPrev = opt.previewReplace;
		var saveData = new GlobalSeachData(opt);
		var saveItems = saveData.list;
		var saveItem:GlobalSearchItem;
		var saveCtxItems:Array<GlobalSearchItem>;
		var canLambda = pj.canLambda() && opt.expandLambdas;
		var lambdaGml:String = null;
		pj.search(function(name:String, path:String, code:String) {
			var lambdaPre:GmlExtLambdaPre;
			if (canLambda) {
				lambdaPre = GmlExtLambda.preInit(pj);
				lambdaPre.gml = lambdaGml;
				code = GmlExtLambda.preImpl(code, lambdaPre);
				lambdaGml = lambdaPre.gml;
			} else lambdaPre = null;
			GlobalSearch.currentPath = path;
			var q = new GmlReader(code);
			var qSqb:GmlReader = null;
			var start = 0;
			var row = 0;
			var ctxName = name;
			saveCtxItems = [];
			saveData.map.set(ctxName, saveCtxItems);
			var ctxStart = 0;
			var ctxCheck:Bool;
			inline function ctxCheckProc(s:String):Void {
				if (ctxFilterFn != null) {
					ctxCheck = ctxFilterFn(s, path);
				} else if (ctxFilterRx != null) {
					ctxCheck = ctxFilterRx.test(s);
				} else ctxCheck = true;
			}
			ctxCheckProc(name);
			var ctxLast = null;
			var out = isRepl ? "" : null;
			var replStart = 0;
			function flush(till:Int) {
				if (!ctxCheck) return;
				var subc:String = q.substring(start, till);
				var mt = rx.exec(subc);
				while (mt != null) {
					var ofs = start + mt.index;
					var eol = code.indexOf("\n", ofs);
					if (eol >= 0) {
						if (StringTools.fastCodeAt(code, eol - 1) == "\r".code) eol -= 1;
					} else eol = code.length;
					var pos = offsetToPos(code, ofs, ctxStart);
					var sol = ofs - pos.column;
					var line = code.substring(sol, eol);
					var ctxLink = ctxName;
					if (showPaths) ctxLink = path + "(" + ctxLink + ")";
					/*if (pos.row >= 0) */ctxLink += ":" + (pos.row + 1);
					if (isRepl || ctxLink != ctxLast) {
						// todo: show multiple changes on the same line combined
						var curr:Dynamic = mt.length > 1 ? mt : mt[0];
						if ((allowDotPrefix || !GmlCodeTools.isDotAccessBacktrack(code, ofs))
							&& (filterFn == null || filterFn(curr))
							&& (lineFilter == null || lineFilter(line))
						) {
							saveItem = { row: pos.row, code: line, next: null };
							saveItems.push(saveItem);
							saveCtxItems.push(saveItem);
							ctxLast = ctxLink;
							var head = '\n\n// in @[$ctxLink]';
							if (checkRefKind) {
								var mtEnd = ofs + mt[0].length;
								if (NativeString.endsWith(ctxName, "(properties)")) {
									head += " (properties)";
								} else if (NativeString.startsWith(line, "#event collision:")) {
									head += " (collision)";
								} else {
									var rk = GmlCodeTools.getReferenceKind(q.source, ofs, mtEnd);
									head += " (" + rk.toFullString() + ")";
								}
							}
							head += ':\n' + line;
							if (isRepl) {
								var next:String;
								if (isReplFn) {
									next = repl(curr, {
										ctx: ctxName,
										row: pos.row,
									});
								} else if (mt.length > 1) {
									var li = rx.lastIndex;
									next = NativeString.replaceExt(mt[0], rx, repl);
									rx.lastIndex = li;
								} else next = repl;
								out += q.substring(replStart, ofs) + next;
								replStart = ofs + mt[0].length;
								if (mt[0] != next) {
									results += head + "\n" + code.substring(sol, ofs)
										+ next + code.substring(replStart, eol);
								}
							} else results += head;
							found += 1;
						}
					}
					mt = rx.exec(subc);
				}
			}
			while (q.loop) {
				var p = q.pos;
				var c = q.read();
				var p1:Int;
				switch (c) {
					case "/".code: {
						if (!opt.checkComments) switch (q.peek()) {
							case "/".code: {
								flush(p);
								q.skipLine();
								start = q.pos;
							};
							case "*".code: {
								flush(p);
								q.skip(); q.skipComment();
								start = q.pos;
							};
						}
					};
					case '"'.code, "'".code, "@".code, "`".code: {
						if (!opt.checkStrings) {
							q.skipStringAuto(c, version);
							if (q.pos > p + 1) {
								flush(p);
								start = q.pos;
							}
						}
					};
					case "#".code: if (p == 0 || q.get(p - 1) == "\n".code) {
						if (q.substr(p, 6) == "#macro") {
							if (!opt.checkMacros) {
								q.skipLine();
								q.skipLineEnd();
								start = q.pos;
							}
						} else {
							var ctxNameNext = q.readContextName(name);
							if (ctxNameNext == null) continue;
							flush(p);
							ctxName = ctxNameNext;
							q.skipLine(); q.skipLineEnd();
							ctxStart = q.pos;
							ctxCheckProc(ctxName);
							saveCtxItems = [];
							if (opt.checkHeaders) {
								start = p;
								flush(q.pos);
							}
							saveData.map.set(ctxName, saveCtxItems);
							start = q.pos;
						}
					};
				}
			}
			flush(q.pos);
			if (isRepl) {
				out += q.substring(replStart, q.length);
				var hasLambda = canLambda && !isPrev && GmlExtLambda.hasHashLambda(out);
				if (canLambda && !isPrev && (hasLambda || lambdaPre.list.length > 0)) {
					var lambdaPost = GmlExtLambda.postInit(name, pj, lambdaPre.list, lambdaPre.map);
					out = GmlExtLambda.postImpl(out, lambdaPost);
					if (out == null) {
						var e = "Failed to update #lambda in " + name + ": " + GmlExtLambda.errorText;
						opt.errors = (opt.errors == null ? e : opt.errors + "\n" + e);
					}
				}
			}
			return isRepl && !isPrev ? out : null;
		}, function() {
			if (finish != null) finish();
			var name:String;
			if (checkRefKind) {
				name = "references";
			} else if (!isRepl) {
				name = "search";
			} else if (isPrev) {
				name = "preview";
			} else {
				name = "replace";
			}
			name += ": " + term;
			var head = '// ' + found + ' result';
			if (found != 1) head += "s";
			if (isRepl) {
				if (isPrev) {
					head += " would be replaced";
				} else head += " replaced";
			} else head += " found";
			results = head + ":" + results;
			//
			if (opt.results != null && NativeString.trimRight(opt.results) != "") {
				results = opt.results + "\n" + results;
			}
			//
			if (opt.errors != null) {
				results = "/* Errors:\n" + opt.errors + "\n*/\n" + results;
			}
			//
			var file = new GmlFile(name, null, KGmlSearchResults.inst, results);
			if (!isRepl) file.searchData = saveData;
			GmlFile.openTab(file);
			Main.window.setTimeout(function() {
				Main.aceEditor.focus();
			});
		}, opt);
	}
}