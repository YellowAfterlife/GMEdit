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
import tools.Aliases;
import parsers.linter.GmlLinter;
import tools.JsTools;
import tools.macros.GmlLinterMacros.*;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterExpr {
	static function __readExpr_invalid(self:GmlLinter, flags:GmlLinterReadFlags):FoundError {
		return @:privateAccess self.readExpect(flags.has(AsStat) ? "a statement" : "an expression");
	}
	
	static function readExpr_checkConst(self:GmlLinter, currName:GmlName, currKind:GmlLinterKind) @:privateAccess {
		switch (currKind) {
			case KIdent: {
				if (self.localKinds[currName] == KConst) {
					self.addWarning('Assigning to a `const` local `$currName`');
				}
			};
			case KNullField, KNullArray: {
				self.addError("Null-conditional values cannot be assigned to");
			};
			default:
		}
	}
	
	public static function read(
		self:GmlLinter, oldDepth:Int, flags:GmlLinterReadFlags, _nk:GmlLinterKind, targetType:GmlType
	):FoundError {
		var newDepth = oldDepth + 1;
		var q = self.reader;
		var nk:GmlLinterKind = self.nextOr(_nk);
		//
		inline function invalid():FoundError {
			return __readExpr_invalid(self, flags);
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
		var currName = nk == KIdent ? self.nextVal : null;
		var selfType:GmlType = null;
		var currType:GmlType = null;
		var currFunc:GmlFuncDoc = null;
		var currValue:GmlLinterValue = null;
		//
		inline function checkConst():Void {
			readExpr_checkConst(self, currName, currKind);
		}

		//
		switch (nk) {
			case KNumber: {
				currType = GmlTypeDef.number;
				var nv = self.nextVal;
				currValue = VNumber(Std.parseFloat(nv), nv);
			};
			case KString: {
				currType = GmlTypeDef.string;
				var nv = self.nextVal;
				currValue = VString(null, nv); // todo: probably parse string?
			};
			case KUndefined: {
				currType = GmlTypeDef.undefined;
				currValue = VUndefined;
			};
			case KIdent: {
				if (hasFlag(HasPrefix)) checkConst();
				if (self.localKinds[currName] == KGhostVar) {
					self.addWarning('Trying to access a variable `$currName` outside of its scope');
				}
				// linting #properties:
				if (self.isProperties && isStat()) {
					if (self.skipIf(self.peek() == KColon)) { // name:type
						rc(self.readCheckSkip(KIdent, "variable type"));
						if (self.skipIf(self.peek() == KLT)) {
							// we know that it's valid or else GmlObjectProperties would prevent you from saving
							var depth = 1;
							while (q.loop) {
								switch (self.next()) {
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
			};
			case KParOpen: {
				rc(self.readExpr(newDepth));
				if (self.next() != KParClose) return self.readExpect("a `)`");
				currType = self.readExpr_currType;
				currFunc = self.readExpr_currFunc;
				currValue = self.readExpr_currValue;
			};
			case KNew: {
				rc(self.readExpr(newDepth, IsNew));
				currType = JsTools.or(self.readExpr_currType, GmlTypeDef.simple(self.readExpr_currName));
				currFunc = currType.getSelfCallDoc(self.getImports());
			};
			case KCast: {
				rc(self.readExpr(newDepth, GmlLinterReadFlags.NoOps.with(IsCast)));
				if (self.readExpr_currKind == KAs) {
					currType = self.readExpr_currType;
				} else currType = null;
				currFunc = null;
			};
			case KNot, KBitNot: {
				rc(self.readExpr(newDepth));
				if (nk == KNot) {
					self.checkTypeCastBoolOp(self.readExpr_currType, self.readExpr_currValue, "!");
					currType = GmlTypeDef.bool;
					switch (self.readExpr_currValue) {
						case null:
						case GmlLinterValue.VNumber(f, _):
							var v = f > 0.5 ? 0 : 1;
							currValue = VNumber(v, "" + v);
						default:
					}
				} else {
					self.checkTypeCast(self.readExpr_currType, GmlTypeDef.int, "~", self.readExpr_currValue);
					currType = GmlTypeDef.int;
					switch (self.readExpr_currValue) {
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
				self.checkTypeCast(self.readExpr_currType, GmlTypeDef.number, nk == KInc ? "++" : "--", self.readExpr_currValue);
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
						anonFields[key] = new GmlTypeAnonField(self.readExpr_currType, self.readExpr_currFunc);
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
					self.checkTypeCast(self.readExpr_currType, GmlTypeDef.number, nk == KAdd ? "+" : "-", self.readExpr_currValue);
					currType = GmlTypeDef.number;
					if (nk == KAdd) {
						currValue = self.readExpr_currValue;
					} else {
						switch (self.readExpr_currValue) {
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
		while (q.loop) {
			nk = self.peek();
			switch (nk) {
				case KSet: {
					if (isStat()) {
						checkConst();
						self.skip();
						flags.remove(AsStat);
						statKind = KSet;
						rc(self.readExpr(newDepth, None, null, currType));
						self.checkTypeCast(self.readExpr_currType, currType, "assignment", self.readExpr_currValue);
						currType = null;
					} else {
						if (hasFlag(NoOps)) break;
						if (self.optNoSingleEqu) {
							self.addWarning("Using single `=` as a comparison operator");
						}
						self.skip();
						rc(self.readOps(newDepth, currType, currValue, nk, "="));
						flags.add(NoSfx);
						currType = self.readExpr_currType;
					}
				};
				case KParOpen: { // fn(...)
					if (self.optForbidNonIdentCalls && !currKind.canCall()) {
						return self.readError('Expression ${currKind.getName()} is not callable');
					}
					if (hasFlag(NoSfx)) return self.readError("Can't call this");
					self.skip();
					var argsSelf = currKind == KIdent && currName == "method" ? GmlTypeDef.methodSelf : selfType;
					var argc = self.readArgs(newDepth, false, currFunc, argsSelf, currType);
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
					currType = GmlLinter.readArgs_outType;
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
					
					currKind = nk == KDot ? KField : KNullField;
					var isStatic = currType.isType();
					var nsType = isStatic ? currType.unwrapParam() : currType;
					var ctn = nsType.getNamespace();
					selfType = currType;
					switch (nsType) {
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
								if (wantWarn && self.optRequireFields) {
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
								if (self.optRequireFields) self.addWarning(
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
				};
				case KAs: { // <expr> as <type>
					if (hasFlag(NoOps)) break;
					self.skip();
					var tnp = q.pos;
					rc(self.readTypeName());
					var asType = GmlTypeDef.parse(GmlLinter.readTypeName_typeStr);
					if (self.optWarnAboutRedundantCasts && currType.equals(asType)) {
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
					rc(self.readExpr(newDepth));
					currType = self.readExpr_currType;
					rc(self.readCheckSkip(KColon, "a colon in a ternary operator"));
					rc(self.readExpr(newDepth));
					var elseType = self.readExpr_currType;
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
							self.checkTypeCast(self.readExpr_currType, currType, "ternary else-value", self.readExpr_currValue);
						}
					} else currType = elseType;
					currKind = KQMark;
				};
				case KNullCoalesce: { // x ?? y
					if (hasFlag(NoOps)) break;
					self.skip();
					rc(self.readExpr(newDepth));
					if (currType.isNullable()) currType = currType.unwrapParam();
					self.checkTypeCast(self.readExpr_currType, currType, "?? operator value", self.readExpr_currValue);
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
							self.checkTypeCastOp(currType, currValue, self.readExpr_currType, self.readExpr_currValue, opk, opv);
						}
						currType = null;
						flags.add(NoSfx);
					}
					else if (nk.isBinOp()) {
						if (hasFlag(NoOps)) break;
						self.skip();
						rc(self.readOps(newDepth, currType, currValue, nk, self.nextVal));
						currType = self.readExpr_currType;
						flags.add(NoSfx);
					}
					else break;
				};
			}
			currValue = null;
			if (nk != KDot && nk != KNullDot) selfType = null;
		}
		//
		if (wasStat && !statKind.isStat()) {
			self.nextKind = statKind;
			self.nextVal = "";
			return self.readExpect("a statement");
		}
		self.readExpr_currName = currKind == KIdent ? currName : null;
		self.readExpr_currKind = currKind;
		self.readExpr_currType = currType;
		self.readExpr_selfType = selfType;
		self.readExpr_currFunc = currFunc;
		self.readExpr_currValue = currValue;
		return false;
	}
}