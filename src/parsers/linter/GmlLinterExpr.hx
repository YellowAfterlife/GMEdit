package parsers.linter;
import ace.AceGmlTools;
import gml.GmlAPI;
import gml.GmlFuncDoc;
import gml.type.GmlType;
import gml.type.GmlTypeCanCastTo;
import gml.type.GmlTypeDef;
import gml.type.GmlTypeTools;
import parsers.linter.GmlLinterArrayAccess;
import parsers.linter.GmlLinterArrayLiteral;
import parsers.linter.GmlLinterFuncLiteral;
import tools.Aliases;
import parsers.linter.GmlLinter;
import tools.JsTools;
import tools.macros.GmlLinterMacros.*;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterExpr extends GmlLinterHelper {
	
	/**
	 * Indicates whatever it is that readExpr just parsed.
	 * It is the right-most top-level expression, so
	 * a.b -> KField
	 * (a.b) -> KParOpen
	 * (a.b).c -> KField
	 */
	public var currKind:GmlLinterKind;
	
	/** If readExpr just parsed something starting with an identifier, this holds that.  */
	public var currName:GmlName;
	
	/** Resulting type of last parsed expression. Often is null. */
	public var currType:GmlType;
	
	/** For `<expr>.field`, indicates type of `<expr>` */
	public var selfType:GmlType;
	
	/** If the resulting expression is a function */
	public var currFunc:GmlFuncDoc;
	
	/** If processed expression evaluates to a literal, this holds that */
	public var currValue:GmlLinterValue;
	
	public var isLocalIdent:Bool;
	
	public var nullSafety:GmlLinterLocalNullSafetyItems;
	
	function invalid(flags:GmlLinterReadFlags):FoundError {
		return linter.readExpect(flags.has(AsStat) ? "a statement" : "an expression");
	}
	
	function checkConst(currName:GmlName, currKind:GmlLinterKind) @:privateAccess {
		switch (currKind) {
			case KIdent: {
				if (linter.localKinds[currName] == KConst) {
					linter.addWarning('Assigning to a `const` local `$currName`');
				}
			};
			case KNullField, KNullArray: {
				linter.addError("Null-conditional values cannot be assigned to");
			};
			default:
		}
	}
	
	public function read(
		oldDepth:Int, flags:GmlLinterReadFlags = None, ?_nk:GmlLinterKind, ?targetType:GmlType
	):FoundError {
		var self = linter;
		var newDepth = oldDepth + 1;
		var q = self.reader;
		var nk:GmlLinterKind = self.nextOr(_nk);
		//
		inline function invalid():FoundError {
			return this.invalid(flags);
		}
		if (nk == KEOF) return invalid();
		//
		inline function hasFlag(flag:GmlLinterReadFlags):Bool {
			return flags.has(flag);
		}
		inline function isStat():Bool {
			return hasFlag(AsStat);
		}
		var wasStat = isStat();
		// the thing itself:
		var statKind = nk;
		var currKind = nk;
		var currName = nk == KIdent ? nextVal : null;
		var isLocalIdent = false;
		var selfType:GmlType = null;
		var currType:GmlType = null;
		var currFunc:GmlFuncDoc = null;
		var currValue:GmlLinterValue = null;
		var nullSafety:GmlLinterLocalNullSafetyItems = [];
		//
		inline function checkConst():Void {
			this.checkConst(currName, currKind);
		}

		//
		switch (nk) {
			case KNumber: {
				currType = GmlTypeDef.number;
				var nv = nextVal;
				currValue = VNumber(Std.parseFloat(nv), nv);
			};
			case KString: {
				currType = GmlTypeDef.string;
				var nv = nextVal;
				currValue = VString(null, nv); // todo: probably parse string?
			};
			case KUndefined: {
				currType = GmlTypeDef.undefined;
				currValue = VUndefined;
			};
			case KIdent: {
				if (hasFlag(HasPrefix)) checkConst();
				if (linter.localKinds[currName] == KGhostVar) {
					addWarning('Trying to access a variable `$currName` outside of its scope');
				}
				// linting #properties:
				if (self.isProperties && isStat()) {
					if (skipIf(peek() == KColon)) { // name:type
						rc(readCheckSkip(KIdent, "variable type"));
						if (skipIf(peek() == KLT)) {
							// we know that it's valid or else GmlObjectProperties would prevent you from saving
							var depth = 1;
							while (q.loop) {
								switch (next()) {
									case KLT: depth++;
									case KGT: if (--depth <= 0) break;
									default:
								}
							}
						}
					}
				}
				// figure out what this is:
				GmlLinterIdent.read(self, currName);
				currType = GmlLinterIdent.type;
				currFunc = GmlLinterIdent.func;
				isLocalIdent = GmlLinterIdent.isLocal;
			};
			case KParOpen: {
				var arrowState:GmlLinterFuncLiteralArgsArrowState = null;
				var arrowArgName:String = null;
				if (skipIfPeek(KParClose)) {
					arrowState = AfterEmptyPar;
				}
				else if (peek() == KIdent) {
					arrowArgName = nextVal;
					var peeker = linter.__peekReader;
					for (iter in 0 ... 2) {
						peeker.skipSpaces1();
						switch (peeker.read()) {
							case ")".code:
								peeker.skipSpaces1();
								if (peeker.skipIfStrEquals("=>")) {
									arrowState = AfterArrow;
									skip();
								}
							case "=".code:
								// running a linter in another linter! Can you believe that?
								// Fortunately it's not like you usually have thousands of arrow funcs
								// all with first argument being optional.
								peeker.skipComplexExpr(editor);
								continue;
							case ":".code if (iter == 0):
								arrowState = AfterColon;
								skip();
							case ",".code:
								arrowState = AfterComma;
								skip();
						}
						break;
					}
				}
				if (arrowState == null) { // normal expr
					rc(self.readExpr(newDepth));
					readCheckSkip(KParClose, "a `)`");
					if (this.currKind == KCall) {
						currKind = statKind = KCall;
					}
					currType = this.currType;
					currFunc = this.currFunc;
					currValue = this.currValue;
					nullSafety = this.nullSafety;
				}
				else {
					if (isStat()) {
						if (arrowState == AfterArrow) {
							return readError("Arrow functions cannot be statements");
						} else return readExpect("a `)`");
					}
					rc(self.funcLiteral.read(newDepth, false, true, {
						arrowFunc: {
							state: arrowState,
							firstArgName: arrowArgName,
						}
					}));
					currFunc = self.funcLiteral.doc;
					currType = currFunc.getFunctionType();
				}
			};
			case KNew: {
				rc(self.readExpr(newDepth, IsNew));
				currType = JsTools.or(this.currType, GmlTypeDef.simple(this.currName));
				currFunc = currType.getSelfCallDoc(self.getImports());
			};
			case KCast: {
				rc(self.readExpr(newDepth, GmlLinterReadFlags.NoOps.with(IsCast)));
				if (this.currKind == KAs) {
					currType = this.currType;
				} else currType = null;
				currFunc = null;
			};
			case KNot, KBitNot: {
				rc(self.readExpr(newDepth));
				nullSafety = this.nullSafety;
				if (nk == KNot) {
					self.checkTypeCastBoolOp(this.currType, this.currValue, "!");
					currType = GmlTypeDef.bool;
					switch (this.currValue) {
						case null:
						case GmlLinterValue.VNumber(f, _):
							var v = f > 0.5 ? 0 : 1;
							currValue = VNumber(v, "" + v);
						default:
					}
					for (nsi in nullSafety) {
						if (nsi.status != null) nsi.status = !nsi.status;
					}
				} else {
					self.checkTypeCast(this.currType, GmlTypeDef.int, "~", this.currValue);
					currType = GmlTypeDef.int;
					switch (this.currValue) {
						case null:
						case GmlLinterValue.VNumber(f, _):
							var i = ~Std.int(f);
							currValue = VNumber(i, "" + i);
						default:
					}
				}
			};
			case KInc, KDec: {
				rc(self.readExpr(newDepth, HasPrefix));
				self.checkTypeCast(this.currType, GmlTypeDef.number, nk == KInc ? "++" : "--", this.currValue);
				currType = GmlTypeDef.number;
			};
			case KSqbOpen: {
				rc(GmlLinterArrayLiteral.read(self, newDepth, targetType));
				currType = GmlLinterArrayLiteral.outType;
			};
			case KLambda, KFunction:
				rc(self.funcLiteral.read(newDepth, nk == KFunction, isStat()));
				currFunc = self.funcLiteral.doc;
				currType = currFunc.getFunctionType();
			case KCubOpen: { // { fd1: v1, fd2: v2 }
				var anon = new GmlTypeAnon();
				var anonFields = anon.fields;
				if (self.skipIf(self.peek() == KCubClose)) {
					// empty!
				} else while (q.loop) {
					var key:String;
					switch (self.next()) {
						case KIdent: key = self.nextVal;
						case KString:
							try {
								key = haxe.Json.parse(self.nextVal);
							} catch (x:Dynamic) {
								key = null;
								self.addWarning("Invalid string for key name");
							}
						case KCubClose: break;
						default: return self.readExpect("a field name");
					}
					rc(self.readCheckSkip(KColon, "a `:` between key-value pair in {}"));
					rc(self.readExpr(newDepth));
					if (key != null) {
						anonFields[key] = new GmlTypeAnonField(this.currType, this.currFunc);
					}
					switch (self.peek()) {
						case KCubClose: self.skip(); break;
						case KComma: self.skip();
						default: return self.readExpect("a `,` or a `}` after a key-value pair in {}");
					}
				}
				currType = GmlType.TAnon(anon);
			};
			default: {
				if (nk.isUnOp()) { // +v or -v
					rc(self.readExpr(newDepth, NoOps));
					self.checkTypeCast(this.currType, GmlTypeDef.number, nk == KAdd ? "+" : "-", this.currValue);
					currType = GmlTypeDef.number;
					if (nk == KAdd) {
						currValue = this.currValue;
					} else {
						switch (this.currValue) {
							case null:
							case VNumber(f, _):
								f = -f;
								currValue = VNumber(f, "" + f);
							default:
						}
					}
				}
				else return invalid();
			};
		}
		// suffixes:
		inline function mergeBinOpNullSafety():Void {
			nullSafety.mergeItems(self.binOps.nullSafety);
		}
		while (q.loop) {
			nk = self.peek();
			var setValue = false;
			switch (nk) {
				case KSet: {
					if (isStat()) {
						checkConst();
						self.skip();
						flags.remove(AsStat);
						statKind = KSet;
						rc(self.readExpr(newDepth, None, null, currType));
						self.checkTypeCast(this.currType, currType, "assignment", this.currValue);
						currType = null;
					} else {
						if (hasFlag(NoOps)) break;
						if (self.prefs.noSingleEquals) {
							self.addWarning("Using single `=` as a comparison operator");
						}
						self.skip();
						var localName = currKind == KIdent && isLocalIdent ? currName : null;
						rc(self.readOps(newDepth, currType, currValue, nk, self.nextVal, localName));
						mergeBinOpNullSafety();
						flags.add(NoSfx);
						currType = this.currType;
					}
				};
				case KParOpen: { // fn(...)
					if (self.prefs.forbidNonIdentCalls && !currKind.canCall()) {
						return self.readError('Expression ${currKind.getName()} is not callable');
					}
					if (hasFlag(NoSfx)) return self.readError("Can't call this");
					self.skip();
					var argsSelf = currKind == KIdent && currName == "method" ? GmlTypeDef.methodSelf : selfType;
					var argc = self.funcArgs.read(newDepth, currFunc, argsSelf, currType);
					rc(argc < 0);
					if (currFunc != null) {
						self.checkCallArgs(currFunc, currName, argc, !isStat(), hasFlag(IsNew));

						// Check that the function's self doc matches the current context
						if (currFunc.selfType != null) {
							var currSelfType = self.getSelfType();
							if (GmlTypeTools.canCastTo(currSelfType, currFunc.selfType) == false) {
								self.addWarning(currFunc.name
									+ ' expects to be executed in the context of ' + currFunc.selfType.toString()
									+ ' (self is ' + currSelfType.toString() + ')');
							}
						}
					}
					statKind = currKind = KCall;
					currType = linter.funcArgs.returnType;
					currFunc = currType.getSelfCallDoc(self.getImports());
				};
				case KInc, KDec: { // x++, x--
					if (hasFlag(NoSfx)) break;
					if (!currKind.canPostfix()) break;
					checkConst();
					self.skip();
					statKind = currKind = nk;
					currType = GmlTypeDef.number;
				};
				case KDot, KNullDot: { // x.y
					self.skip();
					rc(self.readCheckSkip(KIdent, "field name after `.`"));
					var field = self.nextVal;
					
					// extract `Type` from `Type?` when doing `v?.field`
					if (nk == KNullDot && currType.isNullable()) currType = currType.unwrapParam();
					
					var enumType = currKind == KIdent ? GmlAPI.gmlEnums[currName] : null;
					
					currKind = nk == KDot ? KField : KNullField;
					var isStatic:Bool = false, nsType:GmlType = null;
					if (enumType != null) {
						currType = GmlTypeDef.int;
						currFunc = null;
						var ef = enumType.compMap[field];
						if (ef != null && ef.doc != null) {
							if (JsTools.rx(~/^\d+$/g).test(ef.doc)) {
								setValue = true;
								currValue = GmlLinterValue.VNumber(Std.parseFloat(ef.doc), ef.doc);
							} else {
								// todo: try to parse?
							}
						}
					} else {
						selfType = currType;
						isStatic = currType.isType();
						nsType = isStatic ? currType.unwrapParam() : currType;
					}
					if (enumType == null) switch (nsType) {
						case null: {
							currType = null;
							currFunc = null;
						};
						case TInst(_, _, KGlobal): {
							currType = GmlAPI.gmlGlobalTypes[field];
							currFunc = null;
						};
						case TInst(ctn, _, KCustom): {
							var wantWarn = false;
							var found = AceGmlTools.findNamespace(ctn, self.getImports(), function(ns) {
								wantWarn = true;
								if (isStatic) {
									currType = ns.staticTypes[field];
									currFunc = ns.docStaticMap[field];
									return ns.staticKind.exists(field);
								} else {
									currType = ns.getInstType(field);
									currFunc = ns.getInstDoc(field);
									return ns.getInstKind(field) != null;
								}
							});
							
							if (found) {
								if (currType != null) switch (selfType) {
									case TInst(_, sp, _) if (sp.length > 0): {
										currType = currType.mapTemplateTypes(sp);
									};
									default:
								}
							} else {
								var en = GmlAPI.gmlEnums[ctn];
								if (en != null) {
									wantWarn = true;
									if (en.items.exists(field)) {
										// TODO: come up with some method of indicating that enum
										// is typed as itself and may not cast to integers
										currType = GmlTypeDef.int;
										found = true;
									} else currType = GmlTypeDef.forbidden;
								} else currType = null;
								currFunc = null;
							}
							if (!found) {
								currType = null;
								currFunc = null;
								if (wantWarn && self.prefs.requireFields) {
									self.addWarning('Variable $field is not part of $ctn');
								}
							}
						};
						case TAnon(inf): {
							var fd = inf.fields[field];
							if (fd != null) {
								currType = fd.type;
								currFunc = fd.doc;
							} else {
								currType = null;
								currFunc = null;
								if (self.prefs.requireFields) self.addWarning(
									'Variable $field is not part of anonymous struct ' + nsType.toString()
								);
							}
						};
						default: {
							currType = null;
							currFunc = null;
						};
					}
				};
				case KSqbOpen, KNullSqb: { // x[i], x[?i], etc.
					self.skip();
					rc(GmlLinterArrayAccess.read(self, nk, newDepth, currType, currKind, currValue));
					currKind = GmlLinterArrayAccess.outKind;
					currType = GmlLinterArrayAccess.outType;
				};
				case KLiveIn: { // field in object
					if (hasFlag(NoOps)) break;
					self.skip();
					rc(self.readExpr(newDepth));
					currKind = KLiveIn;
					currType = GmlTypeDef.bool;
				};
				case KNot: { // field not in object
					if (hasFlag(NoOps) || self.keywords["in"] == null) break;
					self.seqStart.setTo(self.reader);
					self.skip();
					if (!self.skipIf(self.peek() == KLiveIn)) {
						self.reader.setTo(self.seqStart);
						break;
					}
					rc(self.readExpr(newDepth));
					currKind = KLiveIn;
					currType = GmlTypeDef.bool;
				};
				case KAs: { // <expr> as <type>
					if (hasFlag(NoOps)) break;
					self.skip();
					var tnp = q.pos;
					rc(self.readTypeName());
					var asType = GmlTypeDef.parse(GmlLinter.readTypeName_typeStr);
					if (self.prefs.warnAboutRedundantCasts && currType.equals(asType)) {
						self.addWarning('Redundant cast, ${currType.toString()} is already of type ${asType.toString()}');
					}
					if (!hasFlag(IsCast)) {
						var ex = GmlTypeCanCastTo.isExplicit;
						GmlTypeCanCastTo.isExplicit = true;
						self.checkTypeCast(currType, asType, "as", currValue);
						GmlTypeCanCastTo.isExplicit = ex;
					}
					currType = asType;
					currFunc = null;
					currKind = KAs;
				};
				case KQMark: { // x ? y : z
					if (hasFlag(NoOps)) break;
					self.checkTypeCast(currType, GmlTypeDef.bool, "ternary condition", currValue);
					self.skip();
					
					nullSafety.prepatch(linter);
					rc(self.readExpr(newDepth));
					currType = this.currType;
					rc(self.readCheckSkip(KColon, "a colon in a ternary operator"));
					
					nullSafety.elsepatch(linter);
					rc(self.readExpr(newDepth));
					var elseType = this.currType;
					if (currType != null) {
						if (elseType == null) {
							// shrug
						} else if (elseType.getKind() == KUndefined) { // ? type : undefined
							if (!currType.canCastTo(elseType)) {
								currType = GmlTypeDef.nullable(currType);
							}
						} else if (currType.getKind() == KUndefined) { // ? undefined : type
							if (!elseType.canCastTo(currType)) {
								currType = GmlTypeDef.nullable(elseType);
							}
						} else {
							self.checkTypeCast(this.currType, currType, "ternary else-value", this.currValue);
						}
					} else currType = elseType;
					nullSafety.postpatch(linter);
					currKind = KQMark;
				};
				case KNullCoalesce: { // x ?? y
					if (hasFlag(NoOps)) break;
					self.skip();
					rc(self.readExpr(newDepth));
					if (currType.isNullable()) currType = currType.unwrapParam();
					self.checkTypeCast(this.currType, currType, "?? operator value", this.currValue);
					currKind = KNullCoalesce;
				};
				default: {
					if (nk.isSetOp()) {
						if (!isStat()) return self.readError("Can't use " + self.nextDump() + " here.");
						checkConst();
						self.skip();
						var opv = currType != null ? self.nextVal : null;
						currKind = statKind = KSet;
						rc(self.readExpr(newDepth, None, null, currType));
						if (currType != null) {
							var opk:GmlLinterKind = opv == "+=" ? KAdd : KSub;
							self.checkTypeCastOp(currType, currValue, this.currType, this.currValue, opk, opv);
						}
						currType = null;
						flags.add(NoSfx);
					}
					else if (nk.isBinOp()) {
						if (hasFlag(NoOps)) break;
						self.skip();
						var localName = currKind == KIdent && isLocalIdent ? currName : null;
						rc(self.readOps(newDepth, currType, currValue, nk, self.nextVal, localName));
						mergeBinOpNullSafety();
						currType = this.currType;
						flags.add(NoSfx);
					}
					else break;
				};
			}
			if (!setValue) currValue = null;
			if (nk != KDot && nk != KNullDot) selfType = null;
		}
		//
		if (wasStat && !statKind.isStat()) {
			self.nextKind = statKind;
			self.nextVal = "";
			return self.readExpect("a statement");
		}
		//
		this.currName = currKind == KIdent ? currName : null;
		this.isLocalIdent = currKind == KIdent && isLocalIdent;
		this.currKind = currKind;
		this.currType = currType;
		this.selfType = selfType;
		this.currFunc = currFunc;
		this.currValue = currValue;
		this.nullSafety = nullSafety;
		return false;
	}
}
