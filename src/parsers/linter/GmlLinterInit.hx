package parsers.linter;
import parsers.linter.GmlLinterKind;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterInit {
	public static function keywords(l:GmlLinter):Dictionary<GmlLinterKind> {
		var q = new Dictionary<GmlLinterKind>();
		q["var"] = KVar;
		q["globalvar"] = KGlobalVar;
		q["enum"] = KEnum;
		//
		q["undefined"] = KUndefined;
		//
		q["not"] = KNot;
		q["and"] = KBoolAnd;
		q["or"] = KBoolOr;
		q["xor"] = KBoolXor;
		//
		q["div"] = KIntDiv;
		q["mod"] = KMod;
		//
		//
		q["begin"] = KCubOpen;
		q["end"] = KCubClose;
		q["if"] = KIf;
		q["then"] = KThen;
		q["else"] = KElse;
		q["return"] = KReturn;
		q["exit"] = KExit;
		//
		q["for"] = KFor;
		q["while"] = KWhile;
		q["do"] = KDo;
		q["until"] = KUntil;
		q["repeat"] = KRepeat;
		q["with"] = KWith;
		q["break"] = KBreak;
		q["continue"] = KContinue;
		//
		q["switch"] = KSwitch;
		q["case"] = KCase;
		q["default"] = KDefault;
		//
		q["try"] = KTry;
		q["catch"] = KCatch;
		q["finally"] = KFinally;
		q["throw"] = KThrow;
		//
		var kws = @:privateAccess l.version.config.additionalKeywords;
		if (kws != null) {
			inline function addOpt(name:String, k:GmlLinterKind) {
				if (kws.indexOf(name) >= 0) q[name] = k;
			}
			addOpt("in", KLiveIn);
			addOpt("wait", KLiveWait);
			addOpt("new", KNew);
			addOpt("delete", KDelete);
			addOpt("function", KFunction);
			addOpt("static", KStatic);
		}
		//
		return q;
	}
}