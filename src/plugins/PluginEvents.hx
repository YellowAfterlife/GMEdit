package plugins;
import gml.file.GmlFile;
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
	static function tabsReorder(e:{target:ChromeTabsImpl}):Void;
	//
	static function fileOpen(e:{file:GmlFile}):Void;
	static function activeFileChange(e:{file:GmlFile}):Void;
	static function fileClose(e:{file:GmlFile}):Void;
	static function fileSave(e:{file:GmlFile,?code:String}):Void;
	//
}
