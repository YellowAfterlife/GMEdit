package yy;
import tools.Dictionary;
import haxe.DynamicAccess;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract YyJsonMeta(YyJsonMetaImpl) from YyJsonMetaImpl {
	static function initByModelName():Dictionary<YyJsonMeta> {
		var q = new Dictionary<YyJsonMeta>();
		var base = ["configDeltas", "id", "modelName", "mvc", "name"];
		//
		inline function tt(o:Dynamic):Dictionary<String> { return o; }
		inline function td(o:Dynamic):DynamicAccess<Int> { return o; }
		//
		q["GMProject"] = {
			order: base.concat(["IsDnDProject", "configs", "option_ecma", "parentProject", "resources", "script_order", "tutorial"]),
			types: tt({
				resources: "GMProjectResourcePair",
			}),
		};
		q["GMProjectParent"] = {
			order: base.concat(["alteredResources", "hiddenResources", "projectPath"]),
			types: tt({
				alteredResources: "GMProjectResourcePair",
				hiddenResources: "GMProjectResourcePair",
			}),
		};
		q["GMProjectResourcePair"] = {
			order: base.concat(["Key", "Value"]),
			types: tt({ Value: "GMProjectResource" }),
		};
		q["GMProjectResource"] = {
			order: base.concat(["resourcePath", "resourceType"]),
		}
		//
		return q;
	}
	static function initByResourceType():Dictionary<YyJsonMeta> {
		var q = new Dictionary<YyJsonMeta>();
		var base = ["parent", "resourceVersion", "name", "tags", "resourceType"];
		//
		inline function tt(o:Dynamic):Dictionary<String> { return o; }
		inline function td(o:Dynamic):DynamicAccess<Int> { return o; }
		function td1(fields:Array<String>):DynamicAccess<Int> {
			var r = new DynamicAccess();
			for (f in fields) r[f] = 1;
			return r;
		}
		//
		q["GMScript"] = {
			order: ["isDnD", "isCompatibility"].concat(base),
		};
		//
		q["GMObject"] = {
			order: ["spriteId", "solid", "visible", "spriteMaskId", "persistent", "parentObjectId", "physicsObject", "physicsSensor", "physicsShape", "physicsGroup", "physicsDensity", "physicsRestitution", "physicsLinearDamping", "physicsAngularDamping", "physicsFriction", "physicsStartAwake", "physicsKinematic", "physicsShapePoints", "eventList", "properties", "overriddenProperties"].concat(base),
			digits: td1(["physicsDensity", "physicsRestitution", "physicsLinearDamping", "physicsAngularDamping", "physicsFriction"]),
		};
		q["GMEvent"] = {
			order: ["isDnD", "eventNum", "eventType", "collisionObjectId"].concat(base),
		};
		q["GMMoment"] = {
			order: ["moment", "evnt"].concat(base),
		};
		//{ room
		q["GMRoom"] = {
			order: [
				"isDnd", "volume", "parentRoom",
				"views", "layers", "inheritLayers",
				"creationCodeFile", "inheritCode",
				"instanceCreationOrder", "inheritCreationOrder",
				"sequenceId", "roomSettings", "viewSettings", "physicsSettings",
			].concat(base),
			types: tt({
				views: "GMRoomView",
				instanceCreationOrder: "GMRoomCreationOrder",
				roomSettings: "GMRoomSettings",
				viewSettings: "GMRoomViewSettings",
				physicsSettings: "GMRoomPhysicsSettings",
			}),
			digits: td({ volume: 1 }),
		};
		q["GMRoomView"] = {
			order: ["inherit", "visible", "xview", "yview", "wview", "hview", "xport", "yport", "wport", "hport", "hborder", "vborder", "hspeed", "vspeed", "objectId"]
		};
		q["GMRoomCreationOrder"] = {
			order: ["name", "path"],
		};
		q["GMRoomSettings"] = {
			order: ["inheritRoomSettings", "Width", "Height", "persistent"],
		};
		q["GMRoomViewSettings"] = {
			order: ["inheritViewSettings", "enableViews", "clearViewBackground", "clearDisplayBuffer"],
		};
		q["GMRoomPhysicsSettings"] = {
			order: ["inheritPhysicsSettings", "PhysicsWorld", "PhysicsWorldGravityX", "PhysicsWorldGravityY", "PhysicsWorldPixToMetres"],
			digits: td1(["PhysicsWorldGravityX", "PhysicsWorldGravityY","PhysicsWorldPixToMetres"]),
		};
		//
		var layerBase = ["visible", "depth", "userdefinedDepth", "inheritLayerDepth", "inheritLayerSettings", "gridX", "gridY", "layers", "hierarchyFrozen"].concat(base);
		q["GMRInstanceLayer"] = {
			order: ["instances"].concat(layerBase)
		};
		q["GMRBackgroundLayer"] = {
			order: ["spriteId", "colour", "x", "y", "htiled", "vtiled", "hspeed", "vspeed", "stretch", "animationFPS", "animationSpeedType", "userdefinedAnimFPS"].concat(layerBase),
			digits: td1(["hspeed", "vspeed", "animationFPS"]),
		};
		//}
		//
		return q;
	}
}

typedef YyJsonMetaImpl = {
	?order:Array<String>,
	/**
	 * field name -> field resource type
	 * note: for arrays, sets type for contents
	 */
	?types:Dictionary<String>,
	/** field name -> digits for numeric output */
	?digits:DynamicAccess<Int>,
};