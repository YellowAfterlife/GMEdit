package ui.liveweb;
#if (gmedit.live && !gmedit.mini)
import ace.AceWrap;
import js.html.FrameElement;

/**
 * @author YellowAfterlife
 */
typedef LiveWebAPI = {
	?init:(api:LiveWebInit)->Void,
	?setAPI:(data:Dynamic)->Void,
	?setVersion:(ver:Int, runtime:String)->Void,
	?resyncAPI:()->Void,
	?run:(opt:LiveWebOptions, cb:LiveWebCallback)->Void,
	?print:(opt:LiveWebOptions, cb:LiveWebCallback)->Void,
	?stop:()->Bool,
}
typedef LiveWebInit = {
	?aceEditor:AceWrap,
	?isElectron:Bool,
	?iframePrefix:String,
	?gameFrame:FrameElement,
}
typedef LiveWebOptions = {
	?sources:Array<{name:String, code:String}>,
	?reload:Bool,
	?dryRun:Bool,
}
#end
typedef LiveWebCallback = (error:LiveWebError, js:String)->Void;
typedef LiveWebError = {
	file:String,
	row:Int,
	column:Int,
	text:String,
	error:Dynamic,
};
