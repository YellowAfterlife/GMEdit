package gmk;
import gmx.GmxAction;
import gmx.GmxActionImpl;
import gmx.SfGmx;
import tools.Aliases.GmlCode;
import tools.Aliases.GmlName;
using tools.NativeString;

/**
 * ...
 * @author YellowAfterlife
 */
class GmkActionImpl extends GmxActionImpl {
	override function getLibraryID(action:SfGmx):String {
		return action.get("library");
	}
	override function getActionID(action:SfGmx):Int {
		return Std.parseInt(action.get("id"));
	}
	override function getApplyTo(action:SfGmx):String {
		var val = action.findText("appliesTo");
		if (val.startsWith(".")) return val.substring(1);
		return val;
	}
	//
	override function getArgs(action:SfGmx):Array<SfGmx> {
		return action.find("arguments").findAll("argument");
	}
	override function getArgString(arg:SfGmx):String {
		return arg.text;
	}
	override function getArgScript(arg:SfGmx):GmlName {
		return arg.text;
	}
	override function getFirstArgString(action:SfGmx):GmlCode {
		return action.find("arguments").find("argument").text;
	}
	//
	override function getFunctionName(action:SfGmx):String {
		return action.findText("functionName");
	}
	override function getNotFlag(action:SfGmx):Bool {
		return action.findText("not") == "true";
	}
	// todo: more things
}