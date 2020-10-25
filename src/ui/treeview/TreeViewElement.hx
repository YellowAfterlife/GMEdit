package ui.treeview;
import js.html.DivElement;
import tools.HtmlTools;
import file.FileKind;
using tools.NativeString;

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
	public var yyOpenAs:FileKind;
}
private class TreeViewElementTools {
	public static function getTreeFolderPathV23(el:TreeViewDir) {
		var rel = el.treeRelPath;
		if (rel.endsWith("/")) {
			return rel.substring(0, rel.length - 1) + ".yy";
		} else return rel;
	}
}
