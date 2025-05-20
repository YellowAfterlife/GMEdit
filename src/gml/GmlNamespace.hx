package gml;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import tools.ArrayMap;
import tools.ArrayMapSync;
import tools.Dictionary;
import ace.extern.*;

/**
 * A namespace is a set of static and/or instance fields belonging to some context.
 * It is used for both syntax highlighting and auto-completion.
 * @author YellowAfterlife
 */
class GmlNamespace {
	public static var blank(default, null):GmlNamespace = new GmlNamespace("");
	public static inline var maxDepth = 128;
	
	public var name:String;
	
	/**
	 * Whether this namespace represents an object
	 * (and will have built-ins highlighted/shown in auto-completion)
	 */
	public var isObject:Bool = false;
	
	/**
	 * Whether this can be cast to `struct` constraint-type.
	 * Defaults to `true` for user types and `false` for built-ins.
	 */
	public var canCastToStruct:Bool = true;
	
	/**
	 * Whether assigning `undefined` to this type is allowed.
	 */
	public var isNullable:Bool = false;
	
	/**
	 * If set to true, you cannot reference type<> for this namespace
	 */
	public var noTypeRef:Bool = false;
	
	public var avoidHighlight:Bool = false;
	
	/**
	 * Parent namespace, if any
	 */
	public var parent:GmlNamespace = null;
	
	/**
	 * Interfaces that this namespace implements.
	 */
	public var interfaces:ArrayMap<GmlNamespace> = new ArrayMap();
	
	/** Whether -1 can be assigned to this type - used for built-in index-based types */
	public var minus1able:Bool = false;
	
	public var staticKind:Dictionary<AceTokenType> = new Dictionary();
	public var staticTypes:Dictionary<GmlType> = new Dictionary();
	/** static (`Buffer.ptr`) completions */
	public var compStatic:ArrayMap<AceAutoCompleteItem> = new ArrayMap();
	public var docStaticMap:Dictionary<GmlFuncDoc> = new Dictionary();
	
	public var instKind:Dictionary<AceTokenType> = new Dictionary();
	public function getInstKind(field:String, depth:Int = 0):AceTokenType {
		var q = this, n = depth;
		while (q != null && ++n <= maxDepth) {
			var t = q.instKind[field];
			if (t != null) return t;
			if (q.isObject) {
				t = GmlAPI.stdInstKind[field];
				if (t != null) return t;
			}
			for (qi in q.interfaces.array) {
				t = qi.getInstKind(field, n);
				if (t != null) return t;
			}
			q = q.parent;
		}
		return null;
	}
	
	public var instTypes:Dictionary<GmlType> = new Dictionary();
	public function getInstType(field:String, depth:Int = 0):GmlType {
		var q = this, n = depth;
		while (q != null && ++n <= maxDepth) {
			var t = q.instTypes[field];
			if (t != null) return t;
			if (q.isObject) {
				t = GmlAPI.stdInstType[field];
				if (t != null) return t;
			}
			for (qi in q.interfaces.array) {
				t = qi.getInstType(field, n);
				if (t != null) return t;
			}
			q = q.parent;
		}
		return null;
	}
	/**
	 * Returns a "from <namespace>\ntype <type>"
	 * Handy for fields without auto-completion items
	 */
	public function getInstTypeText(field:String, depth:Int = 0):String {
		var q = this, n = depth;
		inline function fin(t:GmlType):String {
			return "from " + q.name + "\ntype " + t.toString();
		}
		while (q != null && ++n <= maxDepth) {
			var t = q.instTypes[field];
			if (t != null) return fin(t);
			if (q.isObject) {
				t = GmlAPI.stdInstType[field];
				if (t != null) return fin(t);
			}
			for (qi in q.interfaces.array) {
				var s = qi.getInstTypeText(field, n);
				if (s != null) return s;
			}
			q = q.parent;
		}
		return null;
	}
	
	/** instance (`var b; b.ptr`) completions */
	public var compInst:ArrayMapSync<AceAutoCompleteItem> = new ArrayMapSync();
	public function getInstCompItem(field:String, depth:Int = 0):AceAutoCompleteItem {
		var q = this, n = depth;
		while (q != null && ++n <= maxDepth) {
			var c = q.compInst[field];
			if (c != null) return c;
			if (q.isObject) {
				c = GmlAPI.stdInstCompMap[field];
				if (c != null) return c;
			}
			for (qi in q.interfaces.array) {
				c = qi.getInstCompItem(field, n);
				if (c != null) return c;
			}
			q = q.parent;
		}
		return null;
	}
	
