package ui;
import ace.AceTooltips;
import gml.GmlFuncDoc;
import ace.AceStatusBar;
import ace.AceWrap;
import ace.extern.*;
import js.lib.RegExp;
import gml.file.*;
import gml.file.GmlFile;
import file.kind.gml.KGmlScript;
import file.kind.gmx.*;
import file.kind.yy.*;
import electron.FileWrap;
import electron.Shell;
import haxe.io.Path;
import gml.GmlAPI;
import gml.GmlImports;
import ui.ColorPicker;
import ui.treeview.TreeView;
using tools.NativeString;
using tools.HtmlTools;
using StringTools;
import Main.aceEditor;
import gml.Project;

/**
 * Handles logic for middle-clicking identifiers or pressing F1 when your cursor is at one.
 * @author YellowAfterlife
 */
class OpenDeclaration {
	public static function openLink(meta:String, pos:AcePos) {
		// name(def):ctx
		var rx:RegExp = new RegExp("^(.+?)" // -> name
			+ "(?:\\(([^)]*)\\))?" // -> (definition)
			+ "(?::(.+))?$" // -> line/context
		);
		var vals = rx.exec(meta);
		if (vals == null) return false;
		var name = vals[1];
		var def = vals[2];
		var ctx = vals[3];
		var nav:GmlFileNav = { def: def };
		if (ctx != null) {
			var rs = "(\\d+)(?:(\\d+))?";
			rx = new RegExp("^" + rs + "$");
			vals = rx.exec(ctx);
			var ctxRow = null, ctxCol = null;
			if (vals == null) {
				rx = new RegExp("^([^:]+):" + rs + "$");
				vals = rx.exec(ctx);
				if (vals != null) {
					nav.ctx = vals[1];
					ctxRow = vals[2];
					ctxCol = vals[3];
				} else nav.ctx = ctx;
			} else {
				ctxRow = vals[1];
				ctxCol = vals[2];
			}
			if (ctxRow != null) nav.pos = {
				row: Std.parseInt(ctxRow) - 1,
				column: ctxCol != null ? Std.parseInt(ctxCol) - 1 : 0
			};
		}
		openLocal(name, pos, nav);
		return true;
	}
	
	public static function openLookup(lookup:GmlLookup, ?nav:GmlFileNav) {
		if (lookup == null) return false;
		var path = lookup.path;
		var name:String;
		var treeEl = TreeView.find(true, { path: path });
		if (treeEl != null) {
			name = treeEl.title;
		} else {
			// not part of the project, but maybe it's an open tab?
			name = null;
			for (tabEl in ui.ChromeTabs.element.querySelectorEls('.chrome-tab')) {
				var gmlFile:GmlFile = untyped tabEl.gmlFile;
				if (gmlFile != null && gmlFile.path == path) {
					name = gmlFile.name;
					break;
				}
			}
			if (name == null) return false;
		}
		
		var navMode = 0;
		if (nav != null) {
			if (nav.def == null) nav.def = lookup.sub;
			if (nav.pos != null) {
				navMode = 1;
				nav.pos.row += lookup.row;
				nav.pos.column += lookup.col;
			} else {
				nav.pos = { row: lookup.row, column: lookup.col };
				navMode = 2;
			}
		}; else nav = {
			def: lookup.sub,
			pos: { row: lookup.row, column: lookup.col }
		};
		GmlFile.open(name, path, nav);
		switch (navMode) {
			case 1:
				nav.pos.row -= lookup.row;
				nav.pos.column -= lookup.col;
			case 2:
				js.Syntax.delete(nav, "pos");
		}
		return true;
	}
	
	public static function openLocal(name:String, pos:AcePos, ?nav:GmlFileNav):Bool {
		if (openLookup(GmlAPI.gmlLookup[name], nav)) return true;
		//
		var ename = tools.NativeString.escapeProp(name);
		var el = TreeView.element.querySelector('.item[${TreeView.attrIdent}="$ename"]');
		if (el != null) {
			if (Project.current.path == "") {
				TreeView.openProject(el);
			} else {
				GmlFile.open(el.title, el.getAttribute(TreeView.attrPath), nav);
			}
			return true;
		}
		//
		return false;
	}
	
