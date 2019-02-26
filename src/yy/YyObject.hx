package yy;
import electron.FileWrap;
import gml.GmlObjectInfo;
import haxe.extern.EitherType;
import js.RegExp;
import parsers.GmlEvent;
import gml.file.GmlFile;
import gml.file.GmlFileExtra;
import gml.Project;
import haxe.io.Path;
import parsers.GmlObjectProperties;
import tools.Aliases;
import tools.Dictionary;
import tools.NativeArray;
import tools.NativeString;
import ui.treeview.TreeView;
import ace.AceMacro.jsRx;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract YyObject(YyObjectImpl) from YyObjectImpl to YyObjectImpl {
	public static var errorText:String;
	public static var propertyList:Array<String> = [
		"parent_index", "sprite_index", "mask_index",
		"visible", "solid", "persistent", "uses_physics",
		"physics_density", "physics_restitution",
		"physics_collision_group",
		"physics_linear_damping", "physics_angular_damping",
		"physics_sensor", "physics_start_awake", "physics_kinematic",
		"physics_shape", "physics_shape_data",
	];
	public function getProperties():String {
		var out = GmlObjectProperties.header;
		function addID(key:String, val:YyGUID):Void {
			out += '\n$key = ';
			if (val != YyGUID.zero) {
				var res = Project.current.yyResources[val];
				if (res != null) {
					out += res.Value.resourceName + ";";
				} else out += '"$val"; // amiss';
			} else out += "-1;";
		}
		inline function addPrim(key:String, val:Any):Void {
			out += '\n$key = $val;';
		}
		//
		addID("parent_index", this.parentObjectId);
		if (this.spriteId != YyGUID.zero) addID("sprite_index", this.spriteId);
		if (this.maskSpriteId != YyGUID.zero) addID("mask_index", this.maskSpriteId);
		if (!this.visible) addPrim("visible", this.visible);
		if (this.solid) addPrim("solid", this.solid);
		if (this.persistent) addPrim("persistent", this.persistent);
		addPrim("uses_physics", this.physicsObject);
		if (this.physicsObject) {
			addPrim("physics_density", this.physicsDensity);
			addPrim("physics_restitution", this.physicsRestitution);
			addPrim("physics_collision_group", this.physicsGroup);
			addPrim("physics_linear_damping", this.physicsLinearDamping);
			addPrim("physics_angular_damping", this.physicsAngularDamping);
			addPrim("physics_sensor", this.physicsSensor);
			addPrim("physics_start_awake", this.physicsStartAwake);
			addPrim("physics_kinematic", this.physicsKinematic);
			addPrim("physics_shape", this.physicsShape);
			var pts = [];
			for (pt in this.physicsShapePoints) pts.push(pt.x + ',' + pt.y);
			addPrim("physics_shape_data", '"' + pts.join(";") + '"');
		}
		//
		return out;
	}
	private static var setProperties_str:RegExp = jsRx(~/^@?["'](.*?)["']$/);
	public function setProperties(code:String):ErrorText {
		return GmlObjectProperties.parse(code, v2, function(key:String, val:String):ErrorText {
			function id(v:String, t:String):YyGUID {
				if (v == "noone") return YyGUID.zero;
				var ind = Std.parseInt(v);
				if (ind != null) {
					if (ind < 0) {
						return YyGUID.zero;
					} else throw "Can't assign numeric IDs aside of -1";
				}
				var mt = setProperties_str.exec(v);
				var id:YyGUID, res:YyProjectResource;
				if (mt != null) {
					if (YyGUID.test.test(mt[1])) {
						id = cast mt[1];
						res = Project.current.yyResources[id];
						if (res != null && res.Value.resourceType != t) {
							throw 'Wrong resource type - expected $t, got ' + res.Value.resourceType;
						}
						return id;
					} else throw "Expected a GUID";
				} else {
					id = Project.current.yyResourceGUIDs[v];
					if (id == null) throw 'Could not find $v in the project';
					res = Project.current.yyResources[id];
					if (res != null && res.Value.resourceType != t) {
						throw 'Wrong resource type - expected $t, got ' + res.Value.resourceType;
					}
					return id;
				}
			}
			function bool(v:String):Bool {
				switch (v) {
					case "1", "true": return true;
					case "0", "false": return false;
					default: throw 'Expected a bool, got $v';
				}
			}
			function int(v:String):Int {
				var i = Std.parseInt(v);
				if (i != null) return i;
				throw 'Expected an int, got $v';
			}
			function real(v:String):Float {
				var f = Std.parseFloat(v);
				if (Math.isNaN(f)) throw 'Expected a number, got $v';
				return f;
			}
			try {
				switch (key) {
					case "parent_index": this.parentObjectId = id(val, "GMObject");
					case "sprite_index": this.spriteId = id(val, "GMSprite");
					case "mask_index": this.maskSpriteId = id(val, "GMSprite");
					case "visible": this.visible = bool(val);
					case "solid": this.solid = bool(val);
					case "persistent": this.persistent = bool(val);
					case "uses_physics": this.physicsObject = bool(val);
					
					case "physics_density": this.physicsDensity = real(val);
					case "physics_restitution": this.physicsRestitution = real(val);
					case "physics_collision_group": this.physicsGroup = int(val);
					case "physics_linear_damping": this.physicsLinearDamping = real(val);
					case "physics_angular_damping": this.physicsAngularDamping = real(val);
					case "physics_sensor": this.physicsSensor = bool(val);
					case "physics_start_awake": this.physicsStartAwake = bool(val);
					case "physics_kinematic": this.physicsKinematic = bool(val);
					case "physics_shape": this.physicsShape = int(val);
					case "physics_shape_data": {
						var mt = setProperties_str.exec(val);
						if (mt != null) val = mt[1];
						var pts = val.split(";");
						var orig = this.physicsShapePoints;
						var next = [];
						var proto = orig[0];
						for (i in 0 ... pts.length) {
							var ptText = pts[i];
							var ptPair = ptText.split(",");
							if (ptPair.length != 2) throw 'Expected two coordinates for point $i';
							var ptX = real(ptPair[0]);
							var ptY = real(ptPair[1]);
							var pt = orig[i];
							if (pt == null) {
								if (proto != null) {
									pt = Reflect.copy(proto);
									pt.id = new YyGUID();
									pt.x = ptX;
									pt.y = ptY;
								} else pt = {
									id: new YyGUID(),
									modelName: "GMPoint",
									mvc: "1.0",
									x: ptX,
									y: ptY,
								};
							} else {
								pt.x = ptX;
								pt.y = ptY;
							}
							next.push(pt);
						}
						this.physicsShapePoints = next;
					};
					default: throw '$key is not a known property';
				}
				return null;
			} catch (x:Dynamic) {
				return Std.string(x);
			}
		});
	}
	
	public function getCode(objPath:String, ?extras:Array<GmlFileExtra>):String {
		var dir = Path.directory(objPath);
		var out = getProperties();
		var errors = "";
		// GMS2 doesn't sort events so not doing anything means
		// that the events will maintain order as authored.
		if (ui.Preferences.current.eventOrder == 1) {
			var evOrder:Dictionary<Int> = new Dictionary();
			var evCount = 0;
			for (ev in this.eventList) evOrder.set(ev.id, evCount++);
			this.eventList.sort(function(a, b) {
				var at = a.eventtype, bt = b.eventtype;
				if (at != bt) return at - bt;
				//
				if (at == 4) { // collision
					return evOrder[a.id] - evOrder[b.id];
				} else return a.enumb - b.enumb;
			});
		}
		//
		for (ev in this.eventList) {
			var eid = ev.id;
			var oid = ev.collisionObjectId;
			var type = ev.eventtype;
			var numb = ev.enumb;
			var rel = YyEvent.toPath(type, numb, eid);
			var name = YyEvent.toString(type, numb, oid);
			var full = Path.join([dir, rel]);
			if (extras != null) extras.push(new GmlFileExtra(full));
			var code = FileWrap.readTextFileSync(full);
			if (out != "") out += "\n\n";
			var pair = parsers.GmlHeader.parse(code, v2);
			out += "#event " + name;
			if (pair.name != null) out +=  pair.name;
			out += "\n" + pair.code;
		}
		return out;
	}
	public function setCode(objPath:String, gmlCode:String) {
		var dir = Path.directory(objPath);
		//
		var eventData:GmlEventList = GmlEvent.parse(gmlCode, gml.GmlVersion.v2);
		if (eventData == null) {
			errorText = GmlEvent.parseError;
			return false;
		}
		//
		var errors = "";
		NativeArray.filterSelf(eventData, function(item) {
			var idat:GmlEventData = item.data;
			if (idat.type != GmlEvent.typeMagic) return true;
			if (idat.numb != GmlEvent.kindMagicProperties) return true;
			var err = setProperties(item.code.join("\n"));
			if (err != null) errors += err;
			return false;
		});
		// resolve object GUIDs, leave if that doesn't work out:
		for (item in eventData) {
			var idat = item.data;
			if (idat.type == GmlEvent.typeCollision) {
				var obj = gml.Project.current.yyObjectGUIDs[idat.name];
				if (obj == null) {
					errors += "Couldn't find object " + idat.name + " for collision event.\n";
				} else idat.obj = obj;
			} else idat.obj = YyGUID.zero;
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
			var oldName = YyEvent.toString(ev.eventtype, ev.enumb, ev.collisionObjectId);
			oldNames.push(oldName);
			oldMap.set(oldName, ev);
		}
		//
		var newList:Array<{ event:YyObjectEvent, code:String }> = [];
		var newMap = new Dictionary<YyObjectEvent>();
		for (item in eventData) {
			var idat = item.data;
			// try to reuse existing events where possible:
			var newName = YyEvent.toString(idat.type, idat.numb, idat.obj);
			var ev = oldMap[newName];
			if (ev == null) ev = {
				id: new YyGUID(),
				modelName: "GMEvent",
				mvc: "1.0",
				IsDnD: false,
				eventtype: idat.type,
				enumb: idat.numb != null ? idat.numb : 0,
				collisionObjectId: idat.obj,
				m_owner: this.id,
			};
			newMap.set(newName, ev);
			newList.push({ event: ev, code: item.code.join("\r\n") });
		}
		// remove event files that are no longer used:
		for (i in 0 ... oldList.length) if (!newMap.exists(oldNames[i])) {
			var ev = oldList[i];
			var full = Path.join([dir, YyEvent.toPath(ev.eventtype, ev.enumb, ev.id)]);
			if (FileWrap.existsSync(full)) FileWrap.unlinkSync(full);
		}
		// write used event files:
		this.eventList = [];
		for (item in newList) {
			var ev = item.event;
			var full = Path.join([dir, YyEvent.toPath(ev.eventtype, ev.enumb, ev.id)]);
			FileWrap.writeTextFileSync(full, item.code);
			this.eventList.push(ev);
		}
		//
		return true;
	}
	private function getParentJson():YyObject {
		var parentName = gml.Project.current.yyObjectNames[this.parentObjectId];
		if (parentName == null) return null;
		// todo: have an actual asset name -> asset path lookup instead
		var el = TreeView.element.querySelector('.item['
			+ TreeView.attrIdent + '="' + NativeString.escapeProp(parentName) + '"]');
		if (el == null) return null;
		var path = el.getAttribute(TreeView.attrPath);
		if (!FileWrap.existsSync(path)) return null;
		var json:YyObject = FileWrap.readJsonFileSync(path);
		json.path = path;
		return json;
	}
	public static function openEventInherited(full:String, edef:String):GmlFile {
		var edata = YyEvent.fromString(edef);
		if (edata == null) return null;
		var etype = edata.type;
		var enumb = edata.numb;
		var eobj = edata.obj; if (eobj == null) eobj = YyGUID.zero;
		//
		var obj:YyObject = FileWrap.readJsonFileSync(full);
		var parentId = obj.parentObjectId;
		var tries = 1024;
		while (parentId != YyGUID.zero && --tries >= 0) {
			obj = obj.getParentJson();
			if (obj == null) return null;
			for (event in obj.eventList) {
				if (event.eventtype == etype
				&& event.enumb == enumb
				&& event.collisionObjectId == eobj) {
					return GmlFile.open(obj.name, obj.path, { def: edef });
				}
			}
			parentId = obj.parentObjectId;
		}
		return null;
	}
	public function getInfo(?info:GmlObjectInfo):GmlObjectInfo {
		var objName = this.name;
		if (info == null) {
			info = new GmlObjectInfo();
			info.objectName = objName;
			if (this.spriteId != YyGUID.zero) {
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
			var eid = YyEvent.toString(event.eventtype, event.enumb, event.collisionObjectId);
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
	>YyBase,
	?path:String,
	spriteId:YyGUID,
	maskSpriteId:YyGUID,
	name:String,
	eventList:Array<YyObjectEvent>,
	parentObjectId:YyGUID,
	solid:Bool,
	visible:Bool,
	persistent:Bool,
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
};
typedef YyObjectPhysicsShapePoint = {
	>YyBase, // GMPoint 1.0
	x:Float, y:Float,
};
typedef YyObjectEvent = {
	>YyBase,
	eventtype:Int,
	enumb:Int,
	collisionObjectId:YyGUID,
	m_owner:YyGUID,
	IsDnD:Bool,
}
