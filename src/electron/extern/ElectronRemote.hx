package electron.extern;
import electron.AppTools;
import electron.Menu;
import electron.extern.BrowserWindow;

/**
 * ...
 * @author YellowAfterlife
 */
extern class ElectronRemote {
	var dialog:Dynamic;
	var Menu:Class<Menu>;
	var MenuItem:Class<MenuItem>;
	var app:Class<AppTools>;
	function getCurrentWindow():BrowserWindow;
	var BrowserWindow:Class<BrowserWindow>;
}