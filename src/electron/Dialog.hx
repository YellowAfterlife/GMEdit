package electron;

/**
 * https://electronjs.org/docs/api/dialog
 * @author YellowAfterlife
 */
@:native("Electron_Dialog") extern class Dialog {
	public static function showMessageBox(options:DialogMessageOptions, ?async:Int->Bool->Void):Int;
}
typedef DialogMessageOptions = {
	?type:DialogMessageType,
	buttons:Array<String>,
	message:String,
	?title:String,
	?detail:String,
	?checkboxLabel:String,
	?cancelId:Int,
	?defaultId:Int,
};
@:build(tools.AutoEnum.build("lq"))
@:enum abstract DialogMessageType(String) from String to String {
	var None;
	var Info;
	var Error;
	var Question;
	var Warning;
}
