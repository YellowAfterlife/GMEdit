package gml.project;
import tools.Aliases;
import ui.ext.Bookmarks;

/**
 * ...
 * @author YellowAfterlife
 */
typedef ProjectState = {
	treeviewScrollTop:Int,
	treeviewOpenNodes:Array<String>,
	tabs:Array<ProjectTabState>,
	?tabPaths:Array<String>, // legacy
	?activeTab:Int,
	?mtime:Float,
	?bookmarks:Array<GmlBookmarkState>,
}
typedef ProjectTabState = {
	?relPath:RelPath,
	?fullPath:FullPath,
	?pinned:Bool,
	?kind:String,
	?data:Dynamic,
}