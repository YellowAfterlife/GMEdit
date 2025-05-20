package editors;
import js.html.Window;
import js.html.Console;
import ace.extern.*;
import ace.*;
import editors.Editor;
import electron.Dialog;
import file.kind.KCode;
import file.kind.misc.*;
import gml.GmlLocals;
import gml.file.*;
import gml.GmlAPI;
import gml.GmlImports;
import gml.Project;
import parsers.*;
import js.lib.RegExp;
import js.html.Element;
import synext.GmlExtImport;
import synext.GmlExtLambda;
import ui.Preferences;
import tools.NativeString;
import tools.Dictionary;

/**
 * ...
 * @author YellowAfterlife
 */
class EditCode extends Editor {
	
	public static var currentNew:EditCode = null;
	public static var container:Element;
	public var session:AceSession;
	public var kind:KCode;
	private var modePath:String;
	//
	public var locals:Dictionary<GmlLocals> = GmlLocals.defaultMap;
	public var imports:Dictionary<GmlImports> = GmlImports.defaultMap;
	//
	public var lambdaList:Array<String> = [];
	public var lambdaMap:Dictionary<String> = new Dictionary();
	public var lambdas:Dictionary<GmlExtLambda> = new Dictionary();
	
	/**
		Pop-out windows associated with this file
	**/
	public var acePopouts:Array<AcePopout> = [];
	
	public function new(file:GmlFile, modePath:String) {
		super(file);
		kind = cast(file.kind, KCode);
		this.modePath = modePath;
		element = container;
	}
	override function destroy() {
		for (p in acePopouts) p.destroy();
		super.destroy();
	}
	
	override public function ready():Void {
		if (GmlAPI.version.config.indexingMode == Local) {
			GmlSeeker.runSync(file.path, file.code, null, file.kind);
		}
		var _prev = currentNew;
		currentNew = this;
		// todo: this does not seem to cache per-version, but not a performance hit either?
		#if !test
		session = AceTools.createSession(file.code, { path: modePath, version: GmlAPI.version });
		AceTools.bindSession(session, this);
		//
		if (Project.current != null && Project.current.properties.indentWithTabs != null) {
			session.setOption("useSoftTabs", !Project.current.properties.indentWithTabs);
		} else if (Preferences.current.detectTab) {
			if (NativeString.contains(file.code, "\n\t")) {
				session.setOption("useSoftTabs", false);
			} else if (NativeString.contains(file.code, "\n  ")) {
				session.setOption("useSoftTabs", true);
			} else {
				session.setOption("useSoftTabs", Preferences.current.tabSpaces);
			}
		} else {
			session.setOption("useSoftTabs", Preferences.current.tabSpaces);
		}
		if (Project.current != null && Project.current.properties.indentSize != null) {
			session.setOption("tabSize", Std.int(Project.current.properties.indentSize));
		}
		Preferences.hookSetOption(session);
		if (modePath == "ace/mode/javascript") {
			session.setOption("useWorker", false);
		}
		#end
		//
		currentNew = _prev;
		//
		var data = file.path != null ? GmlSeekData.map[file.path] : null;
		if (data != null) {
			locals = data.locals;
			if (data.imports != null) imports = data.imports;
		}
	}
	
	override public function stateLoad() {
		if (file.path != null) AceSessionData.restore(this);
	}
	override public function stateSave() {
		AceSessionData.store(this);
	}
	
	override public function focusGain(prev:Editor):Void {
		super.focusGain(prev);
		Main.aceEditor.setSession(session);
	}
	
	public function setLoadError(text:String) {
		file.code = text;
		file.path = null;
		file.kind = KExtern.inst;
		return text;
	}
	override public function load(data:Dynamic):Void {
		var src = kind.loadCode(this, data);
		src = kind.preproc(this, src);
		file.code = src;
		file.syncTime();
	}
	
