package file.kind.gmk;

import editors.EditCode;
import electron.FileWrap;
import file.kind.KGml;
import gmk.GmkAction;
import gmk.GmkEvent;
import gmk.GmkObject;
import gml.GmlLocals;
import gml.Project;
import gmx.GmxObjectProperties;
import gmx.SfGmx;
import haxe.io.Path;
import parsers.GmlSeekData;
import parsers.GmlSeeker;
import ui.treeview.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmkEvents extends file.kind.gml.KGmlEvents {
	public static var inst:KGmkEvents = new KGmkEvents();
	
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var path = editor.file.path;
		if (data == null) data = FileWrap.readTextFileSync(path);
		var gmx = Std.is(data, String) ? SfGmx.parse(data) : data;
		var out = GmkObject.getCode(gmx, editor.file.path);
		if (out == null) {
			return editor.setLoadError(GmkObject.errorText);
		} else return out;
	}
	
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var path = editor.file.path;
		var root = FileWrap.readGmxFileSync(path);
		if (!GmkObject.setCode(root, path, code)) {
			editor.setSaveError("Can't update XML:\n" + GmkObject.errorText);
			return null;
		}
		return root.toGmxString();
	}
	
	override public function index(path:String, content:String, main:String):Bool {
		var obj = SfGmx.parse(content);
		var out = new GmlSeekData();
		//
		var parentName = obj.findText("parent");
		if (parentName != null) {
			var objectName = Path.withoutExtension(Path.withoutExtension(Path.withoutDirectory(path)));
			GmlSeeker.addObjectChild(parentName, objectName);
		}
		//
		if (ui.Preferences.current.assetThumbs) {
			var sprite = obj.findText("sprite");
			if (sprite != null) {
				var frameURL = Project.current.getSpriteURL(sprite);
				if (frameURL != null) TreeView.setThumb(path, frameURL);
			}
		}
		//
		var dir = Path.withExtension(path, "events");
		if (FileWrap.existsSync(dir)) for (entry in FileWrap.readdirSync(dir)) {
			var event = FileWrap.readGmxFileSync(entry.relPath);
			var name = GmkEvent.toStringGmk(event);
			if (GmkEvent.isEmpty(event)) continue;
			var locals = new GmlLocals(name);
			var code = GmkEvent.getCode(event);
			out.locals.set(name, locals);
			if (code != null) {
				GmlSeeker.runSyncImpl(path, code, null, out, locals, this);
			}
		}
		//
		/*{ // hack: use locals for properties-specific variables
			var locals = new GmlLocals();
			out.locals.set("properties", locals);
			for (prop in GmxObjectProperties.propertyList) {
				locals.add(prop, "property.variable", "(object property)");
			}
		};*/
		//
		GmlSeeker.finish(path, out);
		return true;
	}
}