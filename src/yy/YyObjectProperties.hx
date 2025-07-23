package yy;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import js.lib.RegExp;
import parsers.GmlObjectProperties;
import tools.JsTools;
import tools.NativeObject;
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
		"any", "expr", "asset", "list", "mlist", "color",
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
	public static var assetTypeMap:Dictionary<Int> = (function() {
		var dict = new Dictionary<Int>();
		for (pair in assetTypes) dict.set(pair.name, pair.flag);
		return dict;
	})();
	static var allAssetTypes23:Array<String>;
	public static function isAllAssetTypes23(filters:Array<String>):Bool {
		var allTypes = allAssetTypes23;
		return (filters.length == allTypes.length
			&& filters.filter((s) -> (allTypes.indexOf(s) < 0)).length == 0
		);
	}
	static var assetTypeMap23:Dictionary<String> = (function() {
		var dict = new Dictionary<String>();
		var all = [];
		function add(a:String, b:String):Void {
			all.push(a);
			dict[a] = b;
			dict[b] = a;
		}
		add("GMAnimCurve", "anim_curve");
		add("GMFont", "font");
		add("GMObject", "object");
		add("GMPath", "path");
		add("GMRoom", "room");
		add("GMScript", "script");
		add("GMSequence", "sequence");
		add("GMShader", "shader");
		add("GMSound", "sound");
		add("GMSprite", "sprite");
		add("GMTileSet", "tileset");
		add("GMTimeline", "timeline");
		allAssetTypes23 = all;
		return dict;
	})();
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
				if (!v22) {
					if (res != null) {
						out += res.id.name + ";";
					} else {
						out += vr.name + ";";
					}
				} else {
					if (res != null) {
						out += res.Value.resourceName + ";";
					} else {
						out += '"$val"; // amiss'; // puts a GUID in quotes
					}
				}
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
			q.skipVarExpr(gml.GmlVersion.v2, ",".code);
			if (q.eof) {
				return "(" + x + ")";
			} else {
				return "#" + Json.stringify(x);
			}
		}
		if (o.properties != null) for (prop in o.properties) {
			out += '\n' + (v22 ? prop.varName : prop.name) + ':';
			var found = true;
			switch (prop.varType) {
				case TReal, TInt: {
					var isInt = prop.varType == TInt;
					out += isInt ? "int" : "real";
					if (prop.rangeEnabled) {
						out += '<' + prop.rangeMin + ', ' + prop.rangeMax + '>';
					}
					out += ' = ' + printExpr(prop.value);
				};
				case TString: out += 'string = ' + Json.stringify(prop.value);
				case TBool: out += 'bool = ' + (prop.value == 'True' ? 'true' : 'false');
				case TExpr: out += 'any = ' + printExpr(prop.value);
				case TAsset: {
					out += 'asset';
					if (v22) {
						var flags = prop.resourceFilter;
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
					} else {
						var filters:Array<String> = prop.filters;
						for (i => v in filters) filters[i] = NativeString.trimBoth(v);
						var isAll = isAllAssetTypes23(filters);
						var atm = assetTypeMap23;
						if (!isAll) {
							out += "<";
							var found = 0;
							for (t in filters) {
								if (found++ > 0) out += ", ";
								out += atm.defget(t, t);
							}
							if (found == 0) out += "0";
							out += ">";
						}
					}
					out += ' = ' + printExpr(prop.value);
				};
				case TList: {
					out += prop.multiselect ? 'mlist<' : 'list<';
					var sep = false;
					for (item in prop.listItems) {
						if (sep) out += ', '; else sep = true;
						out += printExpr(item);
					}
					out += '> = ';
					out += printExpr(prop.value);
				};
				case TColor: {
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
		if (!v22 && o.overriddenProperties != null) for (ov in o.overriddenProperties) {
			out += "\n" + ov.objectId.name + "." +ov.propertyId.name + " = " + printExpr(ov.value) + ";";
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
	static var overPropFieldOrder23:Array<String> = [
		"propertyId", "objectId", "value",
	].concat(YyJsonPrinter.mvcOrder23);
	static var digitCount23:DynamicAccess<Int> = { "rangeMin": 1, "rangeMax": 1 };
	public static function set(o:YyObject, code:String) {
		var v22 = YyTools.isV22(o);
		function id(v:GmlObjectPropertiesValue, t:String):EitherType<YyResourceRef, YyGUID> {
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
		var overProps:Array<YyObjectPropertyOverride> = [];
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
						var project = Project.current;
						prop.resourceVersion = project.isGM2024_8 ? "2.0" : "1.0";
						if (project.isGM2024_8) {
							Reflect.setField(prop, "$GMObjectProperty", "v1");
						}
						prop.name = name;
						prop.hxOrder = propFieldOrder23;
						prop.hxDigits = digitCount23;
						if (prop.listItems == null) prop.listItems = [];
						if (orig == null) {
							prop.tags = [];
							prop.filters = [];
						} else {
							NativeObject.fillDefaults(prop, orig);
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
							value: asInt ? Json.stringify(int(value)) : expr(value),
							varType: asInt ? TInt : TReal,
						});
					};
					case "string", "any", "expr": {
						if (params != null) throw type + " has no params";
						var asExpr = type != "string";
						addProp({
							listItems: null,
							multiselect: false,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: asExpr ? expr(value) : string(value),
							varType: asExpr ? TExpr : TString,
						});
					};
					case "asset": {
						var asset = switch (value) {
							case Ident(s): s;
							case Number(f): Json.stringify(f);
							case EString(s): s;
							default: throw 'Expected an asset, got $value';
						};
						if (v22) {
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
							addProp({
								listItems: null,
								multiselect: false,
								rangeEnabled: false,
								rangeMax: 10,
								rangeMin: 0,
								resourceFilter: flags,
								value: asset,
								varType: TAsset,
							});
						} else {
							var filters:Array<String>;
							if (params != null) {
								filters = [];
								for (param in params) switch (param) {
									case Ident(s): filters.push(assetTypeMap23.defget(s, s));
									case Number(0): {};
									default: throw 'Expected an asset type, got $param';
								}
							} else filters = allAssetTypes23.copy();
							// replicating 2.3.0/2.3.1 bugs:
							for (i => v in filters) if (i > 0) filters[i] = " " + v;
							//
							addProp({
								listItems: null,
								multiselect: false,
								rangeEnabled: false,
								rangeMax: 10,
								rangeMin: 0,
								filters: filters,
								value: asset,
								varType: TAsset,
							});
						}
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
							varType: TBool,
						});
					};
					case "unknown": {
						switch (value) {
							case CString(s): props.push(Json.parse(s));
							default: throw 'Expected a JSON string, got $value';
						}
					};
					case "list", "mlist": {
						var multi = type == "mlist";
						if (params == null) throw "List requires option parameters";
						var items = [];
						for (param in params) items.push(expr(param));
						//
						var out = expr(value);
						//
						addProp({
							listItems: items,
							multiselect: multi,
							rangeEnabled: false,
							rangeMax: 10,
							rangeMin: 0,
							value: out,
							varType: TList,
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
							varType: TColor,
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
						var pts = sv != "" ? sv.split(";") : [];
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
		function overProc(object:String, field:String, val:GmlObjectPropertiesValue):ErrorText {
			try {
				if (v22) return "Property overrides are not supported for GMS2.2";
				var ovpOrig:YyObjectPropertyOverride = null;
				if (o.overriddenProperties != null) for (ovp in o.overriddenProperties) {
					if (ovp.objectId.name != object) continue;
					if (ovp.propertyId.name != field) continue;
					ovpOrig = ovp;
					break;
				}
				var path = 'objects/$object/$object.yy';
				var ovp:YyObjectPropertyOverride = {
					propertyId: {
						name: field,
						path: path,
					},
					objectId: {
						name: object,
						path: path,
					},
					value: expr(val),
					resourceVersion: "1.0",
					resourceType: "GMOverriddenProperty"
				};
				if (ovpOrig == null) {
					ovp.name = "";
					ovp.tags = [];
				} else NativeObject.fillDefaults(ovp, ovpOrig);
				overProps.push(ovp);
				return null;
			} catch (x:Dynamic) {
				return Std.string(x);
			}
		}
		var error = GmlObjectProperties.parse(code, gml.GmlVersion.v2, varProc, propProc, overProc);
		o.properties = props.length > 0 ? props : (v22 ? null : []);
		o.overriddenProperties = overProps;
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
