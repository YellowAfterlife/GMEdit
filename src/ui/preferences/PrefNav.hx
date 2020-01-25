package ui.preferences;
import js.html.Element;
import ui.Preferences.*;
import gml.GmlAPI;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefNav {
	
	public static function build(out:Element) {
		out = addGroup(out, "Navigation");
		out.id = "pref-navigation";
		var el:Element;
		//
		#if !lwedit
		addCheckbox(out, "Open assets with single click", current.singleClickOpen, function(z) {
			current.singleClickOpen = z;
			save();
			gml.Project.current.reload();
		}).title = "Allows to open treeview items with single click";
		addCheckbox(out, "Show asset thumbnails", current.assetThumbs, function(z) {
			current.assetThumbs = z;
			save();
			gml.Project.current.reload();
		}).title = "Loads and displays the assigned sprites as object thumbnails in resource tree.";
		addCheckbox(out, "Show taskbar overlays", current.taskbarOverlays, function(z) {
			current.taskbarOverlays = z;
			save();
			gml.Project.current.reload();
		}).title = "Shows GM version icon"
			+ " (or `<project path>.taskbar-overlay.png`, if available)"
			+ " over the GMEdit icon (Windows-only?)";
		//
		var eventOrder = [
			"As authored",
			"By event type",
		];
		addDropdown(out, "GMS2 object event order", eventOrder[current.eventOrder], eventOrder, function(s:String) {
			current.eventOrder = eventOrder.indexOf(s);
			save();
		});
		#end
		//
		addFloatInput(out, "Keep file sessions for (days):", current.fileSessionTime, function(v) {
			current.fileSessionTime = v; save();
		});
		#if !lwedit
		addFloatInput(out, "Keep project sessions for (days):", current.projectSessionTime, function(v) {
			current.projectSessionTime = v; save();
		});
		addIntInput(out, "Max recent project count:", current.recentProjectCount, function(v) {
			current.recentProjectCount = v; save();
		});
		var fileChangeActions = [
			"Do nothing",
			"Ask what to do",
			"Reload unless conflicting",
		];
		addDropdown(out, "If the source file changes", fileChangeActions[current.fileChangeAction], fileChangeActions, function(v) {
			current.fileChangeAction = fileChangeActions.indexOf(v); save();
		});
		#end
	}
}
