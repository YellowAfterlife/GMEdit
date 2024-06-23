package gmk.snips;
import file.FileKind;
import file.kind.misc.KPlain;
import gml.Project;
import gml.GmlAPI;
import haxe.io.Path;
import parsers.GmlSeeker;
import ui.treeview.TreeView;
import file.kind.gml.*;
import file.kind.gmk.*;
using StringTools;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkSnipsLoader {
	public static function run(project:Project){
		GmlSeeker.start();
		GmlAPI.gmlClear();
		GmlAPI.extClear();
		TreeView.clear();
		
		var text = project.readTextFileSync(project.name);
		text = text.replace("\r", "");
		var lines = text.split("\n");
		
		if (true) {
			var rel = project.name;
			var full = project.path;
			var lfItem = TreeView.makeAssetItem(rel, rel, full, "datafile");
			lfItem.yyOpenAs = KGmkSnips.inst;
			TreeView.element.appendChild(lfItem);
		}
		
		project.resourceTypes = new tools.Dictionary();
		var seekSoon = [];
		for (line in lines) {
			if (line.startsWith("#")) continue;
			if (line.startsWith(">")) continue;
			if (line.trim() == "") continue;
			
			var ms = line.indexOf(">");
			var rel:String, meta:String;
			if (ms != -1) {
				meta = line.substring(ms + 1).ltrim();
				rel = line.substring(0, ms).rtrim();
			} else {
				rel = line;
				meta = null;
			}
			Console.log(line, rel, meta);
			
			var openAs:FileKind = null;
			var indexKind:FileKind = null;
			var kind = "script";
			if (rel.ptExt() == "gml") {
				switch (rel.ptExt2()) {
					case "object": indexKind = KGmkSnipsEvents.inst;
					default: indexKind = KGmlScript.inst;
				}
			} else continue;
			
			var name = Path.withoutDirectory(rel);
			var full = project.fullPath(rel);
			if (indexKind != null) seekSoon.push({ full: full, name: name, kind: indexKind });
			//
			var tvItem = TreeView.makeAssetItem(name, rel, full, kind);
			if (openAs != null) tvItem.yyOpenAs = openAs;
			TreeView.element.appendChild(tvItem);
		}
		
		for (item in seekSoon) {
			GmlSeeker.run(item.full, item.name, item.kind);
		}
	}
}