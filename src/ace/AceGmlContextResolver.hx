package ace;
import ace.extern.AcePos;
import ace.extern.AceSession;
import ace.extern.AceToken;
import ace.extern.AceTokenIterator;
import gml.GmlAPI;
import gml.type.GmlType;
import parsers.linter.GmlLinter;
import parsers.GmlReaderExt;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlContextResolver {
	public static function run(session:AceSession, pos:AcePos, ?selfOnly:Bool):AceGmlContextResolver_result {
		var tillRow = pos.row;
		var tillCol = pos.column;
		//
		var editor = session.gmlEditor;
		var scope = session.gmlScopes.get(tillRow);
		var startRow = tillRow;
		while (startRow > 0) {
			if (session.gmlScopes.get(startRow - 1) == scope) startRow--; else break;
		}
		//
		var iter = new AceTokenIterator(session, tillRow, tillCol);
		var iter_tk:AceToken;
		var brackets = [];
		//
		var lt:GmlLinter = null, ltReader:GmlReaderExt = null;
		//
		while ((iter_tk = iter.stepBackward()) != null) {
			var iter_row = iter.getCurrentTokenRow();
			if (iter_row < startRow) break;
			switch (iter_tk.type) {
				case "curly.paren.rparen": brackets.push({
					delta: 1,
					col: iter.getCurrentTokenColumn(),
					row: iter_row,
				});
				case "curly.paren.lparen": brackets.push({
					delta: -1,
					col: iter.getCurrentTokenColumn(),
					row: iter_row,
				});
				case "keyword" if (iter_tk.value == "with"): @:privateAccess {
					var iter_col = iter.getCurrentTokenColumn();
					if (lt == null) {
						lt = new GmlLinter();
						lt.runPre("", editor, GmlAPI.version);
						ltReader = lt.reader;
						for (_reader in [ltReader, lt.seqStart, lt.__peekReader]) {
							_reader.onEOF = function(r:GmlReaderExt) {
								var nrow = r.row + 1;
								if (nrow > tillRow) return null;
								if (nrow == tillRow) {
									// input ends at provided position
									return session.getLine(tillRow).substring(0, tillCol);
								} else return session.getLine(nrow);
							}
						}
					}
					
					// position ltReader after the `with` keyword:
					ltReader.source = session.getLine(iter_row);
					ltReader.length = ltReader.source.length;
					ltReader.pos = iter_col + iter_tk.length;
					ltReader.row = iter_row;
					ltReader.rowStart = 0;
					
					// skip the expression:
					lt.readExpr(0);
					var type = lt.expr.currType;
					
					// todo: if the next token is `{`, do a quick loop on brackets instead
					
					// Here comes the stupid part:
					// We're limiting the reader to have EOF at the target position;
					// We're going to try reading the loop body;
					// If it fails with an EOF, that means that the target is in the loop.
					if (!lt.readLoopStat(0)) continue; // (not in the block!)
					
					if (ltReader.loop) {
						// a linter error and my condolences for your type information
						return { self: null, other: null };
					}
					
					return {
						self: type,
						other: selfOnly ? null : run(session, iter.getCurrentTokenPosition(), true).self
					}
				};
			}
		}
		return {
			self: AceGmlTools.getSelfType({ session: session, scope: scope }),
			other: AceGmlTools.getOtherType({ session: session, scope: scope }),
		};
	}
}
typedef AceGmlContextResolver_result = {
	self: GmlType,
	other: GmlType
}