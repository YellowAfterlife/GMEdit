package ui.treeview;
import js.html.DivElement;
import tools.HtmlTools;
import file.FileKind;

/**
 * Various shorthands
 * @author YellowAfterlife
 */
extern class TreeViewElement extends DivElement {
	/** 2.3 sort order */
	public var yyOrder:Int;
	
	public inline function asTreeDir():TreeViewDir return cast this;
	public inline function asTreeItem():TreeViewItem return cast this;
	
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
}
extern class TreeViewItem extends TreeViewElement {
	public var yyOpenAs:FileKind;
}
