package parsers.linter;
import haxe.ds.Vector;

/**
 * ...
 * @author ...
 */
@:build(tools.AutoEnum.build())
@:build(tools.macros.EnumAbstractBuilder.build())
enum abstract GmlLinterKind(Int) {
	var LKEOF;
	
	// literals:
	var LKString;
	var LKNumber;
	var LKUndefined;
	var LKIdent;
	
	//
	var LKVar;
	var LKGlobalVar;
	var LKConst;
	var LKLet;
	var LKGhostVar; // no longer in scope
	var LKMacro;
	var LKEnum;
	
	// setops:
	var LKSet; // =
	var LKSetOp; // generic (+=, -=, etc.)
	
	// boolean:
	var LKEQ; // ==
	var LKNE; // !=
	var LKLT; // <
	var LKLE; // <=
	var LKGT; // >
	var LKGE; // >=
	var LKBoolAnd; // &&
	var LKBoolOr; // ||
	var LKBoolXor; // ^^
	var LKNot; // !
	
	// numeric:
	var LKAdd; // +
	var LKSub; // -
	var LKMul; // *
	var LKDiv; // /
	var LKIntDiv; // div
	var LKMod; // %
	
	// bitwise:
	var LKAnd; // &
	var LKOr; // |
	var LKXor; // ^
	var LKShl; // <<
	var LKShr; // >>
	var LKBitNot; // ~
	
	//
	var LKInc; // ++
	var LKDec; // --
	
	// brackets
	var LKParOpen;
	var LKParClose;
	var LKCubOpen;
	var LKCubClose;
	var LKSqbOpen;
	var LKSqbClose;
	
	// combined:
	var LKCall; // ()
	var LKField; // a.b
	var LKArray; // a[..]
	var LKNullField; // a?.b
	var LKNullArray; // a?[..]
	
	// misc. operators:
	var LKSemico; // `;`
	var LKDot; // `.`
	var LKComma;
	var LKHash; // `#`
	var LKQMark; // `?`
	var LKColon; // `:`
	var LKAtSign; // `@`
	var LKDollar; // `$`
	var LKNullCoalesce; // `??`
	var LKNullDot; // `?.`
	var LKNullSqb; // `?[`
	var LKArrow; // `->`, used for return types
	var LKArrowFunc; // `=>`, used for arrow functions
	var LKCast; // `cast <expr>`
	var LKAs; // `<expr> as <type>`
	
	// branching:
	var LKIf;
	var LKThen;
	var LKElse;
	var LKReturn;
	var LKExit;
	var LKSwitch;
	var LKDefault;
	var LKCase;
	
	// exception handling:
	var LKTry;
	var LKCatch;
	var LKFinally;
	var LKThrow;
	
	// other features:
	var LKFunction;
	var LKStatic;
	var LKNew;
	var LKDelete;
	
	// loops:
	var LKFor;
	var LKDo;
	var LKWhile;
	var LKUntil;
	var LKRepeat;
	var LKBreak;
	var LKContinue;
	var LKWith;
	
	// syntax extensions:
	var LKMFuncDecl; // #mfunc
	var LKArgs;
	var LKLambda;
	var LKLamDef;
	var LKImport;
	
	// #gmcr:
	var LKYield;
	var LKLabel;
	var LKGoto;
	
	// GMLive-exclusive:
	var LKLiveIn; // `field in object`
	var LKLiveWait; // `wait <time>`
	
	var LKMaxKind;
	
	// helpers:
	public inline function getIndex():Int {
		return cast this;
	}
	public function getName():String {
		return 'unknown[$this]';
	}
	
	// is:
	static var __isUnOp = new GmlLinterKindSet([
		LKAdd, LKSub,
	]);
	public inline function isUnOp() return __isUnOp[this];
	
	static var __isBinOp = new GmlLinterKindSet([
		LKAdd, LKSub, LKMul, LKDiv, LKIntDiv, LKMod,
		LKEQ, LKNE, LKLT, LKGT, LKLE, LKGE,
		LKAnd, LKOr, LKXor, LKShl, LKShr,
		LKBoolAnd, LKBoolOr, LKBoolXor,
	]);
	public inline function isBinOp() return __isBinOp[this];
	
	static var __binOpPriority:Vector<Int> = (function() {
		var n = GmlLinterKind.LKMaxKind.getIndex();
		var pr = new Vector<Int>(n);
		for (i in 0 ... n) pr[i] = -4;
		inline function set(p:Int, k:GmlLinterKind):Void {
			pr[k.getIndex()] = p;
		}
		set(0x00, LKMul);
		set(0x01, LKDiv);
		set(0x02, LKMod);
		set(0x04, LKIntDiv);
		set(0x10, LKAdd);
		set(0x11, LKSub);
		set(0x20, LKShl);
		set(0x21, LKShr);
		set(0x30, LKOr);
		set(0x31, LKAnd);
		set(0x32, LKXor);
		set(0x40, LKSet); // `=` among operators is `==`
		set(0x40, LKEQ);
		set(0x41, LKNE);
		set(0x42, LKLT);
		set(0x43, LKLE);
		set(0x44, LKGT);
		set(0x45, LKGE);
		set(0x50, LKBoolAnd);
		set(0x51, LKBoolXor); // todo: check what priority of this really is
		set(0x60, LKBoolOr);
		return pr;
	})();
	public inline function getBinOpPriority():Int {
		return __binOpPriority[this];
	}
	public static inline function getMaxBinPriority():Int return 0x7;
	
	static var __isSetOp = new GmlLinterKindSet([
		LKSetOp,
	]);
	public inline function isSetOp() return __isSetOp[this];
	
	static var __canSet = new GmlLinterKindSet([
		LKIdent,
		LKField,
	]);
	public inline function canSet() return __canSet[this];
	
	static var __isStat = new GmlLinterKindSet([
		LKSet,
		LKCall,
		LKInc,
		LKDec,
		LKFunction,
		LKNew,
		LKYield,
	]);
	public inline function isStat() return __isStat[this];
	
	static var __canCall = new GmlLinterKindSet([
		LKIdent,
		LKField,
		LKLambda,
		LKFunction,
	]);
	public inline function canCall() return __canCall[this];
	
	static var __noSemico = new GmlLinterKindSet([
		LKCubOpen,
		LKIf,
		LKFor,
		LKWhile,
		LKDo,
		LKRepeat,
		LKSwitch,
		LKWith,
		LKArgs,
		LKMFuncDecl,
		LKMacro,
		LKEnum,
		LKFunction,
	]);
	public inline function needSemico() return !__noSemico[this];
	
	static var __canPostfix = new GmlLinterKindSet([
		LKIdent,
		LKField,
		LKArray,
	]);
	public inline function canPostfix() return __canPostfix[this];
}
abstract GmlLinterKindSet(haxe.ds.Vector<Bool>) {
	public function new(set:Array<GmlLinterKind>) {
		this = new haxe.ds.Vector(GmlLinterKind.LKMaxKind.getIndex());
		for (k in set) this[k.getIndex()] = true;
	}
	@:arrayAccess public inline function get(k:GmlLinterKind) {
		return this[k.getIndex()];
	}
	@:arrayAccess public inline function getAt(k:Int) {
		return this[k];
	}
}