	public function postpImport(val:String):{val:String,sessionChanged:Bool} {
		var val_preImport = val;
		var path = file.path;
		val = GmlExtImport.post(val, this);
		if (val == null) {
			Dialog.showError(GmlExtImport.errorText);
			return null;
		}
		// if there are imports, check if we should be updating the code
		var data = path != null ? GmlSeekData.map[path] : null;
		var sessionChanged = false;
		var hadImports = data != null && data.imports != null;
		if (hadImports || GmlExtImport.post_numImports > 0) {
			var next = GmlExtImport.pre(val, this);
			if (data != null && data.imports != null) {
				imports = data.imports;
			} else imports = GmlImports.defaultMap;
			if (next != val_preImport) {
				var sd = AceSessionData.get(this);
				var session = session;
				session.doc.setValue(next);
				AceSessionData.set(this, sd);
				sessionChanged = true;
				Main.window.setTimeout(function() {
					var undoManager = session.getUndoManager();
					if (!Preferences.current.allowImportUndo) {
						session.setUndoManager(undoManager);
						undoManager.reset();
					}
					undoManager.markClean();
					file.changed = false;
				});
			} else if (!hadImports) {
				// if we didn't have imports before, data.imports would
				// be null and thus our imports were left untransformed.
				// But now they are OK so we can do it again and right.
				val = GmlExtImport.post(val_preImport, this);
				if (val == null) {
					Main.window.alert(GmlExtImport.errorText);
					return null;
				}
			}
		}
		return {val:val,sessionChanged:sessionChanged};
	}
	
	public function setSaveError(text:String):Void {
		Dialog.showError(text);
	}
	override public function save():Bool {
		var code = session.getValue();
		GmlFileBackup.save(file, code);
		//
		code = kind.postproc(this, code);
		if (code == null) return false;
		//
		var ok = kind.saveCode(this, code);
		if (!ok) return false;
		//
		file.savePost(code);
		return true;
	}
	override public function checkChanges():Void {
		#if gmedit.live
		return;
		#end
		var act = Preferences.current.fileChangeAction;
		if (act == Nothing) return;
		var status = kind.checkForChanges(this);
		if (status < 0) {
			switch (Dialog.showMessageBox({
				title: "File missing: " + file.name,
				message: "The source file is no longer found on disk. "
					+ "What would you like to do?",
				buttons: [
					"Keep editing",
					"Close the file"
				], cancelId: 0,
			})) {
				case 1: {
					file.path = null;
					Main.window.setTimeout(function() {
						file.tabEl.querySelector(".chrome-tab-close").click();
					});
				};
				default: file.path = null;
			}
			return;
		}
		if (status > 0) try {
			var prev = file.code;
			var newContent = file.readContent();
			file.load(newContent);
			//
			var rxr = new RegExp("\\r", "g");
			var check_0 = NativeString.trimRight(prev);
			check_0 = NativeString.replaceExt(check_0, rxr, "");
			var check_1 = NativeString.trimRight(file.code);
			check_1 = NativeString.replaceExt(check_1, rxr, "");
			//
			function finishChange():Void {
				if (session.getValue() != file.code) {
					session.setValue(file.code);
				}
				plugins.PluginEvents.fileReload({file:file});
				file.savePost_shared(newContent, true);
				// TODO: need to also run this if we opened a resource that had changes
				// since we have last looked at it.
			}
			//
			var dlg:Int = 0;
			if (check_0 == check_1) {
				// OK!
			} else if (!file.changed) {
				if (act != Ask) {
					finishChange();
				} else dlg = 1;
			} else dlg = 2;
			//
			if (dlg != 0) {
				//Console.log(StringTools.replace(prev, "\r", "\\r"));
				//Console.log(StringTools.replace(file.code, "\r", "\\r"));
				function printSize(b:Float) {
					inline function toFixed(f:Float):String {
						return (untyped f.toFixed)(2);
					}
					if (b < 10000) return b + "B";
					b /= 1024;
					if (b < 10000) return toFixed(b) + "KB";
					b /= 1024;
					if (b < 10000) return toFixed(b) + "MB";
					b /= 1024;
					return toFixed(b) + "GB";
				}
				var sz1 = printSize(file.code.length);
				var sz2 = printSize(session.getValue().length);
				var bt = Dialog.showMessageBox({
					title: "File conflict for " + file.name,
					message: 'Source file changed ($sz1) ' + (dlg == 2
						? 'but you have unsaved changes ($sz2)'
						: 'while the current version is $sz2'
					) + '. What would you like to do?',
					buttons: ["Reload file", "Keep current", "Open changes in a new tab"],
					cancelId: 1,
				});
				switch (bt) {
					case 0: {
						finishChange();
					};
					case 1: { };
					case 2: {
						var name1 = file.name + " <copy>";
						GmlFile.next = new GmlFile(name1, null, file.kind, file.code);
						ui.ChromeTabs.addTab(name1);
					};
				}
			}
		} catch (e:Dynamic) {
			Console.error("Error applying changes: ", e);
		}
	}
}
