package ui.treeview;
import js.html.InputElement;
import js.html.KeyboardEvent;
import haxe.Constraints.Function;
import js.html.DivElement;
import tools.HtmlTools;
import file.FileKind;
using tools.NativeString;
import Main.document;

/**
 * Various shorthands
 * @author YellowAfterlife
 */
extern class TreeViewElement extends DivElement {
	/** 2.3 sort order */
	public var yyOrder:Int;
	
	public inline function asTreeDir():TreeViewDir return cast this;
	public inline function asTreeItem():TreeViewItem return cast this;
	
	/** Indicates whether this is a root element - no parent folders */
	public var treeIsRoot(get, never):Bool;
	private inline function get_treeIsRoot():Bool {
		return parentElement.classList.contains("treeview");
	}
	
	public var treeIsDir(get, never):Bool;
	private inline function get_treeIsDir():Bool {
		return classList.contains(TreeView.clDir);
	}
	
	public var treeIsItem(get, never):Bool;
	private inline function get_treeIsItem():Bool {
		return classList.contains(TreeView.clItem);
	}
	
	public var treeRelPath(get, set):String;
	private inline function get_treeRelPath():String {
		return getAttribute(TreeView.attrRel);
	}
	private inline function set_treeRelPath(v:String):String {
		setAttribute(TreeView.attrRel, v);
		return v;
	}
	
	public var treeFullPath(get, set):String;
	private inline function get_treeFullPath():String {
		return getAttribute(TreeView.attrPath);
	}
	private inline function set_treeFullPath(v:String):String {
		setAttribute(TreeView.attrPath, v);
		return v;
	}
	
	public var treeLabel(get, set):String;
	private inline function get_treeLabel():String {
		return getAttribute(TreeView.attrLabel);
	}
	private inline function set_treeLabel(s:String):String {
		setAttribute(TreeView.attrLabel, s);
		return s;
	}
	
	public var treeKind(get, set):String;
	private inline function get_treeKind():String {
		return getAttribute(TreeView.attrKind);
	}
	private inline function set_treeKind(s:String):String {
		setAttribute(TreeView.attrKind, s);
		return s;
	}
	
	public var treeIdent(get, set):String;
	private inline function get_treeIdent():String {
		return getAttribute(TreeView.attrIdent);
	}
	private inline function set_treeIdent(s:String):String {
		setAttribute(TreeView.attrIdent, s);
		return s;
	}
	
	public var treeParentDir(get, never):TreeViewDir;
	private inline function get_treeParentDir():TreeViewDir {
		return TreeViewElementTools.getTreeParentDir(this);
	}
	
	/** As seen on the page */
	public var treeText(get, set):String;
	private inline function get_treeText():String {
		return TreeViewElementTools.getTreeText(this);
	}
	private inline function set_treeText(s:String):String {
		return TreeViewElementTools.setTreeText(this, s);
	}

	/**
	 * Opens and selects an inline textbox for the element. When the textbox is unfocused
	 * or the user hits enter it will run the provided function 
	 * @param finishFunction function that's ran on the element losing focus
	 */
	public inline function showInlineTextbox(finishFunction:String->Void):Void {
		TreeViewElementTools.showInlineTextbox(this, finishFunction);
	}
}
extern class TreeViewDir extends TreeViewElement {
	public var treeHeader:DivElement;
	public var treeItems:DivElement;
	
	public var treeItemEls(get, never):ElementListOf<TreeViewElement>;
	private inline function get_treeItemEls():ElementListOf<TreeViewElement> {
		return HtmlTools.getChildrenAs(treeItems);
	}
	
	/** Shorthand for getting the path for `parent` nodes in resources */
	public var treeFolderPath23(get, never):String;
	private inline function get_treeFolderPath23():String {
		return TreeViewElementTools.getTreeFolderPathV23(this);
	}
}
extern class TreeViewItem extends TreeViewElement {
	/** If not null, overrides the FileKind that will be used for this element. */
	public var yyOpenAs:FileKind;
}
private class TreeViewElementTools {
	public static function getTreeFolderPathV23(el:TreeViewDir) {
		var rel = el.treeRelPath;
		if (rel.endsWith("/")) {
			return rel.substring(0, rel.length - 1) + ".yy";
		} else return rel;
	}
	public static function getTreeParentDir(el:TreeViewElement):TreeViewDir {
		var par = el.parentElement;
		if (par == null || !par.classList.contains("items")) return null;
		return cast par.parentElement;
	}
	public static function getTreeText(el:TreeViewElement):String {
		var header:DivElement;
		if (el.treeIsDir) {
			header = el.asTreeDir().treeHeader;
		} else header = el;
		return header.querySelector("span").innerText;
	}
	public static function setTreeText(el:TreeViewElement, s:String):String {
		var header:DivElement;
		if (el.treeIsDir) {
			header = el.asTreeDir().treeHeader;
		} else header = el;
		header.querySelector("span").innerText = s;
		return s;
	}
	public static function showInlineTextbox(el:TreeViewElement, finishFunction:String->Void) {
		var spanChild = el.firstElementChild;
		var oldDisplay = spanChild.style.display; // stores old display to apply back later, probably overkill but who knows with themes
		el.draggable = false;
		spanChild.style.display = "none";

		var textInputElement:InputElement = cast document.createElement("input");

		textInputElement.className = "inline-text-field";
		textInputElement.type = "text";
		textInputElement.value = el.textContent;
				
		el.appendChild(textInputElement);

		textInputElement.select();

		var triggered = false;
		var wrappedFinishFunction = function() {
			if (triggered) {
				return;
			}
			triggered = true;
			textInputElement.remove();
			spanChild.style.display = oldDisplay;
			el.draggable = true;

			finishFunction(textInputElement.value);
		}

		textInputElement.addEventListener("focusout", wrappedFinishFunction);
		textInputElement.addEventListener("keyup", function(event:KeyboardEvent) {
			if (event.keyCode == 13) {
				event.preventDefault();
				wrappedFinishFunction();
			}
		});
	}
}
