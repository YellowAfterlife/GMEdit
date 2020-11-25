package file.kind.gmx;
import editors.EditCode;
import electron.FileWrap;
import gmx.GmxObject;
import gmx.SfGmx;
import parsers.*;
import ui.*;
import haxe.io.Path;
import ui.treeview.TreeView;
import gmx.*;
import gml.Project;
import gml.GmlLocals;

/**
 * ...
 * @author YellowAfterlife
 */
class KGmxEvents extends file.kind.gml.KGmlEvents {
	public static var inst:KGmxEvents = new KGmxEvents();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		var root = SfGmx.parse(super.loadCode(editor, data));
		var out = GmxObject.getCode(root);
		if (out == null) {
			return editor.setLoadError(GmxObject.errorText);
		} else return out;
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var root = FileWrap.readGmxFileSync(editor.file.path);
		if (!GmxObject.setCode(root, code)) {
			editor.setSaveError("Can't update GMX:\n" + GmxObject.errorText);
			return null;
		}
		return root.toGmxString();
	}
	override public function index(path:String, content:String, main:String):Bool {
		var obj = SfGmx.parse(content);
		var out = new GmlSeekData();
		//
		var objectName = Path.withoutExtension(Path.withoutExtension(Path.withoutDirectory(path)));
		var parentName = obj.findText("parentName");
		if (parentName != "<undefined>") {
			GmlSeeker.addObjectChild(parentName, objectName);
		}
		//
		if (Preferences.current.assetThumbs) {
			var sprite = obj.findText("spriteName");
			if (sprite != "<undefined>") {
				var framePath = Path.join(["sprites", "images", sprite + "_0.png"]);
				var frameURL = Project.current.getImageURL(framePath);
				if (frameURL != null) TreeView.setThumb(path, frameURL);
			}
		}
		//
		out.addObjectHint(objectName, parentName);
		for (events in obj.findAll("events"))
		for (event in events.findAll("event")) {
			var etype = Std.parseInt(event.get("eventtype"));
			var ename = event.get("ename");
			var enumb:Int = ename == null ? Std.parseInt(event.get("enumb")) : null;
			var name = GmxEvent.toString(etype, enumb, ename);
			var locals = new GmlLocals(name);
			out.locals.set(name, locals);
			for (action in event.findAll("action")) {
				var code = GmxAction.getCode(action);
				if (code != null) {
					GmlSeeker.runSyncImpl(path, code, null, out, locals, this);
				}
			}
		}
		//
		{ // hack: use locals for properties-specific variables
			var locals = new GmlLocals("properties");
			out.locals.set("properties", locals);
			for (prop in GmxObjectProperties.propertyList) {
				locals.add(prop, "property.variable", "(object property)");
			}
		};
		//
		GmlSeeker.finish(path, out);
		return true;
	}
}
