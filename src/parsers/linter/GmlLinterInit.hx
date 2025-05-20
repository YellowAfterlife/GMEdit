package parsers.linter;
import gml.GmlVersionConfig;
import parsers.linter.GmlLinterKind;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlLinterInit {
	public static function keywords(config:GmlVersionConfig):Dictionary<GmlLinterKind> {
		var q = new Dictionary<GmlLinterKind>();
		q["var"] = LKVar;
		q["globalvar"] = LKGlobalVar;
		q["enum"] = LKEnum;
		//
		q["undefined"] = LKUndefined;
		//
		q["not"] = LKNot;
		q["and"] = LKBoolAnd;
		q["or"] = LKBoolOr;
		q["xor"] = LKBoolXor;
		//
		q["div"] = LKIntDiv;
		q["mod"] = LKMod;
		//
		//
		q["begin"] = LKCubOpen;
		q["end"] = LKCubClose;
		q["if"] = LKIf;
		q["then"] = LKThen;
		q["else"] = LKElse;
		q["return"] = LKReturn;
		q["exit"] = LKExit;
		//
		q["for"] = LKFor;
		q["while"] = LKWhile;
		q["do"] = LKDo;
		q["until"] = LKUntil;
		q["repeat"] = LKRepeat;
		q["with"] = LKWith;
		q["break"] = LKBreak;
		q["continue"] = LKContinue;
		//
		q["switch"] = LKSwitch;
		q["case"] = LKCase;
		q["default"] = LKDefault;
		//
		q["try"] = LKTry;
		q["catch"] = LKCatch;
		q["finally"] = LKFinally;
		q["throw"] = LKThrow;
		//
		var kws = config.additionalKeywords;
		if (kws != null) {
			inline function addOpt(name:String, k:GmlLinterKind) {
				if (kws.indexOf(name) >= 0) q[name] = k;
			}
			addOpt("in", LKLiveIn);
			addOpt("wait", LKLiveWait);
			addOpt("new", LKNew);
			addOpt("delete", LKDelete);
			addOpt("function", LKFunction);
			addOpt("static", LKStatic);
		}
		//
		return q;
	}
}