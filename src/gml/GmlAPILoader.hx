package gml;
import electron.FileSystem;
import electron.FileWrap;
import gml.GmlAPI;
import gml.GmlVersionConfig;
import haxe.io.Path;
import js.lib.RegExp;
import parsers.GmlParseAPI;
import tools.ChainCall;
import tools.Dictionary;
import tools.JsTools;
import ui.Preferences;
#if lwedit
import ui.liveweb.LiveWeb;
#end
using tools.NativeString;
using tools.RegExpTools;
using tools.ERegTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:keep class GmlAPILoader {
	static var getContent_rx = new RegExp("\r\n", "g");
	static function getContent(path:String, fn:String->Void):Void {
		if (FileSystem.canSync) {
			var rp = path;
			if (FileSystem.existsSync(rp)) {
				var s = FileSystem.readFileSync(rp, "utf8");
				s = NativeString.replaceExt(s, getContent_rx, "\n");
				fn(s);
			} else fn(null);
		} else {
			FileSystem.readTextFile(path, function(e, s) {
				fn(e == null ? s : null);
			});
		}
	}
	
	static var rxInsertBefore = JsTools.rx(~/^\[\+(\w+)\]\s*(.+)$/gm);
	static var rxReplace = JsTools.rx(~/^(\w+).+$/gm);
	static function applyPatchFile(raw:String, txt:String) {
		rxInsertBefore.each(txt, function(mt:RegExpMatch) {
			var name = mt[1];
			var code = mt[2];
			var rx = new RegExp('^$name\\b', "gm");
			raw = raw.replaceExt(rx, function(next) {
				return code + "\n" + next;
			});
		});
		rxReplace.each(txt, function(mt:RegExpMatch) {
			var name = mt[1];
			var code = mt[0];
			var rx = new RegExp('^$name\\b.*$', "gm");
			raw = raw.replaceExt(rx, function(_) {
				return code;
			});
		});
		return raw;
	}
	
	public static function procHelp(conf:GmlVersionConfig, dir:String) {
		GmlAPI.helpURL = conf.helpURL;
		var helpIndexPath = conf.helpIndex;
		if (helpIndexPath != null) {
			helpIndexPath = dir + "/" + helpIndexPath;
			FileSystem.readTextFile(helpIndexPath, function(err, helpIndexJs) {
				if (err != null) return;
				GmlAPI.helpLookup = new Dictionary();
				helpIndexJs = helpIndexJs.substring(helpIndexJs.indexOf("["));
				helpIndexJs = helpIndexJs.substring(0, helpIndexJs.indexOf(";"));
				try {
					var helpIndexArr:Array<Array<Dynamic>> = haxe.Json.parse(helpIndexJs);
					for (pair in helpIndexArr) {
						var item:Dynamic = pair[1];
						if (Std.is(item, Array)) item = item[0][1];
						GmlAPI.helpLookup.set(pair[0], item);
					}
				} catch (x:Dynamic) {
					trace("Couldn't parse help index:", x);
				}
			});
		}
	}
	public static function loadPre(ctx:GmlAPILoadContext) {
		var conf = ctx.conf;
		var dir = ctx.dir;
		var confKeywords = conf.additionalKeywords;
		if (confKeywords != null) for (kw in confKeywords) {
			GmlAPI.stdKind.set(kw, "keyword");
		}
		
		var cx = new ChainCall();
		
		if (conf.assetFiles != null) for (file in conf.assetFiles) {
			cx.call(getContent, '$dir/$file', function(txt:String) {
				GmlParseAPI.loadAssets(txt, { kind: GmlAPI.stdKind, comp: GmlAPI.stdComp });
			});
		}
		
		var useDefault = false;
		var apiFiles = conf.apiFiles;
		if (apiFiles == null) apiFiles = ["default"];
		for (file in apiFiles) {
			if (file == "default") {
				useDefault = true;
				file = "fnames";
			}
			cx.call(getContent, '$dir/$file', function(s:String) {
				if (s != null) {
					ctx.raw = ctx.raw.nzcct("\n", s);
				} else if (file == "fnames") {
					Main.window.alert("Couldn't find fnames in " + dir);
				}
			});
		}
		
		if (useDefault) cx.call(getContent, dir + "/extra.gml", function(s:String) {
			// whatever missing in fnames
			if (s != null && s != "") ctx.raw += "\n" + s;
			#if lwedit
			ctx.raw += "\ntrace(...)";
			#end
		});
		
		// various corrections instead of editing fnames by hand
		if (useDefault) cx.call(getContent, dir + "/replace.gml", function(s:String) {
			if (s != null) ctx.raw = applyPatchFile(ctx.raw, s);
		});
		if (conf.patchFiles != null) for (rel in conf.patchFiles) {
			cx.call(getContent, '$dir/$rel', function(s:String) {
				if (s != null) ctx.raw = applyPatchFile(ctx.raw, s);
			});
		}
		
		
		if (useDefault) cx.call(getContent, dir + '/exclude.gml', function(s:String) {
			// deprecated and/or forbidden
			if (s != null) ~/^(\w+)(\*?)$/gm.each(s, function(rx:EReg) {
				var name = rx.matched(1);
				if (rx.matched(2) != "") {
					ctx.raw = new EReg('^$name.*$', "gm").replace(ctx.raw, "");
				} else {
					ctx.raw = new EReg('^$name\\b.*$', "gm").replace(ctx.raw, "");
				}
			});
		});
		
		if (useDefault) cx.call(getContent, dir + '/inst.gml', function(s:String) {
			// mark functions that need self-context
			if (s != null) ~/^(\w+)$/gm.each(s, function(rx:EReg) {
				var name = rx.matched(1);
				ctx.raw = new EReg('^$name\\b', "gm").replace(ctx.raw, ":" + name);
			});
		});
		
		// patch non-returning functions:
		if (useDefault) cx.call(getContent, dir + '/noret.gml', function(noRet:String) {
			~/^(\w+)$/gm.each(noRet, function(rx:EReg) {
				var r1 = new RegExp("^(" + rx.matched(1) + "\\(.*?\\))(?:->\\S*)", "gm");
				//ctx.raw = ctx.raw.
				//var name = rx.matched(1);
				//var doc = GmlAPI.stdDoc[name];
				//if (doc != null) doc.hasReturn = false;
			});
		});
		
		return cx;
	}
	static function getArgs():GmlParseAPIArgs {
		return {
			kind: GmlAPI.stdKind,
			doc: GmlAPI.stdDoc,
			comp: GmlAPI.stdComp,
			types: GmlAPI.stdTypes,
			typeExists: GmlAPI.stdTypeExists,
			namespaceDefs: GmlAPI.stdNamespaceDefs,
			typedefs: GmlAPI.stdTypedefs,
			fieldHints: GmlAPI.stdFieldHints,
			instComp: GmlAPI.stdInstComp,
			instCompMap: GmlAPI.stdInstCompMap,
			instKind: GmlAPI.stdInstKind,
			instType: GmlAPI.stdInstType,
			ukSpelling: GmlAPI.ukSpelling,
			version: GmlAPI.version,
			#if lwedit
			lwArg0: GmlAPI.lwArg0,
			lwArg1: GmlAPI.lwArg1,
			lwInst: GmlAPI.lwInst,
			lwConst: GmlAPI.lwConst,
			lwFlags: GmlAPI.lwFlags,
			#end
		};
	}
	public static function init() {
		var version = GmlAPI.version;
		GmlAPI.stdClear();
		GmlExternAPI.gmlResetOnDefine = version.resetOnDefine();
		if (version == GmlVersion.none) return;
		//
		GmlAPI.helpURL = null;
		GmlAPI.helpLookup = null;
		GmlAPI.ukSpelling = Preferences.current.ukSpelling;
		//
		var dir = version.dir;
		var conf:GmlVersionConfig = version.config;
		procHelp(conf, dir);
		var ctx = {
			conf: conf,
			dir: dir,
			raw: "",
		}
		var cx = loadPre(ctx);
		
		// concat customizations:
		#if !lwedit
		if (FileSystem.canSync) {
			var xdir = FileWrap.userPath + "/api/" + version.getName();
			if (FileSystem.existsSync(xdir))
			for (xrel in FileSystem.readdirSync(xdir)) {
				var xfull = xdir + "/" + xrel;
				if (FileSystem.statSync(xfull).isDirectory()) continue;
				if (xrel == "fnames") {
					cx.call(getContent, xfull, function(s:String) {
						ctx.raw += "\n" + s;
					});
					continue;
				}
				var xp = new Path(xrel);
				if (xp.ext != null && xp.ext.toLowerCase() == "gml") {
					if (Path.extension(xp.file).toLowerCase() == "replace") {
						cx.call(getContent, xfull, function(s:String) {
							ctx.raw = applyPatchFile(ctx.raw, s);
						});
						continue;
					}
					cx.call(getContent, xfull, function(s:String) {
						ctx.raw += "\n" + s;
					});
				}
			}
		}
		#end
		
		// if we are running on Node, all of the preceding operations complete immediately,
		// but we didn't initialize the API (in LiveWeb) yet, so might as well just
		// delay by 1 frame instead of restructuring everything.
		#if lwedit
		if (FileSystem.canSync) cx.call(function(_, fn) {
			Main.window.setTimeout(function(_) fn(null));
		}, null, function(_) {});
		#end
		
		//
		var data = getArgs();
		
		cx.finish(function() {
			GmlParseAPI.loadStd(ctx.raw, data);
			
			// give GMLive a copy of data
			#if lwedit
			if (data.lwArg0 != null) {
				if (LiveWeb.api != null) {
					#if 0
					var arr = [];
					for (k => v in data.lwArg0) {
						arr.push(k + ":" + v + ":" + data.lwArg1[k]);
					}
					var init = '{\nlwArgs:"' + arr.join("|") + '",\n';
					//
					arr = [];
					for (k => f in data.lwFlags) arr.push(k + ":" + f);
					init += 'lwFlags:"' + arr.join("|") + '",\n';
					//
					arr = [];
					for (k => _ in data.lwConst) arr.push(k);
					init += 'lwConst:"' + arr.join("|") + '",\n';
					//
					arr = [];
					for (k => _ in data.lwInst) arr.push(k);
					init += 'lwInst:"' + arr.join("|") + '"\n';
					//
					init += "}";
					//Main.console.log(init);
					#end
					LiveWeb.api.setAPI(data);
				}
				Main.window.setTimeout(function() {
					LiveWeb.readyUp();
				});
			}
			
			// force [re-]tokenization so that the welcome page highlights correctly:
			Main.aceEditor.session.bgTokenizer.start(0);
			#end
		});
	}
}
typedef GmlAPILoadContext = {
	conf:GmlVersionConfig,
	dir:String,
	?raw:String,
}