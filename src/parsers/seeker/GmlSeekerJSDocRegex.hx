package parsers.seeker;
import js.lib.RegExp;

/**
 * ...
 * @author YellowAfterlife
 */
class GmlSeekerJSDocRegex {
	public static var jsDoc_full:RegExp = new RegExp("^///\\s*" // start
		+ "\\w*[ \t]*(\\(.+)" // `func(...`
	);
	/** 2.3 only! */
	public static var jsDoc_func:RegExp = new RegExp("^///\\s*" // start
		+ "@func\\s+"
		+ "(\\w+)\\s*" // name -> $1
		+ "\\(" + "(.*)" + "(\\).*)" // args -> $2 (greedy)
	);
	public static var jsDoc_param = new RegExp("^///\\s*"
		+ "@(?:arg|param|argument)\\s+"
		+ "(?:\\{(.*?)\\}\\s*)?" // {type}?
		+ "(\\S+(?:\\s+=.+)?)" // `arg` or `arg=value` -> $1
	);
	public static var jsDoc_hint = new RegExp("^///\\s*"
		+ "@hint\\b\\s*"
		+ "(?:\\{(.+)?\\}\\s*)?" // type -> $1
		+ "(new\\b\\s*)?" // constructor mark -> $2
		+ "(.+)" // the stuff we'll have to parse ourselves
	);
	public static var jsDoc_hint_extimpl = new RegExp("^///\\s*"
		+ "@hint\\b\\s*"
		+ "(\\w+)" // name
		+ "(?:<.*?>)?" // type params
		+ "\\b\\s*"
		+ "(extends|implements)"
		+ "\\b\\s*"
		+ "(\\w+)" // name
	);
	public static var jsDoc_self = new RegExp("^///\\s*"
		+ "@(?:self|this)\\b\\s*"
		+ "\\{(\\w+)\\}"
	);
	public static var jsDoc_return = new RegExp("^///\\s*"
		+ "@return(?:s)?\\b\\s*"
		+ "\\{(.*?)\\}"
	);
	
	public static var jsDoc_implements = new RegExp("^///\\s*"
		+ "@implement(?:s)?"
		+ "(?:\\b\\s*\\{(\\w+)\\})?"
	);
	public static var jsDoc_implements_line = new RegExp("^\\s*(\\w+)");
	
	public static var jsDoc_interface = new RegExp("^///\\s*"
		+ "@interface\\b\\s*"
		+ "(?:\\{(\\w+)\\})?"
	);
	
	public static var jsDoc_is = new RegExp("^///\\s*"
		+ "@is(?:s)?"
		+ "\\b\\s*\\{(.+?)\\}"
		+ "\\s*(.*)"
	);
	public static var jsDoc_is_line = (function() {
		var id = "[_a-zA-Z]\\w*";
		return new RegExp("^\\s*(?:" + [
			'globalvar\\s+($id(?:\\s*,\\s*$id)*)', // globalvar name[, name2]
			'global\\s*\\.\\s*($id)\\s*=', // global.name=
			'(?:static\\s+)?($id)\\s*=' // name= or static name=
		].join("|") + ")");
	})();
	public static var jsDoc_template = new RegExp("^///\\s*"
		+ "@template\\b\\s*"
		+ "(?:\\{(.*?)\\}\\s*)?"
		+ "(\\S+)"
	);
	public static var jsDoc_typedef = new RegExp("^///\\s*"
		+ "@typedef\\b\\s*"
		+ "\\{(.*?)\\}\\s*"
		+ "(\\w+)\\s*"
		+ "(?:<(.*?)>)?"
	);
	
	public static var jsDoc_index_redirect = new RegExp("^///\\s*"
		+ "@index_redirect\\b\\s*"
		+ "(.*)"
	);
	
	public static var gmlDoc_full = new RegExp("^\\s*\\w*\\s*\\(.*\\)");
}