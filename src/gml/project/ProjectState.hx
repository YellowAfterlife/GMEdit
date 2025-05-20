package gml.project;
import haxe.extern.EitherType;
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
	?pinned:EitherType<Bool, Int>,
	?kind:String,
	?data:Dynamic,
}