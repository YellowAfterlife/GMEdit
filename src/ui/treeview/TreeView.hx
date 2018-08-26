package ui.treeview;
import electron.Dialog;
import electron.FileSystem;
import electron.Menu;
import gml.file.*;
import gml.Project;
import js.RegExp;
import js.html.CSSStyleSheet;
import js.html.DragEvent;
import js.html.Element;
import js.html.DivElement;
import js.html.Event;
import js.html.MouseEvent;
import Main.*;
import js.html.StyleElement;
import tools.Dictionary;
using tools.HtmlTools;
using tools.NativeString;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TreeView {
	//
	/** Names of items - used for lookups */
	public static inline var attrIdent:String = "data-ident";
	/** Labels for directories - only used for nesting resolution */
	public static inline var attrLabel:String = "data-label";
	public static inline var attrPath:String = "data-full-path";
	public static inline var attrRel:String = "data-rel-path";
	public static inline var attrKind:String = "data-kind";
	public static inline var attrThumb:String = "data-thumb";
	public static inline var attrOpenAs:String = "data-open-as";
	/** Resource GUID (GMS2 only) */
	public static inline var attrYYID:String = "data-yyid";
	//
	public static inline var clDir:String = "dir";
	public static inline var clItem:String = "item";
	public static inline var clOpen:String = "open";
	//
	public static var element:DivElement;
	public static function clear() {
		element.innerHTML = "";
		//
		var sheet = thumbSheet;
		var rules = sheet.cssRules;
		var i = rules.length;
		while (--i >= 0) sheet.deleteRule(i);
	}
	//
	public static function find(item:Bool, query:TreeViewQuery):Element {
		var qjs = "." + (item ? clItem : clDir);
		if (query.extra != null) qjs += "." + query.extra;
		var check_1:String;
		inline function prop(name:String, value:String) {
			check_1 = value;
			if (check_1 != null) qjs += '[$name="' + check_1.escapeProp() + '"]';
		}
		inline function propPath(name:String, value:String) {
			check_1 = value;
			if (check_1 != null) qjs += '[$name="' + check_1.ptNoBS().escapeProp() + '"]';
		}
		prop(attrIdent, query.ident);
		propPath(attrPath, query.path);
		prop(attrKind, query.kind);
		propPath(attrRel, query.rel);
		return element.querySelector(qjs);
	}
	//
	public static var thumbStyle:StyleElement;
	public static var thumbSheet:CSSStyleSheet;
	public static var thumbMap:Dictionary<String> = new Dictionary();
	public static function setThumb(itemPath:String, thumbPath:String) {
		resetThumb(itemPath);
		thumbSheet.insertRule('.treeview .item[$attrPath="' + itemPath.escapeProp()
			+ '"]::before { background-image: url("' + thumbPath.escapeProp()
			+ '"); }', thumbSheet.cssRules.length);
		var item = find(true, { path: itemPath });
		if (item != null) item.setAttribute(attrThumb, thumbPath);
		thumbMap.set(itemPath, thumbPath);
	}
	public static function resetThumb(itemPath:String) {
		var prefix = '.treeview .item[$attrPath="' + itemPath.escapeProp() + '"]::before {';
		var sheet = thumbSheet;
		var rules = sheet.cssRules;
		var i = rules.length;
		while (--i >= 0) {
			if (rules[i].cssText.indexOf(prefix) >= 0) sheet.deleteRule(i);
		}
		var item = find(true, { path: itemPath });
		if (item != null) item.removeAttribute(attrThumb);
		thumbMap.remove(itemPath);
	}
	//
	static function handleDirClick(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		el = el.parentElement;
		if (e.altKey) {
			TreeViewMenus.target = el;
			TreeViewMenus.openCombined();
		} else {
			var cl = el.classList;
			if (cl.contains(clOpen)) cl.remove(clOpen); else cl.add(clOpen);
		}
	}
	static function handleDirCtxMenu(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		TreeViewMenus.showDirMenu(el.parentElement, e);
	}
	static function handleItemCtxMenu(e:MouseEvent) {
		e.preventDefault();
		TreeViewMenus.showItemMenu(cast e.target, e);
	}
	//
	public static function makeDir(name:String, rel:String):TreeViewDir {
		rel = rel.ptNoBS();
		var r:TreeViewDir = cast document.createDivElement();
		r.className = "dir";
		//
		var header = document.createDivElement();
		header.className = "header";
		header.addEventListener("click", handleDirClick);
		header.addEventListener("contextmenu", handleDirCtxMenu);
		header.title = name;
		r.appendChild(header);
		TreeViewDnD.bind(header, rel);
		//
		var span = document.createSpanElement();
		span.appendChild(document.createTextNode(name));
		header.appendChild(span);
		//
		r.setAttribute(attrLabel, name);
		r.setAttribute(attrRel, rel);
		var c = document.createDivElement();
		c.className = "items";
		r.treeItems = c;
		r.appendChild(c);
		return r;
	}
	//
	static function handleItemClick(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		if (!el.classList.contains("item")) el = el.parentElement;
		var openAs = el.getAttribute(attrOpenAs);
		var nav = openAs != null ? { kind: GmlFileKind.createByName(openAs) } : null;
		GmlFile.open(el.innerText, el.getAttribute(attrPath), nav);
	}
	private static inline function makeItemImpl(name:String, path:String, kind:String) {
		var r = document.createDivElement();
		r.className = "item";
		var span = document.createSpanElement();
		span.appendChild(document.createTextNode(name));
		r.appendChild(span);
		r.title = name;
		r.setAttribute(attrPath, path.ptNoBS());
		r.setAttribute(attrIdent, name);
		if (kind != null) r.setAttribute(attrKind, kind);
		return r;
	}
	//
	public static function makeItem(name:String, rel:String, path:String, kind:String) {
		rel = rel.ptNoBS();
		var r = makeItemImpl(name, path, kind);
		r.setAttribute(attrRel, rel);
		TreeViewDnD.bind(r, rel);
		var th = thumbMap[path];
		if (th != null) r.setAttribute(attrThumb, th);
		r.addEventListener("dblclick", handleItemClick);
		r.addEventListener("contextmenu", handleItemCtxMenu);
		return r;
	}
	//
	private static function openProject(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		if (!el.classList.contains("item")) el = el.parentElement;
		var path = el.getAttribute(attrPath);
		if (FileSystem.existsSync(path)) {
			Project.open(path);
		} else if (Project.current.path == "") {
			if (Dialog.showMessageBox({
				message: "Project is missing. Remove from recent project list?",
				buttons: ["Yes", "No"],
				cancelId: 1,
			}) == 0) {
				RecentProjects.remove(path);
				el.parentElement.removeChild(el);
			}
		}
	}
	public static function makeProject(name:String, path:String) {
		var r = makeItemImpl(name, path, "project");
		r.title = path;
		r.addEventListener("dblclick", openProject);
		r.addEventListener("contextmenu", handleItemCtxMenu);
		return r;
	}
	//
	public static var openPaths:Array<String> = [];
	public static function saveOpen() {
		var r:Array<String> = [];
		for (dir in element.querySelectorEls('.$clDir.$clOpen')) {
			r.push(dir.getAttribute(attrRel));
		}
		openPaths = r;
	}
	public static function restoreOpen(?paths:Array<String>) {
		var paths = paths != null ? paths : openPaths;
		var el = element;
		for (path in paths) {
			var epath = tools.NativeString.escapeProp(path);
			var dir = el.querySelector('.dir[$attrRel="$epath"]');
			if (dir != null) dir.classList.add(clOpen);
		}
	}
	//
	public static function init() {
		element = document.querySelectorAuto(".treeview");
		if (element == null) element = document.createDivElement();
		thumbStyle = document.querySelectorAuto("#tree-thumbs");
		thumbSheet = cast thumbStyle.sheet;
	}
}
typedef TreeViewQuery = {
	?extra:String,
	?path:String,
	?kind:String,
	?rel:String,
	?ident:String,
};
extern class TreeViewDir extends DivElement {
	public var treeItems:DivElement;
}
extern class TreeViewItem extends DivElement {
	
}
