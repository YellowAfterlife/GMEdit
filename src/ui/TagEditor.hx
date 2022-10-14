package ui;
import electron.Dialog;
import gml.Project;
import haxe.io.Path;
import js.html.Element;
import js.html.TextAreaElement;
import tools.JsTools;
import tools.macros.SynSugar;
import yy.YyProject;
import yy.YyResource;
using tools.HtmlTools;
using tools.NativeArray;

/**
 * ...
 * @author YellowAfterlife
 */
class TagEditor {
	public static var element:Element;
	public static var textarea:TextAreaElement;
	public static var currPath:String;
	public static var isDir:Bool;
	public static var targetEl:Element;
	public static function show(relPath:String, _isDir:Bool) {
		var ok = false;
		for (_ in 0 ... 1) {
			var tags:Array<String>;
			try {
				var pj = Project.current;
				if (_isDir) {
					var yyp:YyProject = pj.readYyFileSync(Project.current.name);
					var folder = yyp.Folders.findFirst(q -> q.folderPath == relPath);
					if (folder == null) {
						Dialog.showError('Couldn\'t find folder "$relPath" in the project file.');
						continue;
					}
					tags = folder.tags;
				} else {
					var yy:YyResource = pj.readYyFileSync(relPath);
					tags = yy.tags;
				}
				if (tags == null) tags = [];
			} catch (x:Dynamic) {
				Dialog.showError("Couldn't get tags:\n" + x);
				continue;
			}
			//
			ok = true;
			currPath = relPath;
			isDir = _isDir;
			var pt = new Path(relPath);
			pt.ext = null;
			if (!_isDir) pt.dir = null;
			targetEl.setInnerText(pt.toString());
			textarea.value = tags.join("\n");
		}
		element.setDisplayFlag(ok);
	}
	public static function init() {
		element = Main.document.createDivElement();
		element.id = "tag-editor";
		element.className = "popout-window";
		element.setDisplayFlag(false);
		element.innerHTML = SynSugar.xmls(<html>
			<label for="tags">Tags (one per line):</label>
			<textarea name="tags"></textarea>
			<div>Editing tags for "<span name="target"></span>"</div>
			<div class="tag-editor-controls">
				<input type="button" name="accept" value="Apply" />
				<span></span>
				<input type="button" name="cancel" value="Cancel" />
			</div>
		</html>);
		Main.document.querySelectorAuto("#main", Element).insertAfterSelf(element);
		textarea = element.querySelectorAuto('[name="tags"]');
		targetEl = element.querySelectorAuto('[name="target"]');
		element.querySelector('[name="accept"]').onclick = function(_) {
			var tags = textarea.value.split("\n");
			tags.filterSelf(tag -> StringTools.trim(tag) != "");
			for (_ in 0 ... 1) try {
				inline function tagsDiffer(_tags:Array<String>):Bool {
					return _tags == null
						? tags.length != 0
						: tags.join("\n") != _tags.join("\n");
				}
				var pj = Project.current;
				if (isDir) {
					var yypRel = Project.current.name;
					var yyp:YyProject = pj.readYyFileSync(yypRel);
					var folder = yyp.Folders.findFirst(q -> q.folderPath == currPath);
					if (folder == null) {
						Dialog.showError('Couldn\'t find folder "$currPath" in the project file.');
						continue;
					}
					if (tagsDiffer(folder.tags)) {
						var oldTags = folder.tags;
						folder.tags = tags;
						pj.writeYyFileSync(yypRel, yyp);
					}
				} else {
					var yy:YyResource = pj.readYyFileSync(currPath);
					if (tagsDiffer(yy.tags)) {
						yy.tags = tags;
						pj.writeYyFileSync(currPath, yy);
					}
				}
			} catch (x:Dynamic) {
				Dialog.showError("Couldn't save tags:\n" + x);
			}
			element.setDisplayFlag(false);
		};
		element.querySelector('[name="cancel"]').onclick = function(_) {
			element.setDisplayFlag(false);
		};
	}
}