package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlAPI;
import gml.GmlField;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import parsers.GmlSeekData.GmlSeekDataHint;
import tools.JsTools;
import tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcField {
	public static var addFieldHint_doc:GmlFuncDoc = null;
	public static function addFieldHint(seeker:GmlSeekerImpl,
		isConstructor:Bool,
		namespace:String,
		isInst:Bool,
		field:String,
		args:String,
		info:String,
		type:GmlType,
		argTypes:Array<GmlType>,
		isAuto:Bool
	) {
		var parentSpace:String = null;
		if (namespace == null) {
			if (seeker.isCreateEvent) {
				namespace = seeker.getObjectName();
				parentSpace = seeker.project.objectParents[namespace];
			} else if (seeker.doc != null) {
				namespace = seeker.doc.name;
				parentSpace = seeker.doc.parentName;
				if (namespace == null) return;
			} else return;
		}
		field = JsTools.or(field, "");
			
		var isField = (field != "");
		var name = isField ? field : namespace;
		
		var hintDoc:GmlFuncDoc = null;
		if (args != null) {
			var fa = name;
			if (field == "" && isInst) {
				// self-call, we check for this in GmlLinterFuncArgs
				fa += ":";
			}
			fa += GmlFuncDoc.patchArrow(args);
			hintDoc = GmlFuncDoc.parse(fa);
			hintDoc.trimArgs();
			hintDoc.isConstructor = isConstructor;
			if (argTypes != null) hintDoc.argTypes = argTypes;
			if (type == null) type = hintDoc.getFunctionType();
			info = NativeString.nzcct(hintDoc.getAcText(), "\n", info);
		}
		addFieldHint_doc = hintDoc;
		info = NativeString.nzcct(info, "\n", 'from $namespace');
		if (type != null) info = NativeString.nzcct(info, "\n", "type " + type.toString());
		
		var compMeta = isField ? (args != null ? "function" : "variable") : "namespace";
		var privateFieldRegex = seeker.privateFieldRegex;
		var comp = privateFieldRegex == null || !privateFieldRegex.test(name)
			? new AceAutoCompleteItem(name, compMeta, info) : null;
		var hint = new GmlSeekDataHint(namespace, isInst, field, comp, hintDoc, parentSpace, type);
		
		var out = seeker.out;
		var lastHint = out.fieldHints[hint.key];
		if (lastHint == null) {
			out.fieldHints[hint.key] = hint;
		} else lastHint.merge(hint, isAuto);
		
		if (isField) {
			//
		} else if (!isInst) {
			out.comps[name] = comp;
			//
			if (!out.kindMap.exists(name)) out.kindList.push(name);
			out.kindMap[name] = "namespace";
			if (hintDoc != null) out.docs[name] = hintDoc;
		}
	}
	
	public static function addInstVar(seeker:GmlSeekerImpl, s:String):Void {
		var out = seeker.out;
		var privateFieldRegex = seeker.privateFieldRegex;
		if (out.instFieldMap[s] == null
			&& (privateFieldRegex == null || !privateFieldRegex.test(s))
		) {
			var fd = GmlAPI.gmlInstFieldMap[s];
			if (fd == null) {
				fd = new GmlField(s, "variable");
				GmlAPI.gmlInstFieldMap.set(s, fd);
			}
			out.instFieldList.push(fd);
			out.instFieldMap.set(s, fd);
			out.instFieldComp.push(fd.comp);
		}
	}
}