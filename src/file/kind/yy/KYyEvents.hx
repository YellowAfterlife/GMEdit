package file.kind.yy;
import ace.extern.AceAutoCompleteItem;
import editors.EditCode;
import electron.FileWrap;
import file.kind.KGml;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import haxe.Json;
import parsers.GmlSeekData;
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
		if (data == null) {
			data = YyJson.parse(super.loadCode(editor, data));
		} else if (data is String) {
			data = YyJson.parse(data);
		}
		var obj:YyObject = data;
		var file = editor.file;
		NativeArray.clear(file.extraFiles);
		return obj.getCode(file.path, file.extraFiles);
	}
	override public function postproc(editor:EditCode, code:String):String {
		code = super.postproc(editor, code);
		if (code == null) return null;
		var origText = FileWrap.readTextFileSync(editor.file.path);
		var obj:YyObject = YyJson.parse(origText);
		var oldText = YyJson.stringify(obj, Project.current.yyExtJson);
		if (!obj.setCode(editor.file.path, code)) {
			editor.setSaveError("Can't update YY:\n" + YyObject.errorText);
			return null;
		}
		// if only field order changed, use original text:
		var newText = YyJson.stringify(obj, Project.current.yyExtJson);
		if (newText == oldText) return origText;
		return newText;
	}
	override public function index(path:String, content:String, main:String, sync:Bool):Bool {
		return runSync(path, content, sync);
	}
	public static function runSync(orig:String, src:String, allSync:Bool) {
		var obj:YyObject = YyJson.parse(src);
		var dir = Path.directory(orig);
		var project = Project.current;
		var v23 = project.isGMS23;
		//
		var parentName:String;
		var par = obj.parentObjectId;
		if (v23) {
			parentName = JsTools.nca(par, (par:YyResourceRef).name);
		} else {
			parentName = JsTools.nca(par, project.yyObjectNames[(par:YyGUID)]);
		}
		if (parentName != null) GmlSeeker.addObjectChild(parentName, obj.name);
		//
		if (ui.Preferences.current.assetThumbs && !allSync) {
			var spriteId = obj.spriteId;
			if (v23) {
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
		var out = new GmlSeekData(inst);
		var eventsLeft = 0;
		var eventFiles = [];
		for (event in obj.eventList) {
			var ed = event.unpack(obj);
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
		
		//
		out.addObjectHint(obj.name, parentName);
		function getPropType(prop:YyObjectProperty):GmlType {
			switch (prop.varType) {
				case TInt: return GmlTypeDef.int;
				case TReal: return GmlTypeDef.number;
				case TString: return GmlTypeDef.string;
				case TBool: return GmlTypeDef.bool;
				case TAsset:
					var et = [];
					if (v23) {
						var filters = prop.filters.map((s) -> NativeString.trimBoth(s));
						if (YyObjectProperties.isAllAssetTypes23(filters) || filters.length == 0) return GmlTypeDef.asset;
						for (ft in prop.filters) {
							ft = NativeString.trimBoth(ft);
							et.push(GmlTypeDef.simple(ft.substring(2).toLowerCase()));
						}
					} else {
						var flags = prop.resourceFilter;
						if (flags == 1023 || flags == 0) return GmlTypeDef.asset;
						for (tp in YyObjectProperties.assetTypes) {
							if ((flags & tp.flag) == 0) continue;
							et.push(GmlTypeDef.simple(tp.name));
						}
					}
					if (et.length > 1) {
						return GmlType.TEither(et);
					} else if (et.length == 1) {
						return et[0];
					} else return null;
				case TColor: return GmlTypeDef.simple("color");
				default: return null;
			}
		}
		if (obj.properties != null) for (prop in obj.properties) {
			var fdName = v23 ? prop.name : prop.varName;
			var fdType = getPropType(prop);
			var compText = (
				"variable definition\n" +
				"from " + obj.name
			);
			if (fdType != null) compText += "\ntype " + fdType.toString();
			var comp = new AceAutoCompleteItem(fdName, "variable", compText);
			var hint = new GmlSeekDataHint(obj.name, true, fdName, comp, null, parentName, fdType);
			out.fieldHints[hint.key] = hint;
		}
		
		// quick exit if there are no events:
		if (eventFiles.length == 0) {
			GmlSeeker.finish(orig, out);
			return true;
		}
		
		// process events:
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
		//
		return false;
	}
}
