package gml.project;
import ui.ext.Bookmarks;

/**
 * ...
 * @author YellowAfterlife
 */
typedef ProjectState = {
	treeviewScrollTop:Int,
	treeviewOpenNodes:Array<String>,
	tabPaths:Array<String>,
	?activeTab:Int,
	?mtime:Float,
	?bookmarks:Array<GmlBookmarkState>,
}