package ace.extern;
import ace.AceMacro.jsOrx;
import tools.CharCode;
import ui.preferences.PrefData.PrefMatchMode;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("AceFilteredList") extern class AceFilteredList {
	var all:AceAutoCompleteItems;
	var filtered:AceAutoCompleteItems;
	var filterText:String;
	var exactMatch:Bool;
	var shouldSort:Bool;
	var gmlMatchMode:PrefMatchMode;
	
	function new(array:AceAutoCompleteItems, ?filterText:String):Void;
	function setFilter(str:String):Void;
	function filterCompletions(items:AceAutoCompleteItems, needle:String):AceAutoCompleteItems;
	
	public static inline function init(flProto:Dynamic):Void {
		AceFilteredListImpl.init(flProto);
	}
}
private class AceFilteredListImpl {
	public static function init(flProto:Dynamic):Void {
		var orig:js.lib.Function = flProto.filterCompletions;
		flProto.filterCompletions = function(items:AceAutoCompleteItems, needle:String):AceAutoCompleteItems {
			var _this:AceFilteredList = AceMacro.jsThis;
			var mode = _this.gmlMatchMode;
			if (mode == null) mode = ui.Preferences.current.compMatchMode;
			switch (mode) {
				case StartsWith, AceSmart: {
					_this.exactMatch = (mode == StartsWith);
					_this.shouldSort = (mode == AceSmart);
					return orig.call(AceMacro.jsThis, items, needle);
				};
				case Includes: {
					var results:AceAutoCompleteItems = [];
					_this.shouldSort = true;
					var lower = needle.toLowerCase();
					var length = needle.length;
					for (item in items) {
						var caption = jsOrx(item.caption, item.value, item.snippet);
						if (caption == null) continue;
						var pos = caption.toLowerCase().indexOf(lower);
						if (pos < 0) continue;
						item.exactMatch = pos == 0;
						item.matchMask = ((1 << length) - 1);
						item.rawScore = jsOrx(item.score, 0) - pos;
						results.push(item);
					}
					return results;
				};
				case SectionStart: {
					var results:AceAutoCompleteItems = [];
					_this.shouldSort = false;
					var length = needle.length;
					var nc:Int = needle.fastCodeAt(0);
					var nu:Bool = nc < "a".code || nc > "z".code; // ?"DsMC":"dSmc"
					for (item in items) {
						var caption = jsOrx(item.caption, item.value, item.snippet);
						if (caption == null) continue;
						var c1:Int = -1, c0:Int, c2:Int;
						var np = 0, c1u:Bool;
						var i = 0;
						while (i < caption.length) {
							c0 = c1; c1 = caption.fastCodeAt(i); i++;
							var proc_SectionStart_break:Bool;
							inline function proc_SectionStart(z:Bool):Bool {
								// case-insensitively compare next needle char to section start
								c1u = z;
								nc = needle.fastCodeAt(np);
								if (c1u) {
									if (nc >= "a".code && nc <= "z".code) nc += "A".code - "a".code;
								} else {
									if (nc >= "A".code && nc <= "Z".code) nc -= "A".code - "a".code;
								}
								if (nc != c1 || ++np >= length) {
									// either not the right char or we're done with this needle
									proc_SectionStart_break = true;
								} else {
									proc_SectionStart_break = false;
									while (np < length) {
										nc = needle.fastCodeAt(np);
										c1 = caption.fastCodeAt(i); i++;
										if (nu) {
											if (nc < "a".code || nc > "z".code) break;
											if (c1 >= "A".code && c1 <= "Z".code) nc += "A".code - "a".code;
										} else {
											if (nc < "A".code || nc > "Z".code) break;
											if (c1 >= "a".code && c1 <= "z".code) nc += "a".code - "A".code;
										}
										if (c1 != nc) {
											proc_SectionStart_break = true;
											break;
										}
										np++;
									}
								}
								return proc_SectionStart_break;
							}
							switch (c0) {
								case "_".code, ".".code, -1: {
									if (proc_SectionStart(c1 >= "A".code && c1 <= "Z".code)) break;
								};
								case _ if ((c0 >= "a".code && c0 <= "z".code)
									&& (c1 >= "A".code && c1 <= "Z".code)
								): {
									if (proc_SectionStart(true)) break;
								};
							}
						}
						if (np < length) continue;
						item.matchMask = ((1 << length) - 1);
						item.exactMatch = false;
						item.rawScore = jsOrx(item.score, 0);
						results.push(item);
					}
					return results;
				};
			}
		};
	}
}
