package gmx;
import gml.Project;
import gml.file.GmlFileExtra;
import gmx.GmxLoader;
import gmx.SfGmx;
import haxe.io.Path;
import parsers.GmlMultifile;
import tools.Dictionary;
using tools.NativeString;
using tools.PathTools;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxRooms {
	public static var errorText:String;
	public static function getCCs(pjPath:String, pjRoot:SfGmx, extraFiles:Array<GmlFileExtra>):String {
		var rxName = GmxLoader.rxAssetName;
		var project = Project.current;
		var out = "";
		function loadRec(node:SfGmx) {
			if (node.name == "room") {
				var prefix = node.text;
				var name = rxName.replace(prefix, "$1");
				var rel = prefix + ".room.gmx";
				var room = project.readGmxFileSync(rel);
				var rcc = room.findText("code");
				if (rcc == "") return;
				
				if (out != "") out += "\n\n";
				out += "#target " + name + "\n" + rcc;
				extraFiles.push(new GmlFileExtra(project.fullPath(rel)));
			} else {
				for (sub in node.children) loadRec(sub);
			}
		}
		for (node in pjRoot.findAll("rooms")) loadRec(node);
		return out;
	}
	public static function setCCs(pjPath:String, code:String, extraFiles:Array<GmlFileExtra>):Bool {
		var project = Project.current;
		var pairs = GmlMultifile.split(code, "", "target");
		var first = pairs[0];
		if (first.name == "") {
			if (first.code.trimBoth() != "") {
				errorText = "There's code prior to first room creation code!\n" + first.code;
				return false;
			}
			pairs.shift();
		}
		
		//
		var found = new Map();
		for (pair in pairs) {
			var name = pair.name;
			if (found.exists(name)) {
				errorText = 'Room creation code for "$name" is defined twice!';
				return true;
			}
			found[name] = true;
		}
		
		// remove:
		var xi = extraFiles.length;
		var xmap = new Dictionary();
		while (--xi >= 0) {
			var xf = extraFiles[xi];
			var xp = new Path(xf.path);
			var name = xp.file.ptNoExt(); // double extension because of .room.gmx
			xmap[name] = true;
			if (found[name]) continue;
			
			var rel = 'rooms/$name.room.gmx';
			if (!project.existsSync(rel)) continue;
			
			var room = project.readGmxFileSync(rel);
			var node = room.find("code");
			if (node.text != "") {
				node.text = "";
				project.writeGmxFileSync(rel, room);
				Console.log('Deleted creation code for "$name".');
			}
		}
		
		// add/update:
		for (pair in pairs) {
			var name = pair.name;
			var rel = 'rooms/$name.room.gmx';
			if (!project.existsSync(rel)) {
				errorText = 'Room "$name" doesn\'t exist!';
				return false;
			}
			var room = project.readGmxFileSync(rel);
			var node = room.find("code");
			if (node.text != pair.code) {
				node.text = pair.code;
				project.writeGmxFileSync(rel, room);
				Console.log('Updated creation code for "$name".');
			} else {
				//Console.log('Creation code for "$name" is unchanged.');
			}
		}
		
		//
		return true;
	}
}