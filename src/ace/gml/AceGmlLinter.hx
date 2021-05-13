package ace.gml;
import ace.AceWrap;
import ace.AceWrapCommonCompleters.AfterExecArgs;
import ace.extern.AceDelayedCall;
import ace.extern.AceSession;
import file.kind.KGml;
import parsers.linter.GmlLinter;
import tools.JsTools;

/**
 * ...
 * @author YellowAfterlife
 */
class AceGmlLinter {
	public var editor:AceWrap;
	public function new() {
		
	}
	
	public function canRunLinterFor(session:AceSession):Bool {
		var kind = session.gmlFile.kind;
		return Std.is(kind, KGml) && (cast kind:KGml).canSyntaxCheck;
	}
	
	public function runLinter(session:AceSession, isDelay:Bool) {
		var maxLines = GmlLinter.getOption(function(p) {
			return isDelay ? p.liveIdleMaxLines : p.liveMaxLines;
		});
		if (session.getLength() > maxLines) return;
		
		var now = Date.now().getTime();
		var minDelay = GmlLinter.getOption((p) -> p.liveMinDelay);
		if (now < runLinter_time + minDelay) return;
		runLinter_time = now;
		
		GmlLinter.runFor(session.gmlEditor, {
			editor: editor,
			session: session,
			setLocals: true,
			updateStatusBar: false,
		});
		session.gmlLinterDirty = false;
		var um = session.getUndoManager();
		if (um != null) session.gmlLinterRevision = um.getRevision();
	}
	var runLinter_time:Float = 0;
	
	public function onLinterDelay() {
		// switched tabs?:
		var session = editor.session;
		if (session != onLinterDelay_session) return;
		if (!canRunLinterFor(session)) return;
		
		runLinter(onLinterDelay_session, true);
	}
	var onLinterDelay_call:AceDelayedCall;
	var onLinterDelay_session:AceSession;
	
	public function onAfterExec(e:AfterExecArgs) {
		if (e.command.name != "insertstring") return;
		var session = e.editor.session;
		if (onLinterDelay_session != session) return;
		if (!canRunLinterFor(session)) return;
		switch (e.args) {
			case ";":
				if (!inline GmlLinter.getOption((p) -> p.liveCheckOnSemico)) return;
			case "\n":
				if (!inline GmlLinter.getOption((p) -> p.liveCheckOnEnter)) return;
			default:
				return;
		}
		runLinter(session, false);
	}
	
	public function onKeyboardActivity(_) {
		var t = inline GmlLinter.getOption((p) -> p.liveIdleDelay);
		if (t <= 0) return;
		
		var session = editor.session;
		if (!session.gmlLinterDirty) {
			var u = session.getUndoManager();
			if (u == null) return;
			var rev = u.getRevision();
			if (rev != session.gmlLinterRevision) {
				session.gmlLinterRevision = rev;
				session.gmlLinterDirty = true;
			} else return;
		}
		
		onLinterDelay_session = session;
		onLinterDelay_call.delay(t);
	}
	
	public function bind(editor:AceWrap) {
		this.editor = editor;
		editor.commands.on("afterExec", (e) -> onAfterExec(e));
		editor.on("keyboardActivity", (e) -> onKeyboardActivity(e));
		var lang = AceWrap.require("ace/lib/lang");
		onLinterDelay_call = lang.delayedCall(function() onLinterDelay());
	}
}