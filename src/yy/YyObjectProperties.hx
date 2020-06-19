package yy;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import js.lib.RegExp;
import parsers.GmlObjectProperties;
import tools.NativeString;
import yy.YyJson;
import yy.YyObject;
import gml.Project;
import haxe.Json;
import tools.Aliases;
import tools.Dictionary;
import parsers.GmlReader;
import yy.YyResourceRef;

/**
 * ...
 * @author YellowAfterlife
 */
class YyObjectProperties {
	public static var propertyList:Array<String> = [
		"parent_index", "sprite_index", "mask_index",
		"visible", "solid", "persistent", "uses_physics",
		"physics_density", "physics_restitution",
		"physics_collision_group",
		"physics_linear_damping", "physics_angular_damping", "physics_friction",
		"physics_sensor", "physics_start_awake", "physics_kinematic",
		"physics_shape", "physics_shape_data",
	];
	public static var typeList:Array<String> = [
		"unknown",
		"real", "int", "string", "bool",
		"expr", "asset", "list", "color",
	];
	public static var assetTypes:Array<YyObjectPropertiesAssetFlag> = [
		new YyObjectPropertiesAssetFlag(1, "tileset"),
		new YyObjectPropertiesAssetFlag(2, "sprite"),
		new YyObjectPropertiesAssetFlag(4, "sound"),
		new YyObjectPropertiesAssetFlag(8, "path"),
		new YyObjectPropertiesAssetFlag(16, "script"),
		new YyObjectPropertiesAssetFlag(32, "shader"),
		new YyObjectPropertiesAssetFlag(64, "font"),
		new YyObjectPropertiesAssetFlag(128, "timeline"),
		new YyObjectPropertiesAssetFlag(256, "object"),
		new YyObjectPropertiesAssetFlag(512, "room"),
	];
	public static var assetTypeMap:Dictionary<Int> = {
		var dict = new Dictionary<Int>();
		for (pair in assetTypes) dict.set(pair.name, pair.flag);
		dict;
	};
	//
	private static var rxLString = new RegExp("^(?:@'[^']*?'|@\"[^\"]*?\")$");
	private static var rxJSONish = new RegExp("^[-\\d.\"]");
	public static function get(o:YyObject):String {
		var out = GmlObjectProperties.header;
		var v22 = YyTools.isV22(o);
		function addID(key:String, val:EitherType<YyResourceRef, YyGUID>):Void {
			out += '\n$key = ';
			var valid:Bool, vr:YyResourceRef;
			if (!v22) {
				vr = (val:YyResourceRef);
				if (val != null) {
					valid = vr.name != null && vr.name != "";
				} else valid = false;
			} else {
				valid = (val:YyGUID).isValid();
				vr = null;
			}
			if (valid) {
				var res = Project.current.yyResources[v22 ? val : vr.name];
				if (res != null) {
					if (v22) {
						out += res.Value.resourceName + ";";
					} else {
						out += res.id.name + ";";
					}
				} else out += '"$val"; // amiss';
			} else out += "-1;";
		}
		inline function addPrim(key:String, val:Any):Void {
			out += '\n$key = $val;';
		}
		//
		addID("parent_index", o.parentObjectId);
		if (o.spriteId.isValid()) addID("sprite_index", o.spriteId);
		var mask = v22 ? o.maskSpriteId : o.spriteMaskId;
		if (mask.isValid()) addID("mask_index", mask);
		if (!o.visible) addPrim("visible", o.visible);
		if (o.solid) addPrim("solid", o.solid);
		if (o.persistent) addPrim("persistent", o.persistent);
		addPrim("uses_physics", o.physicsObject);
		if (o.physicsObject) {
			addPrim("physics_density", o.physicsDensity);
			addPrim("physics_restitution", o.physicsRestitution);
			addPrim("physics_collision_group", o.physicsGroup);
			addPrim("physics_linear_damping", o.physicsLinearDamping);
			addPrim("physics_angular_damping", o.physicsAngularDamping);
			addPrim("physics_friction", o.physicsFriction);
			addPrim("physics_sensor", o.physicsSensor);
			addPrim("physics_start_awake", o.physicsStartAwake);
			addPrim("physics_kinematic", o.physicsKinematic);
			addPrim("physics_shape", o.physicsShape);
			var pts = [];
			if (o.physicsShapePoints != null) {
				for (pt in o.physicsShapePoints) pts.push(pt.x + ',' + pt.y);
			}
			addPrim("physics_shape_data", '"' + pts.join(";") + '"');
		}
		//
		if (o.properties != null) for (prop in o.properties) {
			out += '\n' + (v22 ? prop.varName : prop.name) + ':';
			var found = true;
			function printExpr(x:String):String {
				if (rxLString.test(x)) {
					return x;
				} else if (rxJSONish.test(x)) {
					try {
						Json.parse(x);
						return x;
					} catch (_:Dynamic) { }
				}
				//
				var q = new GmlReader(x, gml.GmlVersion.v2);
				q.skipVarExpr(gml.GmlVersion.v2, -1);
				if (q.eof) {
					return "(" + x + ")";
				} else {
					return "#" + Json.stringify(x);
				}
			}
			switch (prop.varType) {
				case 0, 1: {
					out += prop.varType == 1 ? "int" : "real";
					if (prop.rangeEnabled) {
						out += '<' + prop.rangeMin + ', ' + prop.rangeMax + '>';
					}
					out += ' = ' + prop.value;
				};
				case 2: out += 'string = ' + Json.stringify(prop.value);
				case 3: out += 'bool = ' + (prop.value == 'True' ? 'true' : 'false');
				case 4: out += 'expr = ' + printExpr(prop.value);
				case 5: {
					var flags = prop.resourceFilter;
					out += 'asset';
					if (flags != 1023) {
						out += '<';
						var count = 0;
						//
						for (pair in assetTypes) {
							if (flags & pair.flag != 0) {
								flags &= ~pair.flag;
								if (count++ > 0) out += ', ';
								out += pair.name;
							}
						}
						//
						if (flags != 0 || count == 0) {
							if (count++ > 0) out += ', ';
							out += flags;
						}
						out += '>';
					}
					out += ' = ' + prop.value;
				};
				case 6: {
					out += 'list<';
					var sep = false;
					for (item in prop.listItems) {
						if (sep) out += ', '; else sep = true;
						out += printExpr(item);
					}
					out += '> = ';
					if (prop.multiselect) {
						out += '[';
						var q = new GmlReader(prop.value);
						var sep = false;
						while (q.loop) {
							var start = q.pos;
							do {
								q.skipVarExpr(gml.GmlVersion.v2, ','.code);
								if (q.loop) {
									if (q.peek() == ",".code) {
										break;
									} else q.skip();
								}
							} while (q.loop);
							var expr = q.substring(start, q.pos);
							if (q.loop && q.peek() == ",".code) {
								q.skip();
								if (q.peek() == " ".code) q.skip();
							}
							if (sep) out += ', '; else sep = true;
							out += printExpr(expr);
						}
						out += ']';
					} else out += printExpr(prop.value);
				};
				case 7: {
					out += 'color = "' + prop.value + '"';
				};
				default: {
					var json = Json.stringify(prop);
					if (tools.NativeString.contains(json, "'")) {
						out += "unknown = " + Json.stringify(json);
					} else out += "unknown = @'" + json + "'";
				};
			}
			out += v22 ? '; // ' + prop.id : ';';
		}
		//
		return out;
	}
	static var propFieldOrder23:Array<String> = [
		"varType", "value",
		"rangeEnabled", "rangeMin", "rangeMax",
		"listItems", "multiselect",
		"filters",
	].concat(YyJsonPrinter.mvcOrder23);
	static var digitCount23:DynamicAccess<Int> = { "rangeMin": 1, "rangeMax": 1 };
	public static function set(o:YyObject, code:String) {
		var v22 = YyTools.isV22(o);
		function id(v:GmlObjectPropertiesValue, t:String):EitherType<YyGUID, YyResourceRef> {
			var id:YyGUID, res:YyProjectResource;
			inline function checkResourceType():Void {
				if (res == null) return;
				if (v22) {
					if (res.Value.resourceType != t) {
						throw 'Wrong resource type - expected $t, got ' + res.Value.resourceType;
					}
				} else {
					var pathPrefix = t.substring(2).toLowerCase() + "s/";
					if (!NativeString.startsWith(res.id.path, pathPrefix)) {
						throw 'Wrong resource type - expected $pathPrefix, got ' + res.id.path;
					}
				}
			}
			switch (v) {
				case Ident("noone"): return YyGUID.zero;
				case Number(f): {
					if (f < 0) {
						return v22 ? YyGUID.zero : null;
					} else throw "Can't assign numeric IDs aside of -1";
				};
				case CString(s): {
					if (v22 ? YyGUID.test.test(s) : s != "") {
						id = cast s;
						res = Project.current.yyResources[id];
						checkResourceType();
						return v22 ? id : res.id;
					} else throw "Expected a GUID";
				};
				case Ident(v): {
					id = Project.current.yyResourceGUIDs[v];
					if (id == null) throw 'Could not find $v in the project';
					res = Project.current.yyResources[id];
					checkResourceType();
					return v22 ? id : res.id;
				};
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
		function string(v:GmlObjectPropertiesValue):String {
			switch (v) {
				case CString(s): return s;
				default: throw 'Expected a string, got $v';
			}
		}
		function expr(v:GmlObjectPropertiesValue):String {
			switch (v) {
				case Number(f): return Json.stringify(f);
				case CString(s): return Json.stringify(s);
				case Ident(s): return s;
				case EString(s): return s;
				default: throw 'Expected an expression, got $v';
			}
		}
		//
		var props:Array<YyObjectProperty> = [];
		function propProc(name:String, type:String, guid:YyGUID, params:Array<GmlObjectPropertiesValue>, value:GmlObjectPropertiesValue):ErrorText {
			try {
				var orig:YyObjectProperty = null;
				if (o.properties != null) for (prop in o.properties) {
					if ((v22 ? prop.varName : prop.name) != name) continue;
					orig = prop;
					if (v22 && guid == null) guid = prop.id;
					break;
				}
				if (v22 && guid == null) guid = new YyGUID();
				//
				function addProp(prop:YyObjectProperty) {
					if (v22) {
						prop.id = guid;
						prop.modelName = "GMObjectProperty";
						prop.mvc = "1.0";
						prop.varName = name;
						if (prop.resourceFilter == null) {
							prop.resourceFilter = 1023;
						}
					} else {
						prop.resourceType = "GMObjectProperty";
						prop.resourceVersion = "1.0";
						prop.name = name;
						prop.hxOrder = propFieldOrder23;
						prop.hxDigits = digitCount23;
						if (prop.listItems == null) prop.listItems = [];
						if (orig == null) {
							prop.tags = [];
							prop.filters = [];
						} else {
							tools.NativeObject.fillDefaults(prop, orig);
						}
					}
					props.push(prop);
				}
				//
				switch (type) {
					case "real", "int": {
						var asInt = type == "int";
						var rangeEnabled = false;
						var rangeMin = 0.;
						var rangeMax = 10.;
						if (params != null) {
							if (params.length != 2) throw 'Expected <min, max>';
							rangeMin = asInt ? int(params[0]) : real(params[0]);
							rangeMax = asInt ? int(params[1]) : real(params[1]);
							rangeEnabled = true;
						}
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: rangeEnabled,
							rangeMax: rangeMax,
							rangeMin: rangeMin,
							value: Json.stringify(asInt ? int(value) : real(value)),
							varType: asInt ? 1 : 0,
						});
					};
					case "string", "expr": {
						if (params != null) throw type + " has no params";
						var asExpr = type == "expr";
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: asExpr ? expr(value) : string(value),
							varType: asExpr ? 4 : 2,
						});
					};
					case "asset": {
						var flags = 0x0;
						if (params != null) {
							for (param in params) switch (param) {
								case Number(f): flags |= Std.int(f);
								case Ident(s): {
									var flag = assetTypeMap[s];
									if (flag == null) throw '$s is not a known asset type';
									flags |= flag;
								};
								default: throw 'Expected an asset type, got $param';
							}
						} else flags = 1023;
						var asset = switch (value) {
							case Ident(s): s;
							case Number(f): Json.stringify(f);
							default: throw 'Expected an asset, got $value';
						};
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							resourceFilter: flags,
							value: asset,
							varType: 5,
						});
					};
					case "bool": {
						if (params != null) throw "String has no params";
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: bool(value) ? "True" : "False",
							varType: 3,
						});
					};
					case "unknown": {
						switch (value) {
							case CString(s): props.push(Json.parse(s));
							default: throw 'Expected a JSON string, got $value';
						}
					};
					case "list": {
						if (params == null) throw "List requires option parameters";
						var items = [];
						for (param in params) items.push(expr(param));
						//
						var multi = false;
						var out = "";
						switch (value) {
							case Values(a): {
								multi = true;
								var sep = false;
								for (v in a) {
									if (sep) out += ", "; else sep = true;
									out += expr(v);
								}
							};
							default: out = expr(value);
						}
						//
						addProp({
							listItems: items,
							multiselect: multi,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: out,
							varType: 6,
						});
					};
					case "color": {
						if (params != null) throw "String has no params";
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: string(value),
							varType: 7,
						});
					};
					default: throw '$type is not a known type';
				}
				return null;
			} catch (x:Dynamic) {
				return Std.string(x);
			}
		}
		function varProc(key:String, val:GmlObjectPropertiesValue):ErrorText {
			try {
				switch (key) {
					case "parent_index": o.parentObjectId = id(val, "GMObject");
					case "sprite_index": o.spriteId = id(val, "GMSprite");
					case "mask_index": {
						if (v22) {
							o.maskSpriteId = id(val, "GMSprite");
						} else {
							o.spriteMaskId = id(val, "GMSprite");
						}
					};
					case "visible": o.visible = bool(val);
					case "solid": o.solid = bool(val);
					case "persistent": o.persistent = bool(val);
					//
					case "uses_physics": o.physicsObject = bool(val);
					case "physics_density": o.physicsDensity = real(val);
					case "physics_restitution": o.physicsRestitution = real(val);
					case "physics_collision_group": o.physicsGroup = int(val);
					case "physics_linear_damping": o.physicsLinearDamping = real(val);
					case "physics_angular_damping": o.physicsAngularDamping = real(val);
					case "physics_friction": o.physicsFriction = real(val);
					case "physics_sensor": o.physicsSensor = bool(val);
					case "physics_start_awake": o.physicsStartAwake = bool(val);
					case "physics_kinematic": o.physicsKinematic = bool(val);
					case "physics_shape": o.physicsShape = int(val);
					case "physics_shape_data": {
						var sv:String = switch (val) {
							case CString(s): s;
							default: throw "Expected a data string";
						}
						var pts = sv.split(";");
						var orig = o.physicsShapePoints;
						var next = [];
						var proto = orig[0];
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
						o.physicsShapePoints = next;
					};
					//
					default: throw '$key is not a known property';
				}
				return null;
			} catch (x:Dynamic) {
				return Std.string(x);
			}
		}
		var error = GmlObjectProperties.parse(code, gml.GmlVersion.v2, varProc, propProc);
		o.properties = props.length > 0 ? props : (v22 ? null : []);
		return error;
	}
}
class YyObjectPropertiesAssetFlag {
	public var flag:Int;
	public var name:String;
	public function new(f:Int, s:String) {
		flag = f;
		name = s;
	}
}
