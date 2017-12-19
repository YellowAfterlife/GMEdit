package tools;
import js.html.DivElement;
import js.html.Element;
import js.html.MouseEvent;

/**
 * ...
 * @author YellowAfterlife
 */
class HtmlTools {
	
}
extern class ChromeTab extends Element {
	public var gmlFile:GmlFile;
}
extern class TreeViewDir extends DivElement {
	public var treeItems:DivElement;
}
extern class TreeViewItem extends DivElement {
	public var gmlFile:GmlFile;
	public var gmlOpen:Null<MouseEvent>->Void;
}
