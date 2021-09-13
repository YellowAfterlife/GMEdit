package parsers.linter.misc;

import parsers.linter.GmlLinterPrefs;

/**
 * ...
 * @author YellowAfterlife
 */
typedef GmlLinterPrefsState = { >GmlLinterPrefsImpl,
	?forbidNonIdentCalls:Bool,
	?suppressAll:Bool,
}