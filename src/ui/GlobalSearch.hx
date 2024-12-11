package ui;
import ace.AceMacro.jsRx;
import ace.AceWrap;
import ace.extern.*;
import Main.aceEditor;
import Main.window;
import gml.*;
import electron.Dialog;
import gml.file.GmlFile;
import js.lib.RegExp;
import js.Syntax;
import js.html.DivElement;
import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import synext.GmlExtLambda;
import parsers.GmlReader;
import tools.CharCode;
import tools.Dictionary;
import tools.GmlCodeTools;
import tools.NativeObject;
import tools.NativeString;
import tools.macros.SynSugar;
import ui.search.GlobalSeachData;
import haxe.extern.EitherType;
import haxe.Constraints.Function;
import file.kind.gml.*;
using tools.HtmlTools;

/**
 * The little dialog that pops up when you press Ctrl+Shift+F
 * and the unforeseen complexity that comes from having all those checkboxes.
 * @author YellowAfterlife
 */
@:keep class GlobalSearch {
	public static var element:Element;
	public static var infoElement:Element;
	public static var fdFind:InputElement;
	public static var fdReplace:InputElement;
	public static var btFind:InputElement;
	public static var btReplace:InputElement;
	public static var btPreview:InputElement;
	public static var btCancel:InputElement;
	public static var cbWholeWord:InputElement;
	public static var cbMatchCase:InputElement;
	public static var cbCheckComments:InputElement;
	public static var cbCheckStrings:InputElement;
	public static var cbCheckObjects:InputElement;
	public static var cbCheckScripts:InputElement;
	public static var cbCheckHeaders:InputElement;
	public static var cbCheckTimelines:InputElement;
	public static var cbCheckRooms:InputElement;
	public static var cbCheckMacros:InputElement;
	public static var cbCheckShaders:InputElement;
	public static var cbCheckExtensions:InputElement;
	public static var cbCheckLibResources:InputElement;
	public static var cbExpandLambdas:InputElement;
	public static var cbRegExp:InputElement;
	public static var cbUnique:InputElement;
	public static var divSearching:DivElement;
	public static var currentPath:String;
	//
	static function offsetToPos(code:String, till:Int, rowStart:Int):AcePos {
		return ui.search.GlobalSearchImpl.offsetToPos(code, till, rowStart);
	}
	public static function run(opt:GlobalSearchOpt, ?finish:Void->Void) {
		ui.search.GlobalSearchImpl.run(opt, finish);
	}
	public static function findReferences(id:String, ?extra:GlobalSearchOpt) {
		if (!isVisible()) {
			infoElement.style.display = "";
		}
		var opt:GlobalSearchOpt = {
			find: id,
			wholeWord: true,
			matchCase: true,
			checkStrings: jsRx(~/^@?["']/).test(id),
			checkComments: jsRx(~/(?:\/\/|\/\*)/).test(id),
			checkHeaders: true,
			checkScripts: true,
			checkTimelines: true,
			checkObjects: true,
			checkRooms: true,
			checkMacros: true,
			checkShaders: false,
			checkExtensions: true,
			checkLibResources: true,
			expandLambdas: true,
			checkRefKind: true,
		};
		if (extra != null) {
			NativeObject.fillDefaults(extra, opt);
		} else extra = opt;
		run(extra, function() {
			infoElement.style.display = "none";
		});
	}
	public static inline function isVisible() {
		return element.style.display != "none";
	}
	public static function toggle() {
		if (!isVisible()) {
			element.style.display = "";
			infoElement.style.display = "none";
			divSearching.style.display = "none";
			var s = aceEditor.getSelectedText();
			if (s != "" && s != null) fdFind.value = s;
			fdFind.focus();
			fdFind.select();
		} else {
			element.style.display = "none";
		}
	}
	public static function getOptions():GlobalSearchOpt {
		var find:EitherType<String, RegExp>;
		if (!cbRegExp.checked) {
			find = fdFind.value;
		} else try {
			var flags = "g";
			if (!cbMatchCase.checked) flags += "i";
			find = new RegExp(fdFind.value, flags);
		} catch (x:Dynamic) {
			window.alert("Error compiling the regular expression: " + x);
			return null;
		}
		return {
			find: find,
			findFilter: null,
			replaceBy: null,
			previewReplace: false,
			headerFilter: null,
			wholeWord: cbWholeWord.checked,
			matchCase: cbMatchCase.checked,
			checkStrings: cbCheckStrings.checked,
			checkObjects: cbCheckObjects.checked,
			checkScripts: cbCheckScripts.checked,
			checkHeaders: cbCheckHeaders.checked,
			checkComments: cbCheckComments.checked,
			checkTimelines: cbCheckTimelines.checked,
			checkRooms: cbCheckRooms.checked,
			checkMacros: cbCheckMacros.checked,
			checkShaders: cbCheckShaders.checked,
			checkExtensions: cbCheckExtensions.checked,
			checkLibResources: cbCheckLibResources.checked,
			expandLambdas: cbExpandLambdas.checked
		};
	}
	public static function runAuto(opt:GlobalSearchOpt) {
		divSearching.style.display = "";
		run(opt, function() {
			element.style.display = "none";
			infoElement.style.display = "none";
		});
	}
	public static function findAuto(?opt:GlobalSearchOpt) {
		if (opt == null) {
			opt = getOptions();
			if (cbUnique.checked) {
				var found = new Dictionary<Bool>();
				opt.findFilter = function(mt:Dynamic) {
					var k:String = Std.is(mt, Array) ? mt[0] : mt;
					if (found[k]) return false;
					found[k] = true;
					return true;
				};
			}
		}
		if (opt != null) runAuto(opt);
	}
	public static function replaceAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		opt.replaceBy = fdReplace.value;
		runAuto(opt);
	}
	public static function previewAuto(?opt:GlobalSearchOpt) {
		if (opt == null) opt = getOptions();
		if (opt == null) return;
		opt.replaceBy = fdReplace.value;
		opt.previewReplace = true;
		runAuto(opt);
	}
	public static function init() {
        element = Main.document.querySelector("#global-search");
		element.innerHTML = SynSugar.xmls(<form>
			<div class="search-main">
				<div>
					Find what:
					<input type="text" name="find-text" />
				</div>
				<div>
					Replace with:
					<input type="text" name="replace-text" />
				</div>
				<div>
					<input type="button" class="highlighted_button" name="find" value="Find All" />
					<input type="button" class="highlighted_button" name="replace" value="Replace All" title="Replace items across the project" />
					<input type="button" class="highlighted_button" name="cancel" value="Cancel" /><br/>
				</div>
				<div>
					<input type="button" class="highlighted_button" name="preview" value="Preview 'Replace All'" title="Preview replace operation without modifications" />
				</div>
				<div style="display:none" class="searching-text">
					Searching...
				</div>
			</div>
			<div class="search-options">
				<fieldset>
					<legend>Options</legend>
					<input    id="global-search-whole-word" type="checkbox"
					/><label for="global-search-whole-word">Whole word</label><br/>
					<input    id="global-search-match-case" type="checkbox"
					/><label for="global-search-match-case">Match case</label><br/>
					<input    id="global-search-check-comments" type="checkbox" checked
					/><label for="global-search-check-comments">Look in comments</label><br/>
					<input    id="global-search-check-strings" type="checkbox" checked
					/><label for="global-search-check-strings">Look in strings</label><br/>
					<input    id="global-search-check-headers" type="checkbox"
					/><label for="global-search-check-headers" title="Will show results inside #event/etc. lines">Look in headers</label><br/>
					<input    id="global-search-expand-lambdas" type="checkbox" checked
					/><label for="global-search-expand-lambdas" title="If enabled, will show results inside inline functions at place of declaration rather than inside their extension">Expand #lambdas</label><br/>
					<input    id="global-search-regexp" type="checkbox"
					/><label for="global-search-regexp" title="Also lets you use $0,$1,$2,etc. in 'replace by'">RegExp search</label><br/>
					<input    id="global-search-unique" type="checkbox"
					/><label for="global-search-unique" title="When using regexp search, only shows unique matches">Unique match</label>
				</fieldset>
			</div>
			<div class="search-options search-options-2">
				<fieldset>
					<legend>Look in</legend>
					<input    id="global-search-check-scripts"    type="checkbox" checked
					/><label for="global-search-check-scripts">Scripts</label><br/>
					<input    id="global-search-check-objects"    type="checkbox" checked
					/><label for="global-search-check-objects">Objects</label><br/>
					<input    id="global-search-check-timelines"  type="checkbox" checked
					/><label for="global-search-check-timelines">Timelines</label><br/>
					<input    id="global-search-check-macros"     type="checkbox" checked
					/><label for="global-search-check-macros">Macros</label><br/>
					<input    id="global-search-check-rooms" type="checkbox" checked
					/><label for="global-search-check-rooms">Rooms</label><br/>
					<input    id="global-search-check-shaders"    type="checkbox"
					/><label for="global-search-check-shaders">Shaders</label><br/>
					<input    id="global-search-check-extensions" type="checkbox"
					/><label for="global-search-check-extensions">Extensions</label><br/>
					<input    id="global-search-check-lib-resources" type="checkbox"
					/><label for="global-search-check-lib-resources" title="Library resources, set in project properties">Lib. Res.</label><br/>
				</fieldset>
			</div>
		</form>);
		//
		infoElement = Main.document.querySelector("#global-search-info");
		infoElement.innerHTML = SynSugar.xmls(<html>
			Searching...
		</html>);
		//{
        fdFind = element.querySelectorAuto('input[name="find-text"]');
        fdReplace = element.querySelectorAuto('input[name="replace-text"]');
        btFind = element.querySelectorAuto('input[name="find"]');
        btReplace = element.querySelectorAuto('input[name="replace"]');
        btPreview = element.querySelectorAuto('input[name="preview"]');
        btCancel = element.querySelectorAuto('input[name="cancel"]');
		divSearching = element.querySelectorAuto('.searching-text');
		//
		cbWholeWord = element.querySelectorAuto('#global-search-whole-word');
		cbMatchCase = element.querySelectorAuto('#global-search-match-case');
		cbCheckStrings = element.querySelectorAuto('#global-search-check-strings');
		cbCheckObjects = element.querySelectorAuto('#global-search-check-objects');
		cbCheckScripts = element.querySelectorAuto('#global-search-check-scripts');
		cbCheckHeaders = element.querySelectorAuto('#global-search-check-headers');
		cbCheckComments = element.querySelectorAuto('#global-search-check-comments');
		cbCheckTimelines = element.querySelectorAuto('#global-search-check-timelines');
		cbCheckMacros = element.querySelectorAuto('#global-search-check-macros');
		cbCheckShaders = element.querySelectorAuto('#global-search-check-shaders');
		cbCheckExtensions = element.querySelectorAuto('#global-search-check-extensions');
		cbCheckLibResources = element.querySelectorAuto('#global-search-check-lib-resources');
		cbCheckRooms = element.querySelectorAuto('#global-search-check-rooms');
		cbExpandLambdas = element.querySelectorAuto('#global-search-expand-lambdas');
		cbRegExp = element.querySelectorAuto('#global-search-regexp');
		cbUnique = element.querySelectorAuto('#global-search-unique');
		//}
		fdFind.onkeydown = function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: btFind.click();
				case KeyboardEvent.DOM_VK_ESCAPE: btCancel.click();
			}
		}
		fdReplace.onkeydown = function(e:KeyboardEvent) {
			switch (e.keyCode) {
				case KeyboardEvent.DOM_VK_RETURN: btReplace.click();
				case KeyboardEvent.DOM_VK_ESCAPE: btCancel.click();
			}
		}
		btFind.onclick = function(_) findAuto();
		btReplace.onclick = function(_) {
			if (!Dialog.showConfirmWarn("Are you sure that you want to globally replace?"
				+ "\nThis cannot be undone!")) return;
			replaceAuto();
		};
		btPreview.onclick = function(_) previewAuto();
		btCancel.onclick = function(_) element.style.display = "none";
	}
}
typedef GlobalSearchOpt = {
	find:EitherType<String, RegExp>,
	?replaceBy:EitherType<String, Function>,
	/** If `true`, shows pairs of before-after replacement lines but does not modify files. */
	?previewReplace:Bool,
	/**
	 * If provided, is called for each match and returns whether to include/replace it.
	 */
	?findFilter:Function,
	/**
	 * Is called with matched line (same thing you see in search results).
	 * Can return false to ignore the line.
	 */
	?lineFilter:String->Bool,
	/**
	 * Can be a regex to filter context
	 */
	?headerFilter:EitherType<RegExp, GlobalSearchCtxFilter>,
	/** Whole-word match (/\bword\b/) */
	?wholeWord:Bool,
	/** Ignore `.word` */
	?noDotPrefix:Bool,
	/** Case-sensistive match */
	?matchCase:Bool,
	/** Whether to include matches inside strings ("", '') */
	?checkStrings:Bool,
	// per-resource filters:
	?checkObjects:Bool,
	?checkScripts:Bool,
	?checkHeaders:Bool,
	?checkComments:Bool,
	?checkTimelines:Bool,
	?checkMacros:Bool,
	?checkRooms:Bool,
	?checkShaders:Bool,
	?checkExtensions:Bool,
	?checkLibResources:Bool,
	/** Whether to expand pre-2.3 lambdas instead of showing them separately */
	?expandLambdas:Bool,
	/** Whether to display type of reference (read, write, define, etc.) */
	?checkRefKind:Bool,
	?errors:String,
	/** If set, prepends the given strings before the output */
	?results:String,
};
typedef GlobalSearchCtxFilter = (ctx:String, path:String)->Bool;
