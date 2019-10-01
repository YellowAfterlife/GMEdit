package parsers.linter;
import tools.Aliases;
import tools.Dictionary;
import editors.EditCode;
import parsers.linter.GmlLinterKind;
import gml.GmlVersion;
import ace.extern.*;
import tools.macros.GmlLinterMacros.*;
import gml.GmlAPI;
using tools.NativeArray;
using tools.NativeString;

/**
 * ...
 * @author ...
 */
@:access(parsers.linter.GmlLinter)
class GmlLinterMFunc {
	public static function read(self:GmlLinter, q:GmlReaderExt, mfName:String) {
		var mf = GmlAPI.gmlMFuncs[mfName];
		q.skipSpaces0();
		if (q.read() != "(".code) return self.readExpect('a `(` after an #mfunc $mfName');
		var mfStart = q.pos;
		
		// so we want to read arguments without parsing them (yet):
		self.seqStart.setTo(q);
		var mcArgStart:Array<Int> = [];
		var mcArgTill:Array<Int> = [];
		var mcArgString:Array<String> = [];
		var mcArgRow:Array<Int> = [];
		var mcArgRowStart:Array<Int> = [];
		var mcArgSource = q.source;
		var mcArgContext = q.name;
		q.skipSpaces0();
		if (q.peek() == ")".code) {
			q.skip();
		} else {
			var mcArgDone = false;
			var argPos = q.pos;
			var argRow = q.row;
			var argRowStart = q.rowStart;
			inline function flushArg(till:Int):Void {
				mcArgStart.push(argPos);
				mcArgTill.push(till);
				mcArgString.push(null);
				mcArgRow.push(q.row);
				mcArgRowStart.push(q.rowStart);
				argRow = q.row;
				argRowStart = q.rowStart;
				argPos = q.pos;
			}
			//
			var depth = 1;
			while (q.loopLocal) {
				var p = q.pos;
				var c = q.read();
				switch (c) {
					case "(".code, "[".code, "{".code: depth++;
					case ")".code, "]".code, "}".code: if (--depth <= 0) {
						flushArg(p);
						mcArgDone = true;
						break;
					};
					case ",".code if (depth == 1): {
						flushArg(p);
					};
				}
			}
			if (!mcArgDone) return self.readSeqStartError('Unclosed () after an #mfunc $mfName');
		};
		
		// verify argument count / merge rest-arg:
		var mcArgc = mcArgStart.length;
		var mfArgc = mf.args.length;
		if (mcArgc > mfArgc) {
			if (mf.hasRest) {
				mcArgTill[mfArgc - 1] = mcArgTill.pop();
				mcArgStart.resize(mfArgc);
				mcArgTill.resize(mfArgc);
				mcArgRow.resize(mfArgc);
				mcArgRowStart.resize(mfArgc);
				mcArgString.resize(mfArgc);
			} else return self.readError('Too many arguments ($mcArgc/$mfArgc) for #mfunc $mfName');
		} else if (mcArgc < mfArgc) {
			return self.readError('Too few arguments ($mcArgc/$mfArgc) for #mfunc $mfName');
		}
		
		// push arguments and splitters in reverse order:
		var order = mf.order;
		var i = order.length;
		var mfPre = mfName + "_mf";
		while (--i >= 0) {
			var mfPre_i = mfPre + (i + 1);
			q.pushSource(mfPre_i, mfPre_i);
			q.showOnStack = false;
			var ord = order[i];
			var ai:Int;
			if (ord.isPlain()) {
				ai = ord.asPlain();
				q.pushSourceExt(mcArgSource, mcArgStart[ai], mcArgTill[ai],
					mcArgRow[ai], mcArgRowStart[ai], mcArgContext);
			} else switch (ord.kind) {
				case Plain: {};
				case Quoted: {
					// it's a valid string, do we care
					q.pushSource('"`magic`"', mcArgContext);
				};
				case Magic: {
					// note: doesn't pass valid reader state into magicMap handler,
					// but that's OK for the time being
					var mv = GmlExtMFunc.magicMap[ord.asArray()[1]](self.editor, q);
					q.pushSource(mv, 'magic[${ord.asArray()[1]}] in $mfName in $mcArgContext');
				};
				case Pre, Post, PrePost: {
					ai = ord.arg;
					var av = mcArgString[ai];
					if (av == null) {
						av = mcArgSource.substring(mcArgStart[ai], mcArgTill[ai]);
						mcArgString[ai] = av;
					}
					switch (ord.kind) {
						case Pre: av = av.insertAtPadLeft(ord.pstr(0));
						case Post: av = av.insertAtPadRight(ord.pstr(0));
						case PrePost: av = av.insertAtPadBoth(ord.pstr(0), ord.pstr(1));
						default: {};
					}
					q.pushSourceExt(av, 0, av.length, mcArgRow[ai],
						mcArgRowStart[ai] - mcArgStart[ai],
						'Concat in $mfName in $mcArgContext');
				};
			}
			q.showOnStack = false;
		}
		q.pushSource(mfPre + "0", mfPre + "0");
		q.showOnStack = false;
		return false;
	}
}
