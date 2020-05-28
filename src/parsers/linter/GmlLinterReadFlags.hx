package parsers.linter;

/**
 * ...
 * @author YellowAfterlife
 */
enum abstract GmlLinterReadFlags(Int) {
	var None = 0;
	
	/** Do not attempt to read operators after expression */
	var NoOps = 1;
	
	/** Expression is being evaluated as a statement */
	var AsStat = 2;
	
	/** No suffixes (used after reading operators) */
	var NoSfx = 4;
	
	/** Semicolon is not required */
	var NoSemico = 8;
	
	/** Expression is being read after a ++ or -- */
	var HasPrefix = 16;
	
	/** Expression is being read after a `new` */
	var IsNew = 32;
	
	public inline function new(flag:Int) {
		this = flag;
	}
	public inline function has(flag:GmlLinterReadFlags) {
		return (toInt() & flag.toInt()) != 0;
	}
	public inline function toInt():Int {
		return cast this;
	}
	public inline function with(v:GmlLinterReadFlags):GmlLinterReadFlags {
		return cast (toInt() | v.toInt());
	}
	public inline function add(v:GmlLinterReadFlags):Void {
		this = cast (toInt() | v.toInt());
	}
	public inline function without(flag:GmlLinterReadFlags):GmlLinterReadFlags {
		return cast (toInt() & ~flag.toInt());
	}
	public inline function remove(flag:GmlLinterReadFlags):Void {
		this = cast (toInt() & ~flag.toInt());
	}
}
