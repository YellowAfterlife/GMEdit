package parsers.linter;

/**
 * ...
 * @author ...
 */
@:build(tools.AutoEnum.build())
enum abstract GmlLinterKind(Int) {
	var KEOF;
	
	// literals:
	var KString;
	var KNumber;
	var KUndefined;
	var KIdent;
	
	//
	var KVar;
	var KGlobalVar;
	var KConst;
	var KLet;
	var KGhostVar; // no longer in scope
	var KMacro;
	var KEnum;
	
	// setops:
	var KSet; // =
	var KSetOp; // generic (+=, -=, etc.)
	
	// boolean:
	var KEQ; // ==
	var KNE; // !=
	var KLT; // <
	var KLE; // <=
	var KGT; // >
	var KGE; // >=
	var KBoolAnd; // &&
	var KBoolOr; // ||
	var KBoolXor; // ^^
	var KNot; // !
	
	// numeric:
	var KAdd; // +
	var KSub; // -
	var KMul; // *
	var KDiv; // /
	var KIntDiv; // div
	var KMod; // %
	
	// bitwise:
	var KAnd; // &
	var KOr; // |
	var KXor; // ^
	var KShl; // <<
	var KShr; // >>
	var KBitNot; // ~
	
	//
	var KInc; // ++
	var KDec; // --
	
	// brackets
	var KParOpen;
	var KParClose;
	var KCubOpen;
	var KCubClose;
	var KSqbOpen;
	var KSqbClose;
	
	// combined:
	var KCall; // ()
	var KField; // a.b
	var KArray; // a[..]
	
	// misc. operators:
	var KSemico; // `;`
	var KDot; // `.`
	var KComma;
	var KHash; // `#`
	var KQMark; // `?`
	var KColon; // `:`
	var KAtSign; // `@`
	
	// branching:
	var KIf;
	var KThen;
	var KElse;
	var KReturn;
	var KExit;
	var KSwitch;
	var KDefault;
	var KCase;
	
	var KTry;
	var KCatch;
	var KFinally;
	var KThrow;
	
	// loops:
	var KFor;
	var KDo;
	var KWhile;
	var KUntil;
	var KRepeat;
	var KBreak;
	var KContinue;
	var KWith;
	
	// syntax extensions:
	var KMFuncDecl; // #mfunc
	var KArgs;
	var KLambda;
	var KLamDef;
	var KImport;
	
	// #gmcr:
	var KYield;
	var KLabel;
	var KGoto;
	
	// GMLive-exclusive:
	var KLiveIn; // `field in object`
	var KLiveWait; // `wait <time>`
	
	var KMaxKind;
	
	// helpers:
	public inline function getIndex():Int {
		return cast this;
	}
	public function getName():String {
		return 'unknown[$this]';
	}
	
	// is:
	static var __isUnOp = new GmlLinterKindSet([
		KAdd, KSub,
	]);
	public inline function isUnOp() return __isUnOp[this];
	
	static var __isBinOp = new GmlLinterKindSet([
		KAdd, KSub, KMul, KDiv, KIntDiv, KMod,
		KEQ, KNE, KLT, KGT, KLE, KGE,
		KAnd, KOr, KXor, KShl, KShr,
		KBoolAnd, KBoolOr, KBoolXor,
	]);
	public inline function isBinOp() return __isBinOp[this];
	
	static var __isSetOp = new GmlLinterKindSet([
		KSetOp,
	]);
	public inline function isSetOp() return __isSetOp[this];
	
	static var __canSet = new GmlLinterKindSet([
		KIdent, KField,
	]);
	public inline function canSet() return __canSet[this];
	
	static var __isStat = new GmlLinterKindSet([
		KSet, KCall, KInc, KDec,
	]);
	public inline function isStat() return __isStat[this];
	
	static var __canCall = new GmlLinterKindSet([
		KIdent, KField, KLambda,
	]);
	public inline function canCall() return __canCall[this];
	
	static var __noSemico = new GmlLinterKindSet([
		KCubOpen,
		KIf, KFor, KWhile, KDo, KRepeat, KSwitch, KWith,
		KArgs, KMFuncDecl, KMacro, KEnum,
	]);
	public inline function needSemico() return !__noSemico[this];
	
	static var __canPostfix = new GmlLinterKindSet([
		KIdent, KField, KArray,
	]);
	public inline function canPostfix() return __canPostfix[this];
}
abstract GmlLinterKindSet(haxe.ds.Vector<Bool>) {
	public function new(set:Array<GmlLinterKind>) {
		this = new haxe.ds.Vector(GmlLinterKind.KMaxKind.getIndex());
		for (k in set) this[k.getIndex()] = true;
	}
	@:arrayAccess public inline function get(k:GmlLinterKind) {
		return this[k.getIndex()];
	}
	@:arrayAccess public inline function getAt(k:Int) {
		return this[k];
	}
}
