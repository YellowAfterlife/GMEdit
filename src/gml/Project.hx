package gml;
import ace.AceWrap.AceAutoCompleteItem;
import electron.FileSystem;
import electron.Electron;
import haxe.io.Path;
import js.Boot;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;
import tools.Dictionary;
import gml.GmlAPI;
import ace.AceWrap;
import gmx.SfGmx;
import Main.*;
import tools.HtmlTools;
import gml.GmlFile;
import ui.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class Project {
	//
	public static var current:Project = null;
	//
	public static var nameNode = document.querySelector("#project-name");
	//
	public var version:GmlVersion = GmlVersion.v1;
	public var name:String;
	public var path:String;
	public var dir:String;
	//
	public function new(path:String) {
		this.path = path;
		dir = Path.directory(path);
		name = Path.withoutDirectory(path);
		if (Path.extension(path) == "yy") version = GmlVersion.v2;
		document.title = name;
		TreeView.clear();
		reload();
	}
	//
	public function reload() {
		nameNode.innerText = "Loading...";
		window.setTimeout(function() {
			GmlAPI.version = version;
			TreeView.saveOpen();
			reload_1();
			TreeView.restoreOpen();
			nameNode.innerText = "";
		}, 1);
	}
	public function reload_1() {
		switch (version) {
			case GmlVersion.v1: gmx.GmxLoader.run(this);
			default:
		}
	}
}
