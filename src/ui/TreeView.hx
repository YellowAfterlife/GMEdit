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
	//{
	/** whatever that invoked the context menu */
	static var ctxTarget:Element;
	static var ctxMenuDir:Menu;
	//
	static var ctxOpenAllItem:MenuItem;
	static function ctxOpenAll(_, _, _) {
		var found = 0;
		var els = ctxTarget.querySelectorEls('.item');
		if (els.length < 50 || Dialog.showMessageBox({
			message: "Are you sure that you want to open " + els.length + " tabs?",
			buttons: ["Yes", "No"],
			cancelId: 1,
		}) == ) for (el in els) {
			window.setTimeout(function() {
				GmlFile.open(el.innerText, el.getAttribute(attrPath));
			}, found * 50);
			found += 1;
		}
	}
	//
	static var ctxOpenCombinedItem:MenuItem;
	static function ctxOpenCombined(_, _, _) {
		var items = [];
		var error = "";
		var mpath = "";
		for (item in ctxTarget.querySelectorEls('.item[$attrKind="script"]')) {
			var path = item.getAttribute(attrPath);
			var ident = item.getAttribute(attrIdent);
			if (mpath != "") mpath += "|";
			mpath += path;
			items.push({ name: ident, path: path });
		}
		if (items.length > 0) {
			var name = ctxTarget.querySelector('.header').innerText;
			GmlFile.openTab(new GmlFile(name, mpath, Multifile, items));
		}
	}
	//
	static function ctxInit() {
		ctxMenuDir = new Menu();
		ctxOpenAllItem = new MenuItem({ label: "Open all", click: ctxOpenAll });
		ctxMenuDir.append(ctxOpenAllItem);
		ctxOpenCombinedItem = new MenuItem({ label: "Open combined view", click: ctxOpenCombined });
		ctxMenuDir.append(ctxOpenCombinedItem);
	}
	//}
	static function handleDirClick(e:MouseEvent) {
		e.preventDefault();
		var el:Element = cast e.target;
		el = el.parentElement;
		if (e.altKey) {
			ctxTarget = el;
			ctxOpenCombined(null, null, null);
		} else {
			var cl = el.classList;
			if (cl.contains("open")) cl.remove("open"); else cl.add("open");
		}
	}
	static function handleDirCtxMenu(e:Event) {
		ctxTarget = cast e.target;
		ctxTarget = ctxTarget.parentElement;
		ctxOpenAllItem.enabled = ctxTarget.querySelector('.item') != null;
		ctxOpenCombinedItem.enabled = ctxTarget.querySelector('.item[$attrKind="script"]') != null;
		ctxMenuDir.popupAsync();
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
		ctxInit();
	}
}
extern class TreeViewDir extends DivElement {
	public var treeItems:DivElement;
}
extern class TreeViewItem extends DivElement {
	
}
