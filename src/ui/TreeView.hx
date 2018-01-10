package ui;
import electron.Dialog;
import electron.Menu;
import gml.GmlFile;
import gml.Project;
import js.html.Element;
import js.html.DivElement;
import js.html.Event;
import js.html.MouseEvent;
import Main.*;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TreeView {
	//
	public static inline var attrIdent:String = "data-ident";
	public static inline var attrPath:String = "data-full-path";
	public static inline var attrRel:String = "data-rel-path";
	public static inline var attrKind:String = "data-kind";
	//
	public static var element:DivElement;
	public static function clear() {
		element.innerHTML = "";
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
			if (cl.contains("open")) cl.remove("open"); else cl.add("open");
		}
	}
	static function handleDirCtxMenu(e:Event) {
		var el:Element = cast e.target;
		TreeViewMenus.showDirMenu(el.parentElement);
	}
	static function handleItemCtxMenu(e:Event) {
		TreeViewMenus.showItemMenu(cast e.target);
	}
	public static function makeDir(name:String, rel:String):TreeViewDir {
		var r:TreeViewDir = cast document.createDivElement();
		r.className = "dir";
		//
		var header = document.createDivElement();
		header.className = "header";
		header.addEventListener("click", handleDirClick);
		header.addEventListener("contextmenu", handleDirCtxMenu);
		header.title = name;
		r.appendChild(header);
		//
		var span = document.createSpanElement();
		span.appendChild(document.createTextNode(name));
		header.appendChild(span);
		//
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
		GmlFile.open(el.innerText, el.getAttribute(attrPath));
	}
	private static inline function makeItemImpl(name:String, path:String, kind:String) {
		var r = document.createDivElement();
		r.className = "item";
		var span = document.createSpanElement();
		span.appendChild(document.createTextNode(name));
		r.appendChild(span);
		r.title = name;
		r.setAttribute(attrPath, path);
		r.setAttribute(attrIdent, name);
		if (kind != null) r.setAttribute(attrKind, kind);
		return r;
	}
	//
	public static function makeItem(name:String, rel:String, path:String, kind:String) {
		var r = makeItemImpl(name, path, kind);
		r.setAttribute(attrRel, rel);
		r.addEventListener("dblclick", handleItemClick);
		r.addEventListener("contextmenu", handleItemCtxMenu);
		return r;
	}
	//
	private static function openProject(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		if (!el.classList.contains("item")) el = el.parentElement;
		Project.open(el.getAttribute(attrPath));
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
		for (dir in element.querySelectorEls(".dir.open")) {
			r.push(dir.getAttribute(attrRel));
		}
		openPaths = r;
	}
	public static function restoreOpen(?paths:Array<String>) {
		var paths = paths != null ? paths : openPaths;
		var el = element;
		for (path in paths) {
			var dir = el.querySelector('.dir[$attrRel="$path"]');
			if (dir != null) dir.classList.add("open");
		}
	}
	//
	public static function init() {
		element = cast Main.document.querySelector(".treeview");
	}
}
extern class TreeViewDir extends DivElement {
	public var treeItems:DivElement;
}
extern class TreeViewItem extends DivElement {
	
}
