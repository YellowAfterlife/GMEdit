package yy;
import haxe.extern.EitherType;
/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract YyObjectEvent(YyObjectEventImpl) from YyObjectEventImpl to YyObjectEventImpl {
	public static var fieldOrder = [
		"isDnD",
		"eventNum",
		"eventType",
		"collisionObjectId",
		"parent",
		"resourceType",
		"name",
		"tags",
		"resourceVersion",
	];
	public static function compare(a:YyObjectEvent, b:YyObjectEvent):Int {
		if (YyTools.isV22(a)) {
			var at = a.eventtype, bt = b.eventtype;
			if (at != bt) return at - bt;
			//
			if (at == 4) { // collision
				return (a.id:String) < (b.id:String) ? -1 : 1;
			} else return a.enumb - b.enumb;
		} else {
			var at = a.eventType, bt = b.eventType;
			if (at != bt) return at - bt;
			//
			if (at == 4) {
				var aq:YyObjectEventColId = a.collisionObjectId;
				var bq:YyObjectEventColId = a.collisionObjectId;
				return aq.name < bq.name ? -1 : 1;
			} else return a.eventNum - b.eventNum;
		}
	}
	public inline function unpack():YyObjectEventData {
		var id:String, obj:String, num:Int, type:Int;
		if (YyTools.isV22(this)) {
			id = this.id;
			obj = this.collisionObjectId;
			num = this.enumb;
			type = this.eventtype;
		} else {
			var col:YyObjectEventColId = this.collisionObjectId;
			id = (col != null ? col.name : null);
			obj = id;
			num = this.eventNum;
			type = this.eventType;
		}
		return { id: id, obj: obj, num: num, type: type };
	}
}
@:forward abstract YyObjectEventData(YyObjectEventDataImpl)
from YyObjectEventDataImpl to YyObjectEventDataImpl {
	public inline function getPath():String {
		return YyEvent.toPath(this.type, this.num, this.id);
	}
	public inline function getName():String {
		return YyEvent.toString(this.type, this.num, this.obj);
	}
}
typedef YyObjectEventDataImpl = {
	id:String,
	obj:String,
	num:Int,
	type:Int,
};
typedef YyObjectEventImpl = {
	>YyBase,
	collisionObjectId:EitherType<YyGUID, YyObjectEventColId>,
	// older:
	?IsDnD:Bool,
	?eventtype:Int,
	?enumb:Int,
	?m_owner:YyGUID,
	// newer:
	?isDnD:Bool,
	?eventType:Int,
	?eventNum:Int,
	?tags:Array<String>,
	?name:String, // always null?
};
typedef YyObjectEventColId = { name:String, path:String };
