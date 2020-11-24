package file.kind.yy;
import editors.EditCode;
import electron.FileWrap;
import file.kind.KGml;
import haxe.Json;
import tools.NativeArray;
import tools.NativeString;
import yy.YyObject;
import yy.YyJson;
import yy.YyGUID;
import haxe.io.Path;
import parsers.*;
import gml.*;
import yy.*;
import ui.treeview.TreeView;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class KYyEvents extends file.kind.gml.KGmlEvents {
	public static var inst:KYyEvents = new KYyEvents();
	override public function loadCode(editor:EditCode, data:Dynamic):String {
		if (data == null) data = YyJson.parse(super.loadCode(editor, data));
		var obj:YyObject = data;
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		return obj.getCode(file.path, file.extraFiles);
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var obj:YyObject = FileWrap.readYyFileSync(editor.file.path);
		if (!obj.setCode(editor.file.path, code)) {
			editor.setSaveError("Can't update YY:\n" + YyObject.errorText);
			return null;
		}
		//
		return YyJson.stringify(obj, Project.current.yyExtJson);
	}
	override public function index(path:String, content:String, main:String):Bool {
		return runSync(path, content, false);
	}
	public static function runSync(orig:String, src:String, allSync:Bool) {
		var obj:YyObject = YyJson.parse(src);
		var dir = Path.directory(orig);
		//
		var project = Project.current;
		var parentName = project.yyObjectNames[obj.parentObjectId];
		if (parentName != null) GmlSeeker.addObjectChild(parentName, obj.name);
		//
		if (ui.Preferences.current.assetThumbs && !allSync) {
			var spriteId = obj.spriteId;
			if (project.isGMS23) {
				if (spriteId != null) {
					TreeView.setThumbSprite(orig, (cast spriteId:YyResourceRef).name);
				} else TreeView.resetThumb(orig);
			} else {
				if (spriteId.isValid()) {
					var res = project.yyResources[spriteId];
					TreeView.setThumbSprite(orig, res != null ? res.Value.resourceName : null);
				} else TreeView.resetThumb(orig);
			}
		}
		//
		var out = new GmlSeekData();
		var eventsLeft = 0;
		var eventFiles = [];
		for (event in obj.eventList) {
			var ed = event.unpack();
			var rel = YyEvent.toPath(ed.type, ed.num, ed.id);
			var full = Path.join([dir, rel]);
			var name = YyEvent.toString(ed.type, ed.num, ed.obj);
			eventsLeft += 1;
			eventFiles.push({
				name: name,
				full: full,
			});
		}
		{ // hack: use locals for properties-specific variables
			var locals = new GmlLocals("properties");
			out.locals.set("properties", locals);
			for (prop in YyObjectProperties.propertyList) {
				locals.add(prop, "property.variable", "(object property)");
			}
			for (prop in YyObjectProperties.typeList) {
				locals.add(prop, "property.namespace", "(object variable type)");
			}
			for (pair in YyObjectProperties.assetTypes) {
				locals.add(pair.name, "property.namespace", "(asset type)");
			}
		};
		if (eventFiles.length == 0) {
			GmlSeeker.finish(orig, out);
			return true;
		}
		for (file in eventFiles) (function(name, full) {
			if (!allSync) {
				function procEvent(err, code) {
					if (err == null) try {
						var locals = new GmlLocals(name);
						out.locals.set(name, locals);
						GmlSeeker.runSyncImpl(orig, code, null, out, locals, KYyEvents.inst);
					} catch (_:Dynamic) {
						//
					}
					if (--eventsLeft <= 0) {
						GmlSeeker.finish(orig, out);
						GmlSeeker.runNext();
					}
				}
				FileWrap.readTextFile(full, procEvent);
			} else try {
				var code = FileWrap.readTextFileSync(full);
				var locals = new GmlLocals(name);
				out.locals.set(name, locals);
				GmlSeeker.runSyncImpl(orig, code, null, out, locals, KYyEvents.inst);
			} catch (_:Dynamic) {
				//
			}
		})(file.name, file.full);
		if (allSync) GmlSeeker.finish(orig, out);
		return false;
	}
}
