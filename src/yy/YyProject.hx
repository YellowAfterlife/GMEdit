package yy;
import yy.YyResourceRef;

/**
 * ...
 * @author YellowAfterlife
 */
typedef YyProject = {
	>YyBase,
	resources:Array<YyProjectResource>,
	//
	/** Exists 2.3 and forward */
	?Folders:Array<YyProjectFolder>,
	/** Exists 2.3 and forward */
	?TextureGroups:Array<YyTextureGroup>,
	//
	?MetaData: { IDEVersion: String },
};
typedef YyProjectFolder = {
	>YyBase,
	folderPath:String,
	order:Int,
	name:String,
}
typedef YyTextureGroup = {
	>YyBase,
	name: String,
	isScaled:Bool,
	autocrop:Bool,
	border:Int,
	mipsToGenerate:Int,
	groupParent:String,
	targets:Int,
}
typedef YyAssetBrowserData = {
	AssetColours:Array<YyAssetBrowserAssetColour>,
	Palette:Array<YyAssetBrowserColour>,
}
typedef YyAssetBrowserAssetColour = {
	Key: YyResourceRef,
	Value: YyAssetBrowserColour,
}
/** #AABBGGRR */
abstract YyAssetBrowserColour(String) {
	public function toCSS():String {
		if (StringTools.fastCodeAt(this, 0) == "#".code && this.length == 9) {
			return "#"
				+ this.substring(7, 9)
				+ this.substring(5, 7)
				+ this.substring(3, 5)
				+ this.substring(1, 3);
		} else return this;
	}
	public function toAlphaCSS(alpha:Float):String {
		if (StringTools.fastCodeAt(this, 0) == "#".code && this.length == 9) {
			var ah = Std.int(alpha * Std.parseInt("0x" + this.substring(1, 3)));
			return "#"
				+ this.substring(7, 9)
				+ this.substring(5, 7)
				+ this.substring(3, 5)
				+ StringTools.hex(ah, 2);
		} else return this;
	}
}
