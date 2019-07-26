package parsers;

import gml.GmlVersion;
import ace.extern.*;
using tools.NativeArray;
using tools.NativeString;
using StringTools;

/**
 * Like GmlReader, but supports stacking states for macro parsing
 * @author YellowAfterlife
 */
class GmlReaderExt extends GmlReader {
	/** not obligatory */
	public var row:Int = 0;
	
	/** for calculating column */
	public var rowStart:Int = 0;
	
	public var name:String = "";
	
	/** Increments row, sets row offset to current position */
	public function markLine():Void {
		row++;
		rowStart = pos;
	}
	
	/** Forms a stacktrace tail */
	public function getStack():String {
		var n = oldPos.length - 1;
		var r = "";
		for (i in -1 ... n + 1) {
			var _pos:Int, _rowStart:Int;
			if (i < 0) {
				_pos = pos;
				_rowStart = rowStart;
			} else {
				_pos = oldPos[i];
				_rowStart = oldRowStart[i];
			}
			var _col = _pos - _rowStart;
			r += "\nfrom "
				+ (i < 0 ? name : oldName[i])
				+ " [Ln " + ((i < 0 ? row : oldRow[i]) + 1)
				+ ", col " + (_col + 1) + "]";
			if (i < n) {
				var _source = i < 0 ? source : oldSource[i];
				var _rowEnd = _source.indexOf("\n", _rowStart);
				if (_rowEnd >= 0) {
					if (_source.fastCodeAt(_rowEnd - 1) == "\r".code) _rowEnd--;
				} else _rowEnd = _source.length;
				r += ": " + _source.substring(_rowStart, _rowEnd).insert(_col, "¦");
			}
		}
		return r;
	}
	
	public function getTopPos():AcePos {
		var i = oldPos.length - 1;
		if (i >= 0) {
			return new AcePos(oldPos[i] - oldRowStart[i], oldRow[i]);
		} else return new AcePos(pos - rowStart, row);
	}
	
	public function getTopPosString():String {
		return getTopPos().toString();
	}
	
	var oldSource:Array<String> = [];
	var oldPos:Array<Int> = [];
	var oldLength:Array<Int> = [];
	var oldRow:Array<Int> = [];
	var oldRowStart:Array<Int> = [];
	var oldName:Array<String> = [];
	
	public var depth(get, never):Int;
	private inline function get_depth():Int {
		return oldSource.length;
	}
	//
	override function get_loop():Bool {
		if (pos < length) return true;
		while (oldSource.length > 0) {
			source = oldSource.pop();
			pos = oldPos.pop();
			length = oldLength.pop();
			row = oldRow.pop();
			rowStart = oldRowStart.pop();
			name = oldName.pop();
			if (pos < length) return true;
		}
		return false;
	}
	override function get_eof():Bool {
		return !get_loop();
	}
	//
	public function pushSource(code:String, ?next:String) {
		oldSource.push(source);
		oldPos.push(pos);
		oldLength.push(length);
		oldRow.push(row);
		oldRowStart.push(rowStart);
		oldName.push(name);
		//
		source = code;
		pos = 0;
		row = 0;
		rowStart = 0;
		name = next;
		length = code.length;
	}
	//
	public function setTo(q:GmlReaderExt) {
		version = q.version;
		source = q.source; oldSource.setTo(q.oldSource);
		pos = q.pos; oldPos.setTo(q.oldPos);
		length = q.length; oldLength.setTo(q.oldLength);
		row = q.row; oldRow.setTo(q.oldRow);
		rowStart = q.rowStart; oldRowStart.setTo(q.oldRowStart);
		name = q.name; oldName.setTo(q.oldName);
	}
	public function clear():Void {
		source = "";
		pos = 0;
		length = 0;
		oldSource.clear();
		oldLength.clear();
		oldPos.clear();
		oldRow.clear();
		oldRowStart.clear();
	}
	// These are too similar to GmlReader implementations, hm
	@:access(GmlReader.skipComment_1)
	override public function skipComment():Int {
		var n = 0;
		while (loopLocal) {
			var c = read();
			if (c == "\n".code) {
				inline markLine();
				if (peek() == "#".code && GmlReader.skipComment_1(source, pos + 1)) break;
			} else if (c == "*".code && peek() == "/".code) {
				skip();
				break;
			}
		}
		return n;
	}
	
	override public function skipString1(qc:Int):Int {
		var c = peek(), n = 0;
		while (c != qc && loopLocal) {
			skip(); c = peek();
			if (c == "\n".code) inline markLine();
		}
		if (loopLocal) skip();
		return n;
	}
	
	override public function skipString2():Int {
		var n = 0;
		var c = peek();
		while (c != '"'.code && loopLocal) {
			if (c == "\\".code) {
				skip(); c = peek();
				switch (c) {
					case "x".code: skip(2);
					case "u".code: skip(4);
					case "\n".code: skip(); inline markLine();
					default: skip();
				}
			} else skip();
			c = peek();
		}
		if (loopLocal) skip();
		return n;
	}
}
