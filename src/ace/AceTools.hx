package ace;
import ace.extern.*;
import editors.EditCode;
import gml.GmlScopes;
import haxe.extern.EitherType;
import ace.AceWrap;
import js.html.Element;
import ui.Preferences;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class AceTools {
	
	/**
	 * Instantiates Ace and binds all the various GMEdit-specific extensions to it.
	 * Options-object can be used to exclude specific features if you don't need them.
	 */
	public static function createEditor(element:EitherType<String, Element>, ?options:AceWrapOptions):AceWrap {
		return new AceWrap(element, options);
	}
	
	/**
	 * Creates a new Ace editor session and does GMEdit-specific setup for it.
	 */
	public static function createSession(context:EitherType<String, AceDocument>, mode:Dynamic):AceSession {
		var session = new AceSession(context, mode);
		session.gmlScopes = new GmlScopes(session);
		session.setUndoManager(new AceUndoManager());
		// todo: does Mac version of GMS2 use Mac line endings? Probably not
		session.setOption("newLineMode", "windows");
		session.setOption("tabSize", Preferences.current.tabSize);
		session.setOption("useSoftTabs", Preferences.current.tabSpaces);
		return session;
	}
	
	public static function bindSession(session:AceSession, editor:EditCode):Void {
		session.gmlEditor = editor;
		session.gmlFile = editor.file;
	}
	
	public static function cloneSession(session:AceSession):AceSession {
		var copy = createSession(session.doc, session.modeId);
		copy.setOption("useSoftTabs", session.getOption("useSoftTabs"));
		bindSession(copy, session.gmlEditor);
		return copy;
	}
}