	private var compInstCache:AceAutoCompleteItems = new AceAutoCompleteItems();
	private var compInstCacheID:Int = 0;
	private var compInstCacheParent:String = null;
	private var compInstCacheInterfaces:Array<String> = [];
	public function getInstComp(depth:Int = 0, includeBuiltins:Bool = true):AceAutoCompleteItems {
		if (++depth > maxDepth) return [];
		// early exit if there are no dependencies
		if (parent == null && !isObject && interfaces.length == 0) {
			compInstCacheID = compInst.changeID;
			return compInst.array;
		}
		
		//
		var forceUpdate = false;
		var maxID = compInst.changeID;
		inline function updateMaxID(nid:Int):Void {
			maxID = cast Math.max(maxID, nid);
		}
		
		var parItems:AceAutoCompleteItems;
		if (parent != null) {
			parItems = parent.getInstComp(depth, false);
			updateMaxID(parent.compInstCacheID);
			if (compInstCacheParent != parent.name) {
				compInstCacheParent = parent.name;
				forceUpdate = true;
			}
		} else {
			parItems = null;
			compInstCacheParent = null;
		}
		
		var itfItems:Array<AceAutoCompleteItems> = interfaces.length > 0 ? [] : null;
		for (i => itf in interfaces) {
			itfItems.push(itf.getInstComp(depth, false));
			updateMaxID(itf.compInstCacheID);
			if (compInstCacheInterfaces[i] != itf.name) {
				compInstCacheInterfaces[i] = itf.name;
				forceUpdate = true;
			}
		}
		if (compInstCacheInterfaces.length != interfaces.length) {
			compInstCacheInterfaces.resize(interfaces.length);
			forceUpdate = true;
		}
		
		// no changes?:
		if (maxID == compInstCacheID && !forceUpdate) return compInstCache;
		
		//Console.log('Updating $name...');
		var list = compInst.array.copy();
		compInstCacheID = maxID;
		compInstCache = list;
		
		// avoid duplicates:
		var found = new Dictionary();
		for (c in list) found[c.name] = true;
		
		// add interfaces after own items:
		if (itfItems != null) for (items in itfItems) for (c in items) {
			if (found[c.name]) continue;
			found[c.name] = true;
			list.push(c);
		}
		
		// add inherited items before own items:
		if (parItems != null) {
			var i = parItems.length;
			while (--i >= 0) {
				var c = parItems[i];
				if (found[c.name]) continue;
				found[c.name] = true;
				list.unshift(c);
			}
		}
		
		// if this is an object, add built-in variables at the end of the list:
		if (isObject && includeBuiltins) for (c in GmlAPI.stdInstComp) list.push(c);
		
		//
		return list;
	}
	
	public var docInstMap:Dictionary<GmlFuncDoc> = new Dictionary();
	public function getInstDoc(field:String, depth:Int = 0):GmlFuncDoc {
		var q = this, n = depth;
		while (q != null && ++n <= maxDepth) {
			var d = q.docInstMap[field];
			if (d != null) return d;
			for (qi in q.interfaces.array) {
				d = qi.getInstDoc(field, n);
				if (d != null) return d;
			}
			q = q.parent;
		}
		return null;
	}
	
	public function new(name:String) {
		this.name = name;
	}
	
	public function addFieldHint(field:String, isInst:Bool, comp:AceAutoCompleteItem, doc:GmlFuncDoc, type:GmlType) {
		var kind = isInst ? instKind : staticKind;
		kind[field] = doc != null ? "asset.script" : "field";
		
		var types = isInst ? instTypes : staticTypes;
		if (type != null) {
			types[field] = type;
		} else if (doc != null) {
			types[field] = doc.getFunctionType();
		}
		
		if (doc != null) {
			var docs = isInst ? docInstMap : docStaticMap;
			docs[field] = doc;
		}
		
		if (comp != null && field != "") {
			var comps:ArrayMap<AceAutoCompleteItem> = isInst ? compInst : compStatic;
			comps[field] = comp;
		}
	}
	
	public function removeFieldHint(field:String, isInst:Bool) {
		var kind = isInst ? instKind : staticKind;
		kind.remove(field);
		var docs = isInst ? docInstMap : docStaticMap;
		docs.remove(field);
		var types = isInst ? instTypes : staticTypes;
		types.remove(field);
		var comps:ArrayMap<AceAutoCompleteItem> = isInst ? compInst : compStatic;
		comps.remove(field);
	}
	
	/**
	 * 
	 * @return whether a special case was applied
	 */
	public function procSpecialInterfaces(name:String, value:Bool) {
		switch (name) {
			case "struct": canCastToStruct = value;
			case "minus1able": minus1able = value;
			case "nullable": isNullable = value;
			case "simplename": avoidHighlight = value;
			// todo: bitflags
			default: return false;
		}
		return true;
	}
}
