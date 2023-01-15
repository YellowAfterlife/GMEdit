package parsers.seeker;
import ace.extern.AceAutoCompleteItem;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTemplateItem;
import gml.type.GmlTypeTools;
import js.lib.RegExp;
import parsers.GmlSeekData;
import parsers.seeker.GmlSeekerImpl;
import parsers.seeker.GmlSeekerJSDocRegex.*;
import tools.JsTools;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerJSDoc {
	public var args:Array<String> = null;
	public var types:Array<String> = null;
	public var rest:Bool = false;
	public var self:String = null;
	public var returns:String = null;
	public var isInterface:Bool = false;
	public var interfaceName:String = null;
	public var implementsNames:Array<String> = null;
	public var templateItems:Array<GmlTypeTemplateItem> = null;
	
	public function reset(resetInterf = true):Void {
		args = null;
		types = null;
		rest = null;
		self = null;
		returns = null;
		if (resetInterf) {
			isInterface = false;
			interfaceName = null;
			implementsNames = null;
			templateItems = null;
		}
	}
	
	public function new() {
		//
	}
	
	public function typesFlush(pre:Array<GmlTypeTemplateItem>, ctx:String):Array<GmlType> {
		var tpl = pre != null && templateItems != null
			? pre.concat(templateItems)
			: JsTools.or(pre, templateItems);
		var rt = [];
		if (tpl != null) {
			for (s in types) {
				s = GmlTypeTools.patchTemplateItems(s, tpl);
				rt.push(GmlTypeDef.parse(s, ctx));
			}
		} else for (s in types) rt.push(GmlTypeDef.parse(s, ctx));
		return rt;
	}
	
	public function proc(seeker:GmlSeekerImpl, s:String) {
		/*
		A thing to remember! Suppose you have the following:
		```
		function a() {}
		/// hello!
		function b() {}
		```
		for that comment, `main` would not be `b` since we didn't get to `b` yet
		*/
		var out = seeker.out;
		var q = seeker.reader;
		
		var mt = jsDoc_implements.exec(s);
		if (mt != null) {
			var nsi = mt[1];
			if (nsi == null) {
				var lineStart = q.source.lastIndexOf("\n", q.pos - 1) + 1;
				var lineText = q.source.substring(lineStart, q.pos);
				var lineMatch = jsDoc_implements_line.exec(lineText);
				if (lineMatch == null) return;
				nsi = lineMatch[1];
			}
			if (implementsNames == null) implementsNames = [];
			implementsNames.push(nsi);
			return;
		}
		
		mt = jsDoc_is.exec(s);
		if (mt != null) {
			var typeStr = mt[1];
			var doc = mt[2];
			inline function procComp(comp:AceAutoCompleteItem):Void {
				if (comp != null) {
					comp.setDocTag("type", typeStr);
					if (doc != null && doc.trimBoth() != "") comp.setDocTag("ℹ", doc);
				}
			}
			var lineStart = q.source.lastIndexOf("\n", q.pos - 1) + 1;
			var lineText = q.source.substring(lineStart, q.pos);
			var lineMatch = jsDoc_is_line.exec(lineText);
			if (lineMatch == null) return;
			var kind = lineMatch[1];
			var name:String;
			var type = GmlTypeDef.parse(typeStr, mt[0]);
			if (lineMatch[1] != null) {
				tools.RegExpTools.each(JsTools.rx(~/\w+/g), lineMatch[1], function(mt) {
					name = mt[0];
					out.globalVarTypes[name] = type;
					procComp(out.comps[name]);
				});
			} else if (lineMatch[2] != null) {
				name = lineMatch[2];
				out.globalTypes[name] = type;
				var globalField = out.globalFields[name];
				if (globalField != null) {
					procComp(globalField.comp);
				}
			} else {
				name = lineMatch[3];
				var namespace:String;
				if (seeker.isCreateEvent) {
					namespace = seeker.getObjectName();
				} else if (seeker.doc != null) {
					namespace = seeker.doc.name;
					if (namespace == null) return;
				} else return;
				var hint = out.fieldHints[namespace + ":" + name];
				if (hint != null) {
					hint.type = type;
					procComp(hint.comp);
				}
			}
			return;
		}
		
		mt = jsDoc_template.exec(s);
		if (mt != null) {
			var tc = mt[1];
			var names = mt[2];
			if (templateItems == null) templateItems = [];
			for (name in names.split(",")) {
				templateItems.push(new GmlTypeTemplateItem(name, tc));
			}
			return;
		}
		
		mt = jsDoc_typedef.exec(s);
		if (mt != null) {
			var typeStr = mt[1];
			var name = mt[2];
			var paramsStr = mt[3];
			var params = paramsStr != null ? GmlTypeTemplateItem.parseSplit(paramsStr) : null;
			if (params != null) typeStr = GmlTypeTools.patchTemplateItems(typeStr, params);
			var type = GmlTypeDef.parse(typeStr);
			out.typedefs[name] = type;
			return;
		}
		
		mt = jsDoc_hint_extimpl.exec(s);
		if (mt != null) {
			var name = mt[1];
			var target = mt[3];
			if (mt[2] == "implements") {
				var arr = out.namespaceImplements[name];
				if (arr == null) out.namespaceImplements[name] = arr = [];
				if (arr.indexOf(target) < 0) arr.push(target);
			} else {
				var imp = out.namespaceHints[name];
				if (imp != null) {
					imp.parentSpace = target;
				} else {
					imp = new GmlSeekDataNamespaceHint(name, target, null);
					out.namespaceHints[name] = imp;
				}
			}
			return;
		}
		
		mt = jsDoc_hint.exec(s);
		if (mt != null) { // @hint
			var typeStr = mt[1];
			var isNew = mt[2] != null;
			var hr = new GmlReader(mt[3], seeker.version), hp:Int;
			hr.skipSpaces0_local();
			
			var templateSelf:GmlType = null;
			var templateItems:Array<GmlTypeTemplateItem> = null;
			var nsName = hr.readIdent();
			var ctrReturn = null;
			if (nsName != null) {
				if (isNew) ctrReturn = nsName;
				hr.skipSpaces0_local();
				if (hr.peek() == "<".code) { // namespace<params>
					hp = hr.pos;
					if (hr.skipTypeParams()) {
						templateItems = GmlTypeTemplateItem.parseSplit(hr.substring(hp + 1, hr.pos - 1));
						if (isNew) ctrReturn += GmlTypeTemplateItem.joinTemplateString(templateItems, false);
						templateSelf = GmlTypeTemplateItem.toTemplateSelf(templateItems);
						hr.skipSpaces0_local();
					} else return;
				}
			}
			
			if (nsName == null && seeker.doc != null && seeker.doc.templateItems != null) {
				templateSelf = GmlTypeTemplateItem.toTemplateSelf(seeker.doc.templateItems);
				templateItems = seeker.doc.templateItems.copy();
			}
			if (templateItems != null && typeStr != null) {
				typeStr = GmlTypeTools.patchTemplateItems(typeStr, templateItems);
			}
			
			var isInst = false;
			var fdName = null;
			var c = hr.peek();
			if (c == ".".code || c == ":".code) {
				isInst = c == ":".code;
				if (!isInst) templateSelf = null;
				hr.skip();
				hr.skipSpaces0_local();
				fdName = hr.readIdent();
				if (fdName != null) {
					hr.skipSpaces0_local();
					if (hr.peek() == "<".code) { // namespace<params>
						hp = hr.pos;
						if (hr.skipTypeParams()) {
							var fdp = GmlTypeTemplateItem.parseSplit(hr.substring(hp + 1, hr.pos - 1));
							templateItems = templateItems.nzcct(fdp);
							hr.skipSpaces0_local();
						} else return;
					}
				}
			}
			
			var args = null;
			if (hr.peek() == "(".code) {
				hp = hr.pos;
				hr.skip();
				var depth = 1;
				while (hr.loopLocal) {
					c = hr.read();
					switch (c) {
						case "(".code: depth++;
						case ")".code: if (--depth <= 0) break;
					}
				}
				if (depth > 0) return;
				if (hr.peekstr(2) == "->") {
					hr.skip(2);
					hr.skipType();
				}
				args = hr.substring(hp, hr.pos);
				if (templateItems != null) {
					args = GmlTypeTools.patchTemplateItems(args, templateItems);
				}
				hr.skipSpaces0_local();
			}
			
			var info = hr.source.substring(hr.pos);
			
			GmlSeekerProcField.addFieldHint(seeker, isNew, nsName, isInst, fdName, args,
				info, GmlTypeDef.parse(typeStr, mt[0]), null, false);
			var addFieldHint_doc = GmlSeekerProcField.addFieldHint_doc;
			if (addFieldHint_doc != null) {
				if (ctrReturn != null) addFieldHint_doc.returnTypeString = ctrReturn;
				if (templateSelf != null) addFieldHint_doc.templateSelf = templateSelf;
				if (templateItems != null) addFieldHint_doc.templateItems = templateItems;
			}
			return; // found!
		}
		
		mt = jsDoc_self.exec(s);
		if (mt != null) {
			self = mt[1];
			return;
		}
		
		mt = jsDoc_return.exec(s);
		if (mt != null) {
			returns = mt[1];
			return;
		}
		
		mt = jsDoc_interface.exec(s);
		if (mt != null) {
			isInterface = true;
			interfaceName = mt[1];
			if (interfaceName == null) {
				if (seeker.isObject) {
					interfaceName = seeker.getObjectName();
				} else if (!seeker.hasFunctionLiterals) {
					interfaceName = seeker.main;
				}
			}
			return;
		}
		
		mt = jsDoc_param.exec(s);
		if (mt != null) {
			if (args == null) {
				args = [];
				types = [];
			}
			var argText = mt[2];
			var argType = mt[1];
			for (arg in argText.split(",")) {
				args.push(arg);
				types.push(argType);
				if (arg.contains("...")) rest = true;
			}
			return; // found!
		}
		
		if (seeker.hasFunctionLiterals) {
			mt = jsDoc_func.exec(s);
			if (mt != null) { // 2.3 @func
				var fn = mt[1];
				var fa = mt[2];
				var pre = fn + "(";
				var post = mt[3];
				var rest = fa.contains("...");
				var jsd = new GmlFuncDoc(fn, pre, post, fa.splitNonEmpty(","), rest);
				out.docs[fn] = jsd;
				out.comps[fn] = new AceAutoCompleteItem(fn, pre + fa + post);
				if (!out.kindMap.exists(fn)) {
					out.kindMap[fn] = "asset.script";
					out.kindList.push(fn);
				}
				seeker.setLookup(fn, false, "asset.script");
				return;
			}
		}
		
		// tags from hereafter have no meaning outside of a script/function
		if (seeker.main == null) return;
		
		// Classic JSDoc (`/// func(arg1, arg2)`) ?:
		mt = jsDoc_full.exec(s);
		if (mt != null) {
			if (!out.docs.exists(seeker.main)) {
				seeker.doc = GmlFuncDoc.parse(seeker.main + mt[1]);
				seeker.linkDoc();
				if (seeker.mainComp != null && seeker.mainComp.doc == null) {
					seeker.mainComp.doc = s;
				}
			}
			return; // found!
		}
		
		// merge suffix-docs in GML variants with #define args into the doc line:
		if (seeker.version.hasScriptArgs()) {
			// `#define func(a, b)\n/// does things` -> `func(a, b) does things`
			s = s.substring(3).trimLeft();
			seeker.doc = out.docs[seeker.main];
			if (seeker.doc == null) {
				if (gmlDoc_full.test(s)) {
					seeker.doc = GmlFuncDoc.parse(s);
					seeker.doc.name = seeker.main;
					seeker.doc.pre = seeker.main + "(";
				} else seeker.doc = GmlFuncDoc.createRest(seeker.main);
				seeker.linkDoc();
			} else {
				if (gmlDoc_full.test(s)) {
					GmlFuncDoc.parse(s, seeker.doc);
					seeker.doc.name = seeker.main;
					seeker.doc.pre = seeker.main + "(";
				} else seeker.doc.post += " " + s;
			}
			if (seeker.mainComp != null) seeker.mainComp.doc = seeker.doc.getAcText();
			return; // found!
		}
		
		// perhaps it's just extra text
		s = s.substring(3).trimBoth();
		if (seeker.mainComp != null) {
			seeker.mainComp.doc = seeker.mainComp.doc.nzcct("\n", s);
		}
	}
}