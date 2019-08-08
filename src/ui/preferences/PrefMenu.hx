package ui.preferences;
import js.html.Element;
import ui.Preferences.*;

/**
 * ...
 * @author YellowAfterlife
 */
class PrefMenu {
	public static function build(out:Element):Void {
		PrefTheme.build(out);
		PrefMagic.build(out);
		PrefCode.build(out);
		PrefLinter.build(out, null);
		PrefNav.build(out);
		PrefBackups.build(out);
	}
}
