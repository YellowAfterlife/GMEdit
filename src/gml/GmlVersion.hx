package gml;

/**
 * ...
 * @author YellowAfterlife
 */
@:build(tools.AutoEnum.build("int"))
@:enum abstract GmlVersion(Int) {
	/** not set yet */
	var none = 0;
	
	/** GMS1 */
	var v1 = 1;
	
	/** GMS2 */
	var v2 = 2;
	
	/** GMLive superset */
	var live = -1;
	
	public function getName() {
		return null;
	}
}
