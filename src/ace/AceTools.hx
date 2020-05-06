package ace;
import ace.extern.*;
import editors.EditCode;
import gml.GmlScopes;
import haxe.extern.EitherType;
import ace.AceWrap;
import js.html.Element;
import ui.Preferences;

/**
 * GMEdit-specific helpers for Ace.
 * Can also be called by plugins via GMEdit.aceTools.*
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
	 * Creates a new editor session and does GMEdit-specific setup for it.
	 */
	public static function createSession(context:EitherType<String, AceDocument>, mode:Dynamic):AceSession {
		var session = new AceSession(context, mode);
		session.gmlScopes = new GmlScopes(session);
		session.setUndoManager(new AceUndoManager());
		var pj = gml.Project.current;
		var newLineMode = pj != null ? pj.properties.newLineMode : null;
		if (newLineMode == null) {
			newLineMode = electron.FileWrap.isUnix ? "unix" : "windows";
		}
		session.setOption("newLineMode", newLineMode);
		session.setOption("tabSize", Preferences.current.tabSize);
		session.setOption("useSoftTabs", Preferences.current.tabSpaces);
		session.setOption("wrap", Main.aceEditor.getOption("wrap"));
		return session;
	}
	
	/**
	 * Links an editor session to a codeEditor
	 */
	public static function bindSession(session:AceSession, editor:EditCode):Void {
		session.gmlEditor = editor;
		session.gmlFile = editor.file;
	}
	
	/**
	 * Creates a copy of an editor session that is linked to the same codeEditor/file/document
	 */
	public static function cloneSession(session:AceSession):AceSession {
		var mode:Dynamic = session.modeRaw;
		var copy = createSession(session.doc, mode);
		copy.setOption("useSoftTabs", session.getOption("useSoftTabs"));
		bindSession(copy, session.gmlEditor);
		return copy;
	}
}
