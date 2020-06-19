package gmx;
import gmx.GmxObject;
import gmx.SfGmx;
import parsers.GmlObjectProperties;
import tools.Aliases;
import yy.YyObjectProperties;

/**
 * ...
 * @author YellowAfterlife
 */
class GmxObjectProperties {
	public static var propertyList:Array<String> = [
		"parent_index", "sprite_index", "mask_index",
		"visible", "solid", "persistent", "uses_physics",
		"physics_density", "physics_restitution",
		"physics_collision_group",
		"physics_linear_damping", "physics_angular_damping", "physics_friction",
		"physics_sensor", "physics_start_awake", "physics_kinematic",
		"physics_shape", "physics_shape_data",
	];
	public static inline var noAsset:String = "<undefined>";
	
	public static function get(o:SfGmx):String {
		var out = GmlObjectProperties.header;
		function addID(key:String, val:String):Void {
			out += '\n$key = ' + (val != noAsset ? val : "-1") + ";";
		}
		function addID_opt(key:String, val:String):Void {
			if (val != noAsset) out += '\n$key = $val;';
		}
		inline function addPrim(key:String, val:Any):Void {
			out += '\n$key = $val;';
		}
		function addPrim_opt(key:String, val:Any, def:Any):Void {
			if (val != def) out += '\n$key = $val;';
		}
		addID("parent_index", o.findText("parentName"));
		addID_opt("sprite_index", o.findText("spriteName"));
		addID_opt("mask_index", o.findText("maskName"));
		addPrim_opt("visible", o.findInt("visible") != 0, true);
		addPrim_opt("solid", o.findInt("solid") != 0, false);
		addPrim_opt("persistent", o.findInt("persistent") != 0, false);
		var usesPhysics = o.findInt("PhysicsObject") != 0;
		addPrim("uses_physics", usesPhysics);
		if (usesPhysics) {
			addPrim("physics_density", o.findFloat("PhysicsObjectDensity"));
			addPrim("physics_restitution", o.findFloat("PhysicsObjectRestitution"));
			addPrim("physics_collision_group", o.findInt("PhysicsObjectGroup"));
			addPrim("physics_linear_damping", o.findFloat("PhysicsObjectLinearDamping"));
			addPrim("physics_angular_damping", o.findFloat("PhysicsObjectAngularDamping"));
			addPrim("physics_friction", o.findFloat("PhysicsObjectFriction"));
			addPrim("physics_sensor", o.findInt("PhysicsObjectSensor") != 0);
			addPrim("physics_start_awake", o.findInt("PhysicsObjectAwake") != 0);
			addPrim("physics_kinematic", o.findInt("PhysicsObjectKinematic") != 0);
			addPrim("physics_shape", o.findInt("PhysicsObjectShape"));
			var pts = [];
			var gmxPts = o.find("PhysicsShapePoints");
			if (gmxPts != null) for (pt in gmxPts.children) pts.push(pt.text);
			addPrim("physics_shape_data", '"' + pts.join(";") + '"');
		}
		return out;
	}
	public static function set(o:SfGmx, code:GmlCode):ErrorText {
		function id(v:GmlObjectPropertiesValue):String {
			switch (v) {
				case Ident("noone"): return noAsset;
				case Number(f): {
					if (f < 0) return noAsset;
					throw "Can't assign numeric IDs aside of -1";
				};
				case CString(s): return s;
				case Ident(v): return v;
				default: throw 'Expected an identifier, got ' + v.getName();
			}
		}
		function bool(v:GmlObjectPropertiesValue):Bool {
			switch (v) {
				case Number(1), Ident("true"): return true;
				case Number(0), Ident("false"): return false;
				default: throw 'Expected a bool, got $v';
			}
		}
		function int(v:GmlObjectPropertiesValue):Int {
			switch (v) {
				case Number(f): {
					if (f % 1 != 0) throw 'Expected an int, got $v';
					return Std.int(f);
				};
				default: throw 'Expected an int, got $v';
			}
		}
		function real(v:GmlObjectPropertiesValue):Float {
			switch (v) {
				case Number(f): return f;
				default: throw 'Expected a number, got $v';
			}
		}
		//
		inline function setID(name:String, val:GmlObjectPropertiesValue) {
			o.setChildText(name, id(val));
		}
		inline function setBool(name:String, val:GmlObjectPropertiesValue) {
			o.setChildInt(name, bool(val) ? -1 : 0);
		}
		inline function setInt(name:String, val:GmlObjectPropertiesValue) {
			o.setChildInt(name, int(val));
		}
		inline function setFloat(name:String, val:GmlObjectPropertiesValue) {
			o.setChildFloat(name, real(val));
		}
		function varProc(key:String, val:GmlObjectPropertiesValue):ErrorText {
			try {
				switch (key) {
					case "parent_index": setID("parentName", val);
					case "sprite_index": setID("spriteName", val);
					case "mask_index": setID("maskName", val);
					case "visible": setBool("visible", val);
					case "solid": setBool("solid", val);
					case "persistent": setBool("persistent", val);
					//
					case "uses_physics": setBool("PhysicsObject", val);
					case "physics_density": setFloat("PhysicsObjectDensity", val);
					case "physics_restitution": setFloat("PhysicsObjectRestitution", val);
					case "physics_collision_group": setInt("PhysicsObjectGroup", val);
					case "physics_linear_damping": setFloat("PhysicsObjectLinearDamping", val);
					case "physics_angular_damping": setFloat("PhysicsObjectAngularDamping", val);
					case "physics_friction": setFloat("PhysicsObjectFriction", val);
					case "physics_sensor": setBool("PhysicsObjectSensor", val);
					case "physics_start_awake": setBool("PhysicsObjectAwake", val);
					case "physics_kinematic": setBool("PhysicsObjectKinematic", val);
					case "physics_shape": setInt("PhysicsObjectShape", val);
					case "physics_shape_data": {
						var sv:String = switch (val) {
							case CString(s): s;
							default: throw "Expected a data string";
						}
						var pts = sv.split(";");
						var next:Array<SfGmx> = [];
						for (i in 0 ... pts.length) {
							var ptText = pts[i];
							var ptPair = ptText.split(",");
							if (ptPair.length != 2) throw 'Expected two coordinates for point $i';
							//
							var ptX = Std.parseFloat(ptPair[0]);
							if (Math.isNaN(ptX)) throw 'X coordinate for point $i is not a valid number (${ptPair[0]}).';
							var ptY = Std.parseFloat(ptPair[1]);
							if (Math.isNaN(ptY)) throw 'Y coordinate for point $i is not a valid number (${ptPair[1]}).';
							//
							next.push(new SfGmx("point", '$ptX,$ptY'));
						}
						var ptsGmx = o.find("PhysicsShapePoints");
						ptsGmx.clearChildren();
						for (pt in next) ptsGmx.addChild(pt);
					};
					//
					default: throw '$key is not a known property';
				}
				return null;
			} catch (x:Dynamic) {
				return Std.string(x);
			}
		}
		var error = GmlObjectProperties.parse(code, gml.GmlVersion.v1, varProc);
		return error;
	}
}