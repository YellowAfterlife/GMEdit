package parsers;

import ace.extern.*;
using tools.NativeArray;
using tools.NativeString;
using StringTools;

/**
 * Like GmlReader, but supports stacking states for macro parsing
 * @author YellowAfterlife
 */
@:keep class GmlReaderExt extends GmlReader {
	/** not obligatory */
	public var row:Int = 0;
	
	/** for calculating column */
	public var rowStart:Int = 0;
	
	public var name:String = "";
	
	public var showOnStack:Bool = true;
	
	/** May return the next line for consumption */
	public var onEOF:GmlReaderExt->String = null;
	
	/** Increments row, sets row offset to current position */
	public function markLine():Void {
		row++;
		rowStart = pos;
	}
	
	/** Forms a stacktrace tail */
	public function getStack():String {
		var n = oldPos.length;
		var i = n + 1;
		var r = "";
		while (--i >= 0) {
			var _pos:Int, _rowStart:Int;
			if (i == n) {
				_pos = pos;
				_rowStart = rowStart;
			} else {
				if (!oldShowOnStack[i]) continue;
				_pos = oldPos[i];
				_rowStart = oldRowStart[i];
			}
			var _col = _pos - _rowStart;
			var _name = (i == n ? name : oldName[i]);
			r += (_name != null ? "\nfrom " + _name : "\nfrom")
				+ "[Ln " + ((i == n ? row : oldRow[i]) + 1)
				+ ", col " + (_col + 1) + "]";
			if (i > 0) {
				var _source = i == n ? source : oldSource[i];
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
		if (oldPos.length > 0) {
			return new AcePos(oldPos[0] - oldRowStart[0], oldRow[0]);
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
	var oldShowOnStack:Array<Bool> = [];
	
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
			showOnStack = oldShowOnStack.pop();
			if (pos < length) return true;
		}
		if (onEOF != null) {
			var s = onEOF(this);
			if (s != null) {
				source = s;
				length = s.length;
				pos = 0;
				rowStart = 0;
				row++;
				return true;
			}
		}
		return false;
	}
	override function get_eof():Bool {
		return !get_loop();
	}
	//
	public function pushSource(code:String, ?_name:String) {
		oldSource.push(source);
		oldPos.push(pos);
		oldLength.push(length);
		oldRow.push(row);
		oldRowStart.push(rowStart);
		oldName.push(name);
		oldShowOnStack.push(showOnStack);
		//
		source = code;
		pos = 0;
		row = 0;
		rowStart = 0;
		name = _name;
		length = code.length;
		showOnStack = true;
	}
	public function pushSourceExt(code:String, pos:Int, till:Int, row:Int, rowStart:Int, ?name:String) {
		pushSource(code, name);
		this.pos = pos;
		this.length = till;
		this.row = row;
		this.rowStart = rowStart;
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
		showOnStack = q.showOnStack; oldShowOnStack.setTo(q.oldShowOnStack);
	}
	public function clear():Void {
		source = ""; oldSource.clear();
		name = null; oldName.clear();
		pos = 0; oldPos.clear();
		length = 0; oldLength.clear();
		row = 0; oldRow.clear();
		rowStart = 0; oldRowStart.clear();
		showOnStack = true; oldShowOnStack.clear();
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
	
	public function print() {
		var i = this.depth;
		var r = [source.substring(pos, length)];
		while (--i >= 0) {
			r.push(oldSource[i].substring(oldPos[i], oldLength[i]));
		}
		return r;
	}
	
	public function getBottomOffset():Int {
		if (oldPos.length > 0) {
			return oldPos[oldPos.length - 1];
		} else return pos;
	}
	
	public function getWatchForDepth(depth:Int, n:Int) {
		var p = oldPos[depth];
		var bn = p < n ? p : n;
		var src = oldSource[depth];
		return src.fastSub(p - bn, bn) + "¦" + src.fastSub(p, n);
	}
}
