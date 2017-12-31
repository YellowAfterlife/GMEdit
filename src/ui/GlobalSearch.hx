package ui;
import ace.AceWrap;
import Main.aceEditor;
import Main.window;
import gml.*;
import js.RegExp;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import tools.NativeString;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GlobalSearch {
	public static var element:Element;
	public static var fdFind:InputElement;
	public static var fdReplace:InputElement;
	public static var btFind:InputElement;
	public static var btReplace:InputElement;
	public static var btCancel:InputElement;
	public static var cbWholeWord:InputElement;
	public static var cbMatchCase:InputElement;
	public static var cbCheckComments:InputElement;
	public static var cbCheckStrings:InputElement;
	public static var cbCheckObjects:InputElement;
	public static var cbCheckScripts:InputElement;
	//
	static function offsetToPos(code:String, till:Int):AcePos {
		var row = 0, rowStart = 0;
		var pos = code.indexOf("\n");
		while (pos <= till && pos >= 0) {
			row += 1;
			rowStart = pos + 1;
			pos = code.indexOf("\n", rowStart);
		}
		return { column: till - rowStart, row: row };
	}
	public static function find(term:String, opt:GlobalSearchOpt) {
		var pj = Project.current;
		if (pj.version == gml.GmlVersion.none) return;
		var eterm = NativeString.escapeRx(term);
		if (opt.wholeWord) eterm = "\\b" + eterm + "\\b";
		var rx = new RegExp(eterm, opt.matchCase ? "g" : "ig");
		var out = "";
		var found = 0;
		pj.search(function(name:String, path:String, code:String) {
			var mt = rx.exec(code);
			while (mt != null) {
				var ofs = mt.index;
				var eol = code.indexOf("\n", ofs);
				if (eol >= 0) {
					if (StringTools.fastCodeAt(code, eol - 1) == "\r".code) eol -= 1;
				} else eol = code.length;
				var pos = offsetToPos(code, ofs);
				out += "\n\n// in @[" + name + ":" + (pos.row + 1) + "]:\n";
				out += code.substring(ofs - pos.column, eol);
				found += 1;
				mt = rx.exec(code);
			}
		}, function() {
			var name = "search: " + term;
			out = "// " + found + " result" + (found != 1 ? "s" : "") + ":" + out;
			GmlFile.next = new GmlFile(name, null, SearchResults, out);
			ChromeTabs.addTab(name);
			window.setTimeout(function() {
				aceEditor.focus();
			});
		}, opt);
	}
	public static function toggle() {
		if (element.style.display == "none") {
			element.style.display = "";
			var s = aceEditor.getSelectedText();
			if (s != "" && s != null) fdFind.value = s;
			fdFind.focus();
			fdFind.select();
		} else {
			element.style.display = "none";
		}
	}
	public static function init() {
		element = Main.document.querySelector("#global-search");
		fdFind = element.querySelectorAuto('input[name="find-text"]');
		fdReplace = element.querySelectorAuto('input[name="replace-text"]');
		btFind = element.querySelectorAuto('input[name="find"]');
		btReplace = element.querySelectorAuto('input[name="replace"]');
		btCancel = element.querySelectorAuto('input[name="cancel"]');
		//
		cbWholeWord = element.querySelectorAuto('input[name="whole-word"]');
		cbMatchCase = element.querySelectorAuto('input[name="match-case"]');
		cbCheckComments = element.querySelectorAuto('input[name="check-comments"]');
		cbCheckStrings = element.querySelectorAuto('input[name="check-strings"]');
		cbCheckObjects = element.querySelectorAuto('input[name="check-objects"]');
		cbCheckScripts = element.querySelectorAuto('input[name="check-scripts"]');
		//
		fdFind.onkeydown = function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: btFind.click();
				case KeyboardEvent.DOM_VK_ESCAPE: btCancel.click();
			}
		}
		btFind.onclick = function(_) {
			var opt:GlobalSearchOpt = {
				wholeWord: cbWholeWord.checked,
				matchCase: cbMatchCase.checked,
				checkComments: cbCheckComments.checked,
				checkStrings: cbCheckScripts.checked,
				checkObjects: cbCheckObjects.checked,
				checkScripts: cbCheckScripts.checked
			};
			find(fdFind.value, opt);
			element.style.display = "none";
		};
		btCancel.onclick = function(_) element.style.display = "none";
	}
}
typedef GlobalSearchOpt = {
	wholeWord:Bool,
	matchCase:Bool,
	checkComments:Bool,
	checkStrings:Bool,
	checkObjects:Bool,
	checkScripts:Bool,
};
