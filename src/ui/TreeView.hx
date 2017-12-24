package ui;
import gml.GmlFile;
import js.html.Element;
import js.html.DivElement;
import js.html.MouseEvent;
import Main.document;
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
	//
	public static var toggleCode = ('var cl = this.parentElement.classList;'
		+ ' if (cl.contains("open")) cl.remove("open"); else cl.add("open");'
		+ ' return false;');
	//
	public static var element:DivElement;
	public static function clear() {
		element.innerHTML = "";
	}
	//
	public static function openEvent(e:MouseEvent) {
		var el:Element = cast e.target;
		if (!el.classList.contains("item")) el = el.parentElement;
		GmlFile.open(el.innerText, el.getAttribute(attrPath));
		e.preventDefault();
	}
	public static function makeDir(name:String, rel:String):TreeViewDir {
		var r:TreeViewDir = cast document.createDivElement();
		r.className = "dir";
		//
		var header = document.createDivElement();
		header.className = "header";
		header.setAttribute("onclick", toggleCode);
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
	public static function makeItem(name:String, rel:String, path:String) {
		var r = document.createDivElement();
		r.className = "item";
		var span = document.createSpanElement();
		span.appendChild(document.createTextNode(name));
		r.appendChild(span);
		r.title = name;
		r.setAttribute(attrRel, rel);
		r.setAttribute(attrPath, path);
		r.setAttribute(attrIdent, name);
		r.addEventListener("dblclick", openEvent);
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
