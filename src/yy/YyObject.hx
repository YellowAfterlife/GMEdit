package yy;
import electron.FileSystem;
import parsers.GmlEvent;
import gml.GmlFile;
import haxe.io.Path;
import tools.Dictionary;
import tools.NativeString;
import ui.TreeView;

/**
 * ...
 * @author YellowAfterlife
 */
@:forward abstract YyObject(YyObjectImpl) from YyObjectImpl to YyObjectImpl {
	public static var errorText:String;
	public function getCode(objPath:String):String {
		var dir = Path.directory(objPath);
		var out = "";
		var errors = "";
		// GMS2 doesn't sort events so not doing anything means
		// that the events will maintain order as authored.
		/*var evOrder:Dictionary<Int> = new Dictionary();
		var evCount = 0;
		for (ev in this.eventList) evOrder.set(ev.id, evCount++);
		this.eventList.sort(function(a, b) {
			var at = a.eventtype, bt = b.eventtype;
			if (at != bt) return at - bt;
			//
			if (at == gmx.GmxEvent.typeCollision) {
				return evOrder[a.id] - evOrder[b.id];
			} else return a.enumb - b.enumb;
		});*/
		//
		for (ev in this.eventList) {
			var eid = ev.id;
			var oid = ev.collisionObjectId;
			var type = ev.eventtype;
			var numb = ev.enumb;
			var rel = YyEvent.toPath(type, numb, eid);
			var name = YyEvent.toString(type, numb, oid);
			var full = Path.join([dir, rel]);
			var code = FileSystem.readTextFileSync(full);
			if (out != "") out += "\n\n";
			out += "#event " + name + "\n" + NativeString.trimRight(code);
		}
		return out;
	}
	public function setCode(objPath:String, gmlCode:String) {
		var dir = Path.directory(objPath);
		//
		var eventData = GmlEvent.parse(gmlCode, gml.GmlVersion.v2);
		if (eventData == null) {
			errorText = GmlEvent.parseError;
			return false;
		}
		// resolve object GUIDs, leave if that doesn't work out:
		var errors = "";
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
				enumb: idat.numb,
				collisionObjectId: idat.obj,
				m_owner: this.id,
			};
			newMap.set(newName, ev);
			newList.push({ event: ev, code: item.code[0] });
		}
		// remove event files that are no longer used:
		for (i in 0 ... oldList.length) if (!newMap.exists(oldNames[i])) {
			var ev = oldList[i];
			var full = Path.join([dir, YyEvent.toPath(ev.eventtype, ev.enumb, ev.id)]);
			if (FileSystem.existsSync(full)) FileSystem.unlinkSync(full);
		}
		// write used event files:
		this.eventList = [];
		for (item in newList) {
			var ev = item.event;
			var full = Path.join([dir, YyEvent.toPath(ev.eventtype, ev.enumb, ev.id)]);
			FileSystem.writeFileSync(full, item.code);
			this.eventList.push(ev);
		}
		//
		return true;
	}
	public static function openEventInherited(full:String, edef:String):GmlFile {
		var edata = YyEvent.fromString(edef);
		if (edata == null) return null;
		var etype = edata.type;
		var enumb = edata.numb;
		var eobj = edata.obj; if (eobj == null) eobj = YyGUID.zero;
		//
		var obj:YyObject = FileSystem.readJsonFileSync(full);
		var parentId = obj.parentObjectId;
		var tries = 1024;
		while (parentId != YyGUID.zero && --tries >= 0) {
			var parentName = gml.Project.current.yyObjectNames[parentId];
			if (parentName == null) return null;
			// todo: have an actual asset name -> asset path lookup instead
			var el = TreeView.element.querySelector('.item['
				+ TreeView.attrIdent + '="' + NativeString.escapeProp(parentName) + '"]');
			if (el == null) return null;
			var path = el.getAttribute(TreeView.attrPath);
			if (!FileSystem.existsSync(path)) return null;
			obj = FileSystem.readJsonFileSync(path);
			for (event in obj.eventList) {
				if (event.eventtype == etype
				&& event.enumb == enumb
				&& event.collisionObjectId == eobj) {
					return GmlFile.open(parentName, path, { def: edef });
				}
			}
			parentId = obj.parentObjectId;
		}
		return null;
	}
}
typedef YyObjectImpl = {
	>YyBase,
	name:String,
	eventList:Array<YyObjectEvent>,
	parentObjectId:YyGUID,
}
typedef YyObjectEvent = {
	>YyBase,
	eventtype:Int,
	enumb:Int,
	collisionObjectId:YyGUID,
	m_owner:YyGUID,
	IsDnD:Bool,
}
