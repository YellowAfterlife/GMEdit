package ui;
import js.html.Element;
import tools.JsTools;
import tools.macros.SynSugar;
using tools.HtmlTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TagEditor {
	public static var element:Element;
	public static function show() {
		element.setDisplayFlag(true);
	}
	public static function init() {
		element = Main.document.createDivElement();
		element.id = "tag-editor";
		element.setDisplayFlag(false);
		element.innerHTML = SynSugar.xmls(<html>
			<label for="tags">Tags (one per line):</label>
			<textarea name="tags"></textarea>
			<div class="tag-editor-controls">
				<input type="button" name="accept" value="Apply" />
				<span></span>
				<input type="button" name="accept" value="Cancel" />
			</div>
		</html>);
		
		//show();
	}
}