	public static function openImportFile(rel:String) {
		var dir = "#import";
		if (!FileWrap.existsSync(dir)) {
			FileWrap.mkdirSync(dir);
		}
		var pj = Project.current;
		var full = Path.join([dir, rel]);
		var data = null;
		if (!pj.existsSync(full)) {
			full += ".gml";
			if (!pj.existsSync(full)) data = "";
		}
		if (data == null) data = pj.readTextFileSync(full);
		var name = Path.withoutDirectory(full);
		var file = new GmlFile(name, pj.fullPath(full), file.kind.gml.KGmlImports.inst, data);
		GmlFile.openTab(file);
		return true;
	}
	
	public static function proc(session:AceSession, pos:AcePos, token:AceToken) {
		if (token == null) return false;
		var term = token.value;
		// opening #import "<path>":
		if (token.type.isImportPath()) {
			if (openImportFile(term.substring(1, term.length - 1))) return true;
		}
		// color picker for hex colors:
		if (token.type == "numeric" && ColorPicker.rxGml.test(term)) {
			ColorPicker.open(term);
			return true;
		}
		// @[links] in comments:
		if (term.substring(0, 2) == "@[") {
			var rx = new RegExp("^@\\[(.*)\\]");
			var vals = rx.exec(term);
			if (vals != null) openLink(vals[1], pos);
			return true;
		}
		// `http[s]://` links in comments:
		if (token.type.contains("link.url")) {
			Shell.openExternal(term);
		}
		//
		var scope = session.gmlScopes.get(pos.row);
		// parent event navigation overrides early:
		if (term == "event_inherited" || term == "action_inherited") {
			if (scope == "") return false;
			var file = session.gmlFile;
			var path = file.path;
			#if !gmedit.no_gmx
			if (Std.is(file.kind, KGmxEvents)) {
				return gmx.GmxObject.openEventInherited(path, scope) != null;
			} else // ->
			#end
			if (Std.is(file.kind, KYyEvents)) {
				return yy.YyObject.openEventInherited(path, scope) != null;
			} else return false;
			return true;
		}
		// handle namespace.term | localTyped.term:
		do {
			if (scope == null) break;
			var imp = session.gmlFile.codeEditor.imports[scope];
			if (imp == null) break;
			//
			var iter = new AceTokenIterator(session, pos.row, pos.column);
			var tk = iter.stepBackward();
			var next:String, ns:GmlImportNamespace;
			if (tk != null && tk.value == ".") {
				tk = iter.stepBackward();
				if (tk != null) switch (tk.type) {
					case "enum": {
						var en = GmlAPI.gmlEnums[tk.value];
						if (en == null) break;
						return openLookup(en.fieldLookup[term], {
							ctx:term,
							pos:new AcePos(0, 0),
							ctxAfter:true,
						});
					};
					case "namespace": {
						ns = imp.namespaces[tk.value];
						if (ns == null) break;
						next = ns.longen[term];
						if (next != null) term = next;
						break;
					};
					case "local", "sublocal": {
						var t = imp.localTypes[tk.value];
						var tn = t.getNamespace();
						if (tn == null) break;
						ns = imp.namespaces[tn];
						if (ns == null) break;
						next = ns.longen[term];
						if (next != null) term = next;
						break;
					};
				}
			}
			//
			next = imp.longen[term];
			if (next != null) term = next;
		} while (false);
		//
		if (openLocal(term, pos, null)) return true;
		// try to do the sort of resolution that we do in AceTooltips
		var doc = AceTooltips.getDocAt(session, pos, token);
		if (doc != null && doc.lookup != null) {
			return openLookup(doc.lookup, doc.nav);
		}
		//
		var helpURL = GmlAPI.helpURL;
		if (helpURL != null) {
			var helpLookup = GmlAPI.helpLookup;
			if (helpLookup != null) {
				var helpTerm = helpLookup[term];
				if (helpTerm == null) {
					var gbTerm = StringTools.replace(term, "color", "colour");
					helpTerm = helpLookup[gbTerm];
				}
				if (helpTerm != null) {
					Shell.openExternal(helpURL.replace("$1", helpTerm));
					return true;
				}
			} else {
				if (!electron.Dialog.showConfirm('Open manual search for "$term"?')) return false;
				Shell.openExternal(helpURL.replace("$1", term));
				return true;
			}
		}
		return false;
	}
}
