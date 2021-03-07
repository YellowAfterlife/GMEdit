package parsers.linter;
import haxe.ds.Vector;

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
	var KNullField; // a?.b
	var KNullArray; // a?[..]
	
	// misc. operators:
	var KSemico; // `;`
	var KDot; // `.`
	var KComma;
	var KHash; // `#`
	var KQMark; // `?`
	var KColon; // `:`
	var KAtSign; // `@`
	var KDollar; // `$`
	var KNullCoalesce; // `??`
	var KNullDot; // `?.`
	var KNullSqb; // `?[`
	var KArrow; // `->`, used for return types
	var KCast; // `cast <expr>`
	var KAs; // `<expr> as <type>`
	
	// branching:
	var KIf;
	var KThen;
	var KElse;
	var KReturn;
	var KExit;
	var KSwitch;
	var KDefault;
	var KCase;
	
	// exception handling:
	var KTry;
	var KCatch;
	var KFinally;
	var KThrow;
	
	// other features:
	var KFunction;
	var KStatic;
	var KNew;
	var KDelete;
	
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
	
	static var __binOpPriority:Vector<Int> = (function() {
		var n = GmlLinterKind.KMaxKind.getIndex();
		var pr = new Vector<Int>(n);
		for (i in 0 ... n) pr[i] = -4;
		inline function set(p:Int, k:GmlLinterKind):Void {
			pr[k.getIndex()] = p;
		}
		set(0x00, KMul);
		set(0x01, KDiv);
		set(0x02, KMod);
		set(0x04, KIntDiv);
		set(0x10, KAdd);
		set(0x11, KSub);
		set(0x20, KShl);
		set(0x21, KShr);
		set(0x30, KOr);
		set(0x31, KAnd);
		set(0x32, KXor);
		set(0x40, KSet); // `=` among operators is `==`
		set(0x40, KEQ);
		set(0x41, KNE);
		set(0x42, KLT);
		set(0x43, KLE);
		set(0x44, KGT);
		set(0x45, KGE);
		set(0x50, KBoolAnd);
		set(0x51, KBoolXor); // todo: check what priority of this really is
		set(0x60, KBoolOr);
		return pr;
	})();
	public inline function getBinOpPriority():Int {
		return __binOpPriority[this];
	}
	public static inline function getMaxBinPriority():Int return 0x7;
	
	static var __isSetOp = new GmlLinterKindSet([
		KSetOp,
	]);
	public inline function isSetOp() return __isSetOp[this];
	
	static var __canSet = new GmlLinterKindSet([
		KIdent, KField,
	]);
	public inline function canSet() return __canSet[this];
	
	static var __isStat = new GmlLinterKindSet([
		KSet, KCall, KInc, KDec, KFunction, KNew,
	]);
	public inline function isStat() return __isStat[this];
	
	static var __canCall = new GmlLinterKindSet([
		KIdent, KField, KLambda, KFunction,
	]);
	public inline function canCall() return __canCall[this];
	
	static var __noSemico = new GmlLinterKindSet([
		KCubOpen,
		KIf, KFor, KWhile, KDo, KRepeat, KSwitch, KWith,
		KArgs, KMFuncDecl, KMacro, KEnum, KFunction,
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
