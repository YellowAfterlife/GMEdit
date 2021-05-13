package parsers.seeker;
import gml.GmlFuncDoc;
import gml.type.GmlTypeDef;
import parsers.GmlSeekData.GmlSeekDataNamespaceHint;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerProcDoc {
	public static function flush(seeker:GmlSeekerImpl) {
		final q = seeker.reader;
		final jsDoc = seeker.jsDoc;
		var doc = seeker.doc;
		final main = seeker.main;
		final out = seeker.out;
		
		var updateComp = false;
		if (doc == null && (main != null && main != "")) {
			// no doc yet, but there should be, so let's scrap what we may
			doc = out.docs[main];
			if (doc == null) {
				seeker.doc = doc = GmlFuncDoc.create(main);
				seeker.linkDoc();
			}
			updateComp = true;
		}
		
		if (doc != null) {
			if (jsDoc.args != null) {
				doc.args = jsDoc.args;
				doc.argTypes = jsDoc.typesFlush(null, doc.name);
				doc.templateItems = jsDoc.templateItems;
				if (jsDoc.rest) doc.rest = jsDoc.rest;
				doc.procHasReturn(seeker.src, seeker.start, q.pos, seeker.docIsAutoFunc);
			} else if (doc.args.length != 0 || doc.hasReturn) {
				// have some arguments and no JSDoc
				doc.procHasReturn(seeker.src, seeker.start, q.pos, seeker.docIsAutoFunc, doc.args);
			} else { // no JSDoc, try indexing
				doc.fromCode(seeker.src, seeker.start, q.pos);
				updateComp = true;
			}
			if (jsDoc.returns != null) {
				doc.returnTypeString = jsDoc.returns;
				updateComp = true;
			}
			if (jsDoc.isInterface) {
				if (jsDoc.interfaceName == null) jsDoc.interfaceName = main;
				if (!out.namespaceHints.exists(jsDoc.interfaceName)) {
					out.namespaceHints[jsDoc.interfaceName] = new GmlSeekDataNamespaceHint(jsDoc.interfaceName, null, null);
				}
			}
			doc.selfType = GmlTypeDef.parse(jsDoc.self, doc.name);
			
			//
			if (updateComp) {
				var mainComp = seeker.mainComp;
				if (mainComp != null) mainComp.doc = doc.getAcText();
			}
		}
		
		if (jsDoc.implementsNames != null) {
			var ownType:String;
			if (seeker.isObject) {
				ownType = seeker.getObjectName();
			} else ownType = main;
			//
			var arr = out.namespaceImplements[ownType];
			if (arr == null) { arr = []; out.namespaceImplements[ownType] = arr; }
			//
			if (ownType == null) {
				Main.console.warn("Trying to add @implements without a known self-type", arr);
			} else for (nsi in jsDoc.implementsNames) {
				if (arr.indexOf(nsi) < 0) arr.push(nsi);
			}
		}
		seeker.doc = null;
		seeker.docIsAutoFunc = false;
		jsDoc.reset();
	}
}