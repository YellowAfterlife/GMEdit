package;

import haxe.Json;
import neko.Lib;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
using StringTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static var configPath:String = "config.json";
	static var electronDir:String = "../base";
	static var appDir:String = "../../bin/resources/app";
	static var verPath:String = "../../bin/builddate.txt";
	static var config:Config;
	static function flushConfig() {
		File.saveContent(configPath, Json.stringify(config, null, "\t"));
	}
	static function prompt(text:String):String {
		Sys.print(text + "?: ");
		return Sys.stdin().readLine();
	}
	static function preinit() {
		try {
			config = Json.parse(File.getContent(configPath));
			return;
		} catch (x:Dynamic) {
			//
		}
		var cfg:Config = {};
		cfg.path_7z = prompt("Path to 7z.exe");
		cfg.path_rh = prompt("Path to ResourceHacker.exe");
		config = cfg;
		flushConfig();
	}
	static function run7z(args:Array<String>) {
		var p = new Process(config.path_7z, args.concat(["-y"]) );
		var e = p.exitCode(true);
		Sys.stderr().writeInput(p.stderr);
	}
	static function pack(mode:PackMode) {
		var cwd = Sys.getCwd();
		var tempDefault = cwd + "temp/default";
		var tempDefaultApp = cwd + "temp/default/resources/app";
		var tempMac = cwd + "temp/mac";
		var tempMacApp = tempMac + "/GMEdit.app/Contents/Resources/app";
		var out = cwd + "out";
		var extras = ["-y" , "-bb0", "-bd"];
		CopySync.ensureDirectory("temp/default/resources/app");
		CopySync.ensureDirectory("temp/mac/GMEdit.app/Contents/Resources/app");
		CopySync.ensureDirectory("out");
		
		var wantUpload = mode == Beta || mode == Stable;
		var version:String = {
			var now = Date.now();
			var tzo = Math.round( -now.getTimezoneOffset() / 30) / 2;
			var verbose = false;
			if (verbose) {
				DateTools.format(now, "%b %e, %Y %H:%M") + " GMT" + (tzo > 0 ? "+" : "") + tzo;
			} else DateTools.format(now, "%b %e, %Y");
		}
		Sys.println("Version: " + version);
		
		var appPaths = FileSystem.readDirectory(appDir);
		appPaths.remove("node_modules");
		appPaths.remove("dist");
		Sys.println("Copying base app...");
		CopySync.copyDir(appDir, tempDefaultApp, appPaths);
		Sys.println("Unzipping node_modules...");
		run7z(["x",
			electronDir + "/GMEdit-AppOnly.zip",
			"node_modules",
			"-o" + tempDefault,
		]);
		
		var hasMac = false;
		var rxVer = ~/\w+-\d+\.\d+\.\d+(?:\.\d+)?-(?:(\w+)-)?(\w+)\.zip/;
		var baseDir = cwd + electronDir;
		if (wantUpload) {
			if (config.path_butler == null) {
				config.path_butler = prompt("Path to itch.io butler (https://itchio.itch.io/butler)");
				flushConfig();
			}
			if (config.itch_path == null) {
				config.itch_path = prompt("itch.io username/projectname (like `yellowafterlife/gmedit`)");
				flushConfig();
			}
		}
		for (verRel in FileSystem.readDirectory(baseDir)) {
			var verFull = baseDir + "/" + verRel;
			if (verRel.indexOf("AppOnly") >= 0) {
				Sys.println('Packing GMEdit-AppOnly.zip...');
				var appOnly = out + "/GMEdit-AppOnly.zip";
				File.copy(verFull, appOnly);
				Sys.setCwd(tempDefaultApp);
				run7z(["a", appOnly].concat(appPaths));
				if (!wantUpload) continue;
				var itchName = config.itch_path + ":Editor-";
				if (mode == Beta) itchName += "Beta-";
				itchName += "App-Only";
				Sys.println('Uploading $itchName...');
				Sys.command(config.path_butler, ["push",
					appOnly, itchName, "--userversion", version,
				]);
				continue;
			}
			if (mode == AppOnly) continue;
			if (!rxVer.match(verRel)) continue;
			var arch = rxVer.matched(1);
			var platform = rxVer.matched(2);
			var isMac = platform == "mac";
			
			if (isMac && !hasMac) {
				hasMac = true;
				Sys.println("Copying base files for Mac...");
				CopySync.copyDir(tempDefault, tempMacApp);
			}
			
			var platformCap = platform.charAt(0).toUpperCase() + platform.substr(1);
			var zipRel =  "GMEdit-" + platformCap + (arch != null ? "-" + arch.toUpperCase() : "") + ".zip";
			var zipFull = out + "/" + zipRel;
			
			Sys.println('Packing $zipRel...');
			File.copy(verFull, zipFull);
			if (isMac) {
				Sys.setCwd(tempMac);
				run7z(["a", zipFull, "GMEdit.app"]);
			} else {
				Sys.setCwd(tempDefault);
				run7z(["a", zipFull, "resources"]);
			}
			
			if (wantUpload) {
				var itchName = config.itch_path + ":Editor-";
				if (mode == Beta) itchName += "Beta-";
				itchName += switch (platform) {
					case "win": "Windows";
					default: platformCap;
				}
				if (arch != null) itchName += "-" + arch.toUpperCase();
				
				Sys.println('Uploading $itchName...');
				Sys.command(config.path_butler, ["push",
					zipFull, itchName, "--userversion", version,
				]);
			}
		}
		CopySync.copyDir(tempDefault, tempMacApp);
	}
	static function main() {
		configPath = Sys.getCwd() + configPath;
		preinit();
		Sys.println("What would you like to do?");
		Sys.println("s\tPack and upload stable");
		Sys.println("b\tPack and upload beta");
		Sys.println("p\tPack without uploading");
		Sys.println("a\tPack an app-only ZIP");
		Sys.print("> ");
		var c = String.fromCharCode(Sys.getChar(true)).toLowerCase();
		Sys.println("");
		try {
			switch (c) {
				case "s": pack(Stable);
				case "b": pack(Beta);
				case "p": pack(Pack);
				case "a": pack(AppOnly);
				default: Sys.println("Not a known option.");
			}
		} catch (x:Dynamic) {
			Sys.println("Error: " + x);
			Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		}
		Sys.println("Press any key to exit!");
		Sys.getChar(false);
	}
	
}
enum abstract PackMode(Int) {
	var AppOnly;
	var Pack;
	var Stable;
	var Beta;
}
typedef Config = {
	?path_7z:String,
	?path_rh:String,
	?path_butler:String,
	?itch_path:String,
}