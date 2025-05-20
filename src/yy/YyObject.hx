package yy;
import electron.FileWrap;
import gml.GmlObjectInfo;
import haxe.Json;
import haxe.extern.EitherType;
import js.lib.RegExp;
import js.html.Console;
import parsers.GmlEvent;
import gml.file.GmlFile;
import gml.file.GmlFileExtra;
import gml.Project;
import haxe.io.Path;
import tools.Aliases;
import tools.Dictionary;
import tools.NativeArray;
import tools.NativeString;
import tools.JsTools;
import ui.treeview.TreeView;
import ace.AceMacro.jsRx;
import yy.YyGUID;
import yy.YyObjectEvent;
import yy.YyResourceRef;
import yy.YyTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract YyObject(YyObjectImpl) from YyObjectImpl to YyObjectImpl {
	public static var errorText:String;
	
	public function getCode(objPath:String, ?extras:Array<GmlFileExtra>):String {
		var dir = Path.directory(objPath);
		var out = YyObjectProperties.get(this);
		var errors = "";
		// GMS2 doesn't sort events so not doing anything means
		// that the events will maintain order as authored.
		if (ui.Preferences.current.eventOrder == 1) {
			this.eventList.sort(YyObjectEvent.compare);
		}
		//
		for (event in this.eventList) {
			var ed = event.unpack(this);
			var rel = ed.getPath();
			var name = ed.getName();
			var full = Path.join([dir, rel]);
			if (extras != null) extras.push(new GmlFileExtra(full));
			var code = try {
				FileWrap.readTextFileSync(full);
			} catch (x:Dynamic) {
				Console.warn("Missing event file: " + full);
				"";
			}
			if (out != "") out += "\n\n";
			var pair = parsers.GmlHeader.parse(code, gml.GmlVersion.v2);
			out += "#event " + name;
			if (pair.name != null) out +=  pair.name;
			out += "\n" + pair.code;
		}
		return out;
	}
	
	public function setCode(objPath:String, gmlCode:String) {
		var dir = Path.directory(objPath);
		var sorted = ui.Preferences.current.eventOrder == 1;
		var v22 = YyTools.isV22(this);
		var project = Project.current;
		
		//
		var eventData:GmlEventList = GmlEvent.parse(gmlCode, gml.GmlVersion.v2);
		if (eventData == null) {
			errorText = GmlEvent.parseError;
			return false;
		}
		
		// process and purge properties pseudo-event:
		var errors = "";
		NativeArray.filterSelf(eventData, function(item) {
			var idat:GmlEventData = item.data;
			if (idat.type != GmlEvent.typeMagic) return true;
			if (idat.numb != GmlEvent.kindMagicProperties) return true;
			var err = YyObjectProperties.set(this, item.code.join("\n"));
			if (err != null) errors += err;
			return false;
		});
		
		// resolve object GUIDs, leave if that doesn't work out:
		for (item in eventData) {
			var idat = item.data;
			if (idat.type == GmlEvent.typeCollision) {
				var obj = project.yyObjectGUIDs[idat.name];
				if (obj == null) {
					errors += "Couldn't find object " + idat.name + " for collision event.\n";
				} else idat.obj = obj;
			} else idat.obj = YyGUID.getDefault(v22);
		}
		if (errors != "") {
			errorText = errors;
			return false;
		}
		
		// fill out oldList/oldMap so that we can tell what existed before:
		var oldList = this.eventList;
		var oldMap = new Dictionary<YyObjectEvent>();
		var oldNames:Array<String> = [];
		for (ev in oldList) {
			var ed = ev.unpack(this);
			var oldName = ed.getName();
			oldNames.push(oldName);
			oldMap.set(oldName, ev);
		}
		
		// form a new event list:
		var newList:Array<{ event:YyObjectEvent, code:GmlCode }> = [];
		var newMap = new Dictionary<Array<GmlCode>>();
		var newNames:Array<String> = [];
		for (item in eventData) {
			var idat = item.data;
			var name = YyEvent.toString(idat.type, idat.numb, idat.obj);
			newNames.push(name);
			newMap.set(name, item.code);
		}
		
		//
		for (i in 0 ... oldList.length) {
			if (newMap.exists(oldNames[i])) {
				// if we're sorting events, we want the existing ones in original
				// order and then the new ones, so we'll add them in first pass
				if (sorted) newList.push({ event: oldList[i], code: newMap[oldNames[i]].join("\r\n") });
			} else {
				// remove event files that are no longer used
				var rel = oldList[i].unpack(this).getPath();
				var full = Path.join([dir, rel]);
				if (FileWrap.existsSync(full)) FileWrap.unlinkSync(full);
			}
		}
		
		// form newly introduced events:
		var v2022_8 = project.yyResourceVersion >= 1.6;
		for (i in 0 ... eventData.length) {
			var ename = newNames[i];
			if (sorted && oldMap.exists(ename)) continue; // see above
			var item = eventData[i];
			var idat = item.data;
			var ev:YyObjectEvent = sorted ? null : oldMap[ename];
			if (ev != null) {
				// OK!
			}
			else if (v22) {
				ev = {
					id: new YyGUID(),
					modelName: "GMEvent",
					mvc: "1.0",
					IsDnD: false,
					collisionObjectId: idat.obj,
					eventtype: idat.type,
					enumb: idat.numb != null ? idat.numb : 0,
					m_owner: this.id,
				};
			} else {
				var obj = idat.obj;
				var col:YyResourceRef;
				if (v2022_8 && idat.type == GmlEvent.typeCollision && obj == this.name) {
					col = null;
				} else if (obj == null || obj == "") {
					col = null;
				} else {
					col = { name:obj, path:'objects/$obj/$obj.yy' };
				};
				ev = {
					resourceType: "GMEvent",
					resourceVersion: "1.0",
					isDnD: false,
					eventType: idat.type,
					eventNum: idat.numb != null ? idat.numb : 0,
					name: "",
				};
				if (project.isGM2024) {
					if (project.isGM2024_8) {
						Reflect.setField(ev, "$GMEvent", "v1");
					} else {
						Reflect.setField(ev, "$GMEvent", "");
					}
					Reflect.setField(ev, "%Name", "");
					ev.resourceVersion = "2.0";
				}
				ev.collisionObjectId = col;
				if (!v2022_8) {
					ev.parent = { name: this.name, path: 'objects/${this.name}/${this.name}.yy' };
					ev.tags = [];
				}
			}
			newList.push({ event: ev, code: item.code.join("\r\n") });
		}
		
		// write used event files:
		this.eventList = [];
		for (item in newList) {
			var ev = item.event;
			var full = Path.join([dir, ev.unpack(this).getPath()]);
			FileWrap.writeTextFileSync(full, item.code);
			this.eventList.push(ev);
		}
		
		//
		return true;
	}
	private function getParentJson():YyObject {
		var parentName:String;
		if (this.parentObjectId == null) {
			parentName = null;
		} else if (this.parentObjectId is String) {
			parentName = Project.current.yyObjectNames[this.parentObjectId];
		} else {
			parentName = (this.parentObjectId:YyResourceRef).name;
		}
		if (parentName == null) return null;
		// todo: have an actual asset name -> asset path lookup instead
		var el = TreeView.element.querySelector('.item['
			+ TreeView.attrIdent + '="' + NativeString.escapeProp(parentName) + '"]');
		if (el == null) return null;
		var path = el.getAttribute(TreeView.attrPath);
		if (!FileWrap.existsSync(path)) return null;
		var json:YyObject = FileWrap.readYyFileSync(path);
		json.path = path;
		return json;
	}
	public static function openEventInherited(full:String, edef:String):GmlFile {
		var edata = YyEvent.fromString(edef);
		if (edata == null) return null;
		var etype = edata.type;
		var enumb = edata.numb;
		var eobj = edata.obj;
		var obj:YyObject = FileWrap.readYyFileSync(full);
		var v22 = YyTools.isV22(obj);
		//
		var parentId:String;
		inline function setParentId() {
			if (obj.parentObjectId == null) {
				parentId = null;
			} else if (obj.parentObjectId is String) {
				parentId = obj.parentObjectId;
				if (parentId == YyGUID.zero) parentId = null;
			} else {
				parentId = (obj.parentObjectId:YyResourceRef).name;
				if (parentId == "") parentId = null;
			}
		}
		setParentId();
		var tries = 1024;
		while (parentId != null && --tries >= 0) {
			obj = obj.getParentJson();
			if (obj == null) return null;
			for (event in obj.eventList) {
				if (event.unpack(obj).getName() == edef) {
					return GmlFile.open(obj.name, obj.path, { def: edef });
				}
			}
			setParentId();
		}
		return null;
	}
	public function getInfo(?info:GmlObjectInfo):GmlObjectInfo {
		var objName = this.name;
		var v23 = Project.current.isGMS23;
		if (info == null) {
			info = new GmlObjectInfo();
			info.objectName = objName;
			if (Reflect.isObject(this.spriteId)) {
				info.spriteName = (cast this.spriteId:YyResourceRef).name;
			} else if (this.spriteId.isValid()) {
				var res = Project.current.yyResources[this.spriteId];
				if (res != null) {
					info.spriteName = res.Value.resourceName;
				} else info.spriteName = this.spriteId;
			} else info.spriteName = "<undefined>";
			info.visible = this.visible;
			info.solid = this.solid;
			info.persistent = this.persistent;
		}
		//
		for (event in this.eventList) {
			var eid:String;
			if (v23) {
				var cor:YyResourceRef = event.collisionObjectId;
				var co = cor != null ? cor.name : null;
				eid = GmlEvent.toString(event.eventType, event.eventNum, co);
			} else {
				eid = YyEvent.toString(event.eventtype, event.enumb, event.collisionObjectId);
			}
			var elist = info.eventMap[eid];
			if (elist == null) {
				elist = [];
				info.eventList.push(eid);
				info.eventMap.set(eid, elist);
			}
			elist.unshift(objName + "(" + eid + ")");
		}
		//
		var parent = getParentJson();
		if (parent != null) {
			info.parents.unshift(parent.name);
			parent.getInfo(info);
		}
		//
		return info;
	}
}
typedef YyObjectImpl = {
	>YyResource,
	?path:String,
	spriteId:YyGUID,
	/** older */
	?maskSpriteId:YyGUID,
	/** newer */
	?spriteMaskId:YyGUID,
	eventList:Array<YyObjectEvent>,
	parentObjectId:EitherType<YyResourceRef, YyGUID>,
	solid:Bool,
	visible:Bool,
	persistent:Bool,
	properties:Array<YyObjectProperty>,
	overriddenProperties:Array<YyObjectPropertyOverride>,
	physicsObject:Bool,
	
	physicsDensity:Float,
	physicsRestitution:Float,
	physicsGroup:Int,
	physicsLinearDamping:Float,
	physicsAngularDamping:Float,
	physicsFriction:Float,
	
	physicsSensor:Bool,
	physicsStartAwake:Bool,
	physicsKinematic:Bool,
	
	physicsShape:Int,
	physicsShapePoints:Array<YyObjectPhysicsShapePoint>,
	?managed:Bool,
};
typedef YyObjectPhysicsShapePoint = {
	>YyBase, // GMPoint 1.0
	x:Float, y:Float,
};
typedef YyObjectProperty = YyBase & {
	?listItems:Array<String>,
	multiselect:Bool,
	rangeEnabled:Bool,
	rangeMax:Float,
	rangeMin:Float,
	/** 2.2? */
	?resourceFilter:Int,
	/** 2.3 */
	?filters:Array<String>,
	/** if multi-select: `"A", "B"` */
	value:String,
	varType:YyObjectPropertyType,
	/** 2.2 */
	?varName:String,
	/** 2.3 */
	?name:String,
};
typedef YyObjectPropertyOverride = YyBase & {
	propertyId:YyResourceRef,
	objectId:YyResourceRef,
	value:String,
	?name:String, // unused
};
enum abstract YyObjectPropertyType(Int) {
	var TReal = 0;
	var TInt = 1;
	var TString = 2;
	var TBool = 3;
	var TExpr = 4;
	var TAsset = 5;
	var TList = 6;
	var TColor = 7;
}