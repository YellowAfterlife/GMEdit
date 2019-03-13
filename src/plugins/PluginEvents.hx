package plugins;
import gml.file.GmlFile;
import ui.ChromeTabs;
import ui.ChromeTabs.ChromeTabsImpl;

/**
 * Calls to these compile to
 * GMEdit._signal("name", param) [if return type is Void]
 * or GMEdit._emit("name", param) [otherwise]
 * This enforces strict typing and doubles as a signal/event reference
 * @author YellowAfterlife
 */
@:build(plugins.PluginEventsMacros.build())
extern class PluginEvents {
	
	/**
	 * Dispatches whenever the user drags tabs around to change their order.
	 */
	static function tabsReorder(e:{target:ChromeTabsImpl}):Void;
	
	/**
	 * Dispatches when a new file is opened and ready to go.
	 */
	static function fileOpen(e:{file:GmlFile}):Void;
	
	/**
	 * Dispatches when active file (read: tab) changes
	 */
	static function activeFileChange(e:{file:GmlFile}):Void;
	
	/**
	 * Dispatches after a file (and it's tab) is closed and before it's gone for good.
	 * Tab indicates it's tab element (which is no longer in DOM at this point).
	 */
	static function fileClose(e:{file:GmlFile,tab:ChromeTab}):Void;
	
	/**
	 * Dispatches after a file is saved.
	 * `code` will contain a copy of file's new contents, if appropriate
	 */
	static function fileSave(e:{file:GmlFile,?code:String}):Void;
}
