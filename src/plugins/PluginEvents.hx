package plugins;
import gml.file.GmlFile;
import gml.Project;
import gml.project.ProjectState;
import js.html.Element;
import js.html.MouseEvent;
import ui.ChromeTabs;
import ui.ChromeTabs.ChromeTabsImpl;
import ace.AceWrap;

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
	 * Dispatches prior to showing the tab context menu.
	 */
	static function tabMenu(e:{target:ChromeTab,event:MouseEvent}):Void;
	
	/**
	 * Dispatches when a new file is opened and ready to go.
	 */
	static function fileOpen(e:{file:GmlFile}):Void;

	/**
	 * Dispatches when a new project is opened and ready to go.
	 */
	static function projectOpen(e:{project:Project}):Void;

	/**
	 * Dispatches when the project is closed or a new project is opened
	 */
	static function projectClose(e:{project:Project}):Void;
	
	/**
	 * Dispatches when saving the project state (treeview, open tabs).
	 * You can save your plugin-specific per-project state here.
	 */
	static function projectStateSave(e:{project:Project, state:ProjectState}):Void;
	
	/**
	 * Dispatches when restoring the project state.
	 * This happens when the project is fully loaded and tabs were re-opened.
	 * You can load your previously-saved plugin-specific per-project state here.
	 */
	static function projectStateRestore(e:{project:Project, state:ProjectState}):Void;
	
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
	static function fileSave(e:{file:GmlFile, ?code:String}):Void;
	
	/**
	 * Dispatches after a file tab was reloaded due to changes on disk
	 * (automatically or with user permit)
	 */
	static function fileReload(e:{file:GmlFile}):Void;

	/**
	 * Dispatches after a file's name or path changes.
	 */
	static function fileRename(e:{file:GmlFile}):Void;
	
	/**
	 * Called after constructing the preferences menu.
	 * You can use this to insert your plugin-specific DOM elements into it.
	 * ui.Preferences offers a large set of helpers for all kinds of helpers.
	 * 
	 * @deprecated Consider implementing `PluginData.buildPreferences` instead, which doesn't
	 *             require manual location of the plugin's preferences element, and fires on reloads.
	 */
	static function preferencesBuilt(e:{target:Element}):Void;

	/**
	 * Called after constructing the preferences menu.
	 * You can use this to insert your plugin-specific DOM elements into it.
	 * ui.Preferences is similarly used here.
	 */
	static function projectPropertiesBuilt(e:{project:Project, target:Element}):Void;
	
	/**
	 * Called whenever instantiating a new Ace editor.
	 * You can use this to apply editor hooks/modifications.
	 */
	static function editorCreated(e:{editor:AceWrap, options:AceWrapOptions}):Void;
}
