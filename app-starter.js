(function ($global) { "use strict";
var $estr = function() { return js_Boot.__string_rec(this,''); },$hxEnums = $hxEnums || {},$_;
function $extend(from, fields) {
	var proto = Object.create(from);
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var EReg = function(r,opt) {
	this.r = new RegExp(r,opt.split("u").join(""));
};
EReg.__name__ = true;
EReg.prototype = {
	match: function(s) {
		if(this.r.global) {
			this.r.lastIndex = 0;
		}
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
};
var HxOverrides = function() { };
HxOverrides.__name__ = true;
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) {
		return undefined;
	}
	return x;
};
HxOverrides.now = function() {
	return Date.now();
};
var Lambda = function() { };
Lambda.__name__ = true;
Lambda.exists = function(it,f) {
	var x = $getIterator(it);
	while(x.hasNext()) if(f(x.next())) {
		return true;
	}
	return false;
};
Math.__name__ = true;
var Reflect = function() { };
Reflect.__name__ = true;
Reflect.isFunction = function(f) {
	if(typeof(f) == "function") {
		return !(f.__name__ || f.__ename__);
	} else {
		return false;
	}
};
Reflect.compareMethods = function(f1,f2) {
	if(f1 == f2) {
		return true;
	}
	if(!Reflect.isFunction(f1) || !Reflect.isFunction(f2)) {
		return false;
	}
	if(f1.scope == f2.scope && f1.method == f2.method) {
		return f1.method != null;
	} else {
		return false;
	}
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
var electron_WindowsAccentColors = function() { };
electron_WindowsAccentColors.__name__ = true;
electron_WindowsAccentColors.init = function() {
	if(electron_WindowsAccentColors.ready) {
		return;
	}
	electron_WindowsAccentColors.ready = true;
	try {
		if(Electron == null) {
			return;
		}
		if(window.process.platform != "win32") {
			return;
		}
		var remote = Electron.remote;
		if(remote == null) {
			remote = window.require("@electron/remote");
		}
		var path = window.require("path");
		var appPath = remote.app.getAppPath();
		var jsPath = path.resolve(appPath,"./misc/WindowsAccentColors.js");
		electron_WindowsAccentColors.impl = window.require(jsPath);
	} catch( _g ) {
		var x = haxe_Exception.caught(_g).unwrap();
		console.error("Error initializing accent colors: ",x);
	}
};
electron_WindowsAccentColors.updateFocus = function(active) {
	electron_WindowsAccentColors.init();
	if(electron_WindowsAccentColors.impl == null) {
		return;
	}
	var html = window.document.documentElement;
	var style = html.style;
	var pre = active ? "active" : "inactive";
	html.setAttribute("titlebar-foreground-is-light",html.getAttribute(pre + "-titlebar-foreground-is-light"));
	style.setProperty("--titlebar-background-color",style.getPropertyValue("--" + pre + "-titlebar-background-color"));
	style.setProperty("--titlebar-foreground-color",style.getPropertyValue("--" + pre + "-titlebar-foreground-color"));
};
electron_WindowsAccentColors.update = function(focus) {
	if(electron_WindowsAccentColors.impl == null) {
		electron_WindowsAccentColors.init();
	} else {
		electron_WindowsAccentColors.impl.reload();
	}
	if(electron_WindowsAccentColors.impl == null) {
		return;
	}
	if(!electron_WindowsAccentColors.impl.isDetectable) {
		return;
	}
	var fc0 = electron_WindowsAccentColors.impl.inactiveTitlebarTextColor;
	var fc1 = electron_WindowsAccentColors.impl.titlebarTextColor;
	var html = window.document.documentElement;
	html.setAttribute("hasAccentColors","");
	html.setAttribute("active-titlebar-foreground-is-light","" + Std.string(fc1 == "#ffffff"));
	html.setAttribute("inactive-titlebar-foreground-is-light","" + Std.string(fc0 == "#ffffff"));
	var style = html.style;
	style.setProperty("--active-titlebar-background-color",electron_WindowsAccentColors.impl.titlebarColor);
	style.setProperty("--active-titlebar-foreground-color",fc1);
	style.setProperty("--inactive-titlebar-background-color",electron_WindowsAccentColors.impl.inactiveTitlebarColor);
	style.setProperty("--inactive-titlebar-foreground-color",fc0);
	if(focus == null) {
		focus = window.document.documentElement.hasAttribute("hasFocus");
	}
	electron_WindowsAccentColors.updateFocus(focus);
};
var haxe_Exception = function(message,previous,native) {
	Error.call(this,message);
	this.message = message;
	this.__previousException = previous;
	this.__nativeException = native != null ? native : this;
};
haxe_Exception.__name__ = true;
haxe_Exception.caught = function(value) {
	if(((value) instanceof haxe_Exception)) {
		return value;
	} else if(((value) instanceof Error)) {
		return new haxe_Exception(value.message,null,value);
	} else {
		return new haxe_ValueException(value,null,value);
	}
};
haxe_Exception.thrown = function(value) {
	if(((value) instanceof haxe_Exception)) {
		return value.get_native();
	} else if(((value) instanceof Error)) {
		return value;
	} else {
		var e = new haxe_ValueException(value);
		return e;
	}
};
haxe_Exception.__super__ = Error;
haxe_Exception.prototype = $extend(Error.prototype,{
	unwrap: function() {
		return this.__nativeException;
	}
	,get_native: function() {
		return this.__nativeException;
	}
});
var haxe_ValueException = function(value,previous,native) {
	haxe_Exception.call(this,String(value),previous,native);
	this.value = value;
};
haxe_ValueException.__name__ = true;
haxe_ValueException.__super__ = haxe_Exception;
haxe_ValueException.prototype = $extend(haxe_Exception.prototype,{
	unwrap: function() {
		return this.value;
	}
});
var haxe_http_HttpBase = function(url) {
	this.url = url;
	this.headers = [];
	this.params = [];
	this.emptyOnData = $bind(this,this.onData);
};
haxe_http_HttpBase.__name__ = true;
haxe_http_HttpBase.prototype = {
	onData: function(data) {
	}
	,onBytes: function(data) {
	}
	,onError: function(msg) {
	}
	,onStatus: function(status) {
	}
	,hasOnData: function() {
		return !Reflect.compareMethods($bind(this,this.onData),this.emptyOnData);
	}
	,success: function(data) {
		this.responseBytes = data;
		this.responseAsString = null;
		if(this.hasOnData()) {
			this.onData(this.get_responseData());
		}
		this.onBytes(this.responseBytes);
	}
	,get_responseData: function() {
		if(this.responseAsString == null && this.responseBytes != null) {
			this.responseAsString = this.responseBytes.getString(0,this.responseBytes.length,haxe_io_Encoding.UTF8);
		}
		return this.responseAsString;
	}
};
var haxe_http_HttpJs = function(url) {
	this.async = true;
	this.withCredentials = false;
	haxe_http_HttpBase.call(this,url);
};
haxe_http_HttpJs.__name__ = true;
haxe_http_HttpJs.__super__ = haxe_http_HttpBase;
haxe_http_HttpJs.prototype = $extend(haxe_http_HttpBase.prototype,{
	request: function(post) {
		var _gthis = this;
		this.responseAsString = null;
		this.responseBytes = null;
		var r = this.req = js_Browser.createXMLHttpRequest();
		var onreadystatechange = function(_) {
			if(r.readyState != 4) {
				return;
			}
			var s;
			try {
				s = r.status;
			} catch( _g ) {
				s = null;
			}
			if(s == 0 && js_Browser.get_supported() && $global.location != null) {
				var protocol = $global.location.protocol.toLowerCase();
				if(new EReg("^(?:about|app|app-storage|.+-extension|file|res|widget):$","").match(protocol)) {
					s = r.response != null ? 200 : 404;
				}
			}
			if(s == undefined) {
				s = null;
			}
			if(s != null) {
				_gthis.onStatus(s);
			}
			if(s != null && s >= 200 && s < 400) {
				_gthis.req = null;
				_gthis.success(haxe_io_Bytes.ofData(r.response));
			} else if(s == null || s == 0 && r.response == null) {
				_gthis.req = null;
				_gthis.onError("Failed to connect or resolve host");
			} else if(s == null) {
				_gthis.req = null;
				var onreadystatechange = r.response != null ? haxe_io_Bytes.ofData(r.response) : null;
				_gthis.responseBytes = onreadystatechange;
				_gthis.onError("Http Error #" + r.status);
			} else {
				switch(s) {
				case 12007:
					_gthis.req = null;
					_gthis.onError("Unknown host");
					break;
				case 12029:
					_gthis.req = null;
					_gthis.onError("Failed to connect to host");
					break;
				default:
					_gthis.req = null;
					var onreadystatechange = r.response != null ? haxe_io_Bytes.ofData(r.response) : null;
					_gthis.responseBytes = onreadystatechange;
					_gthis.onError("Http Error #" + r.status);
				}
			}
		};
		if(this.async) {
			r.onreadystatechange = onreadystatechange;
		}
		var _g = this.postData;
		var _g1 = this.postBytes;
		var uri = _g == null ? _g1 == null ? null : new Blob([_g1.b.bufferValue]) : _g1 == null ? _g : null;
		if(uri != null) {
			post = true;
		} else {
			var _g = 0;
			var _g1 = this.params;
			while(_g < _g1.length) {
				var p = _g1[_g];
				++_g;
				if(uri == null) {
					uri = "";
				} else {
					uri = (uri == null ? "null" : Std.string(uri)) + "&";
				}
				var s = p.name;
				var value = (uri == null ? "null" : Std.string(uri)) + encodeURIComponent(s) + "=";
				var s1 = p.value;
				uri = value + encodeURIComponent(s1);
			}
		}
		try {
			if(post) {
				r.open("POST",this.url,this.async);
			} else if(uri != null) {
				r.open("GET",this.url + (this.url.split("?").length <= 1 ? "?" : "&") + (uri == null ? "null" : Std.string(uri)),this.async);
				uri = null;
			} else {
				r.open("GET",this.url,this.async);
			}
			r.responseType = "arraybuffer";
		} catch( _g ) {
			var _g1 = haxe_Exception.caught(_g).unwrap();
			this.req = null;
			this.onError(_g1.toString());
			return;
		}
		r.withCredentials = this.withCredentials;
		if(!Lambda.exists(this.headers,function(h) {
			return h.name == "Content-Type";
		}) && post && this.postData == null) {
			r.setRequestHeader("Content-Type","application/x-www-form-urlencoded");
		}
		var _g = 0;
		var _g1 = this.headers;
		while(_g < _g1.length) {
			var h = _g1[_g];
			++_g;
			r.setRequestHeader(h.name,h.value);
		}
		r.send(uri);
		if(!this.async) {
			onreadystatechange(null);
		}
	}
});
var haxe_io_Bytes = function(data) {
	this.length = data.byteLength;
	this.b = new Uint8Array(data);
	this.b.bufferValue = data;
	data.hxBytes = this;
	data.bytes = this.b;
};
haxe_io_Bytes.__name__ = true;
haxe_io_Bytes.ofData = function(b) {
	var hb = b.hxBytes;
	if(hb != null) {
		return hb;
	}
	return new haxe_io_Bytes(b);
};
haxe_io_Bytes.prototype = {
	getString: function(pos,len,encoding) {
		if(pos < 0 || len < 0 || pos + len > this.length) {
			throw haxe_Exception.thrown(haxe_io_Error.OutsideBounds);
		}
		if(encoding == null) {
			encoding = haxe_io_Encoding.UTF8;
		}
		var s = "";
		var b = this.b;
		var i = pos;
		var max = pos + len;
		switch(encoding._hx_index) {
		case 0:
			while(i < max) {
				var c = b[i++];
				if(c < 128) {
					if(c == 0) {
						break;
					}
					s += String.fromCodePoint(c);
				} else if(c < 224) {
					var code = (c & 63) << 6 | b[i++] & 127;
					s += String.fromCodePoint(code);
				} else if(c < 240) {
					var code1 = (c & 31) << 12 | (b[i++] & 127) << 6 | b[i++] & 127;
					s += String.fromCodePoint(code1);
				} else {
					var u = (c & 15) << 18 | (b[i++] & 127) << 12 | (b[i++] & 127) << 6 | b[i++] & 127;
					s += String.fromCodePoint(u);
				}
			}
			break;
		case 1:
			while(i < max) {
				var c = b[i++] | b[i++] << 8;
				s += String.fromCodePoint(c);
			}
			break;
		}
		return s;
	}
};
var haxe_io_Encoding = $hxEnums["haxe.io.Encoding"] = { __ename__:true,__constructs__:null
	,UTF8: {_hx_name:"UTF8",_hx_index:0,__enum__:"haxe.io.Encoding",toString:$estr}
	,RawNative: {_hx_name:"RawNative",_hx_index:1,__enum__:"haxe.io.Encoding",toString:$estr}
};
haxe_io_Encoding.__constructs__ = [haxe_io_Encoding.UTF8,haxe_io_Encoding.RawNative];
var haxe_io_Error = $hxEnums["haxe.io.Error"] = { __ename__:true,__constructs__:null
	,Blocked: {_hx_name:"Blocked",_hx_index:0,__enum__:"haxe.io.Error",toString:$estr}
	,Overflow: {_hx_name:"Overflow",_hx_index:1,__enum__:"haxe.io.Error",toString:$estr}
	,OutsideBounds: {_hx_name:"OutsideBounds",_hx_index:2,__enum__:"haxe.io.Error",toString:$estr}
	,Custom: ($_=function(e) { return {_hx_index:3,e:e,__enum__:"haxe.io.Error",toString:$estr}; },$_._hx_name="Custom",$_.__params__ = ["e"],$_)
};
haxe_io_Error.__constructs__ = [haxe_io_Error.Blocked,haxe_io_Error.Overflow,haxe_io_Error.OutsideBounds,haxe_io_Error.Custom];
var haxe_io_Path = function() { };
haxe_io_Path.__name__ = true;
haxe_io_Path.join = function(paths) {
	var _g = [];
	var _g1 = 0;
	while(_g1 < paths.length) {
		var v = paths[_g1];
		++_g1;
		if(v != null && v != "") {
			_g.push(v);
		}
	}
	if(_g.length == 0) {
		return "";
	}
	var path = _g[0];
	var _g1 = 1;
	var _g2 = _g.length;
	while(_g1 < _g2) {
		path = haxe_io_Path.addTrailingSlash(path);
		path += _g[_g1++];
	}
	return haxe_io_Path.normalize(path);
};
haxe_io_Path.normalize = function(path) {
	var slash = "/";
	path = path.split("\\").join(slash);
	if(path == slash) {
		return slash;
	}
	var target = [];
	var _g = 0;
	var _g1 = path.split(slash);
	while(_g < _g1.length) {
		var token = _g1[_g];
		++_g;
		if(token == ".." && target.length > 0 && target[target.length - 1] != "..") {
			target.pop();
		} else if(token == "") {
			if(target.length > 0 || HxOverrides.cca(path,0) == 47) {
				target.push(token);
			}
		} else if(token != ".") {
			target.push(token);
		}
	}
	var acc_b = "";
	var colon = false;
	var slashes = false;
	var _g2_offset = 0;
	var _g2_s = target.join(slash);
	while(_g2_offset < _g2_s.length) {
		var s = _g2_s;
		var index = _g2_offset++;
		var c = s.charCodeAt(index);
		if(c >= 55296 && c <= 56319) {
			c = c - 55232 << 10 | s.charCodeAt(index + 1) & 1023;
		}
		var c1 = c;
		if(c1 >= 65536) {
			++_g2_offset;
		}
		var c2 = c1;
		switch(c2) {
		case 47:
			if(!colon) {
				slashes = true;
			} else {
				var i = c2;
				colon = false;
				if(slashes) {
					acc_b += "/";
					slashes = false;
				}
				acc_b += String.fromCodePoint(i);
			}
			break;
		case 58:
			acc_b += ":";
			colon = true;
			break;
		default:
			var i1 = c2;
			colon = false;
			if(slashes) {
				acc_b += "/";
				slashes = false;
			}
			acc_b += String.fromCodePoint(i1);
		}
	}
	return acc_b;
};
haxe_io_Path.addTrailingSlash = function(path) {
	if(path.length == 0) {
		return "/";
	}
	var c1 = path.lastIndexOf("/");
	var c2 = path.lastIndexOf("\\");
	if(c1 < c2) {
		if(c2 != path.length - 1) {
			return path + "\\";
		} else {
			return path;
		}
	} else if(c1 != path.length - 1) {
		return path + "/";
	} else {
		return path;
	}
};
var haxe_iterators_ArrayIterator = function(array) {
	this.current = 0;
	this.array = array;
};
haxe_iterators_ArrayIterator.__name__ = true;
haxe_iterators_ArrayIterator.prototype = {
	hasNext: function() {
		return this.current < this.array.length;
	}
	,next: function() {
		return this.array[this.current++];
	}
};
var js_Boot = function() { };
js_Boot.__name__ = true;
js_Boot.__string_rec = function(o,s) {
	if(o == null) {
		return "null";
	}
	if(s.length >= 5) {
		return "<...>";
	}
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) {
		t = "object";
	}
	switch(t) {
	case "function":
		return "<function>";
	case "object":
		if(o.__enum__) {
			var e = $hxEnums[o.__enum__];
			var con = e.__constructs__[o._hx_index];
			var n = con._hx_name;
			if(con.__params__) {
				s = s + "\t";
				return n + "(" + ((function($this) {
					var $r;
					var _g = [];
					{
						var _g1 = 0;
						var _g2 = con.__params__;
						while(true) {
							if(!(_g1 < _g2.length)) {
								break;
							}
							var p = _g2[_g1];
							_g1 = _g1 + 1;
							_g.push(js_Boot.__string_rec(o[p],s));
						}
					}
					$r = _g;
					return $r;
				}(this))).join(",") + ")";
			} else {
				return n;
			}
		}
		if(((o) instanceof Array)) {
			var str = "[";
			s += "\t";
			var _g = 0;
			var _g1 = o.length;
			while(_g < _g1) {
				var i = _g++;
				str += (i > 0 ? "," : "") + js_Boot.__string_rec(o[i],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( _g ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") {
				return s2;
			}
		}
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		var k = null;
		for( k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) {
			str += ", \n";
		}
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "string":
		return o;
	default:
		return String(o);
	}
};
var js_Browser = function() { };
js_Browser.__name__ = true;
js_Browser.get_supported = function() {
	if(typeof(window) != "undefined" && typeof(window.location) != "undefined") {
		return typeof(window.location.protocol) == "string";
	} else {
		return false;
	}
};
js_Browser.createXMLHttpRequest = function() {
	if(typeof XMLHttpRequest != "undefined") {
		return new XMLHttpRequest();
	}
	if(typeof ActiveXObject != "undefined") {
		return new ActiveXObject("Microsoft.XMLHTTP");
	}
	throw haxe_Exception.thrown("Unable to create XMLHttpRequest object.");
};
var tools_ChainCall = function() {
	this.isRunning = false;
	this.queue = [];
};
tools_ChainCall.__name__ = true;
tools_ChainCall.prototype = {
	next: function() {
		var item = this.queue.shift();
		if(item != null) {
			this.isRunning = true;
			item.fn.apply(null,item.args);
		} else {
			this.isRunning = false;
		}
	}
	,call: function(fn,a,cb) {
		var _gthis = this;
		var q = { fn : fn, args : [a,function(val) {
			cb(val);
			_gthis.next();
		}]};
		this.queue.push(q);
		if(!this.isRunning) {
			this.next();
		}
		return this;
	}
};
var ui_Preferences = function() { };
ui_Preferences.__name__ = true;
var ui_Starter = function() { };
ui_Starter.__name__ = true;
ui_Starter.initAPI = function() {
	ui_Starter.modulePath = window.__dirname;
	if(ui_Starter.modulePath == null) {
		ui_Starter.modulePath = ".";
	}
	var hasRequire = window.require != null;
	var dynWindow = window;
	dynWindow.__themeData = { };
	dynWindow.Electron_FS = hasRequire ? require("fs") : ui_FileSystemBrowser;
	var electron = hasRequire ? require("electron") : null;
	if(electron != null) {
		var remote = electron.remote;
		var ver = window.parseInt(window.process.versions.electron);
		if(ver >= 14) {
			remote = require("@electron/remote");
			electron.remote = remote;
		}
		ui_Starter.userPath = remote.app.getPath("userData") + "/GMEdit";
	}
	dynWindow.Electron = electron;
};
ui_Starter.initAce = function() {
	var text = null;
	if(Electron_FS.existsSync != null) {
		var full = ui_Starter.userPath + "/config/" + "aceOptions" + ".json";
		if(Electron_FS.existsSync(full)) {
			try {
				text = Electron_FS.readFileSync(full,"utf8");
			} catch( _g ) {
			}
		}
	} else {
		text = window.localStorage.getItem("aceOptions");
	}
	if(text == null) {
		return;
	}
	var aceData;
	try {
		aceData = JSON.parse(text);
	} catch( _g ) {
		return;
	}
	var log = window.document.getElementById("source");
	var ff = aceData.fontFamily;
	if(ff != null) {
		log.style.fontFamily = ff;
	}
	var fs = aceData.fontSize;
	if(fs != null) {
		log.style.fontSize = fs + "px";
	}
};
ui_Starter.initPreferences = function() {
	var prefText = null;
	if(Electron_FS.existsSync != null) {
		var full = ui_Starter.userPath + "/config/" + "user-preferences" + ".json";
		if(Electron_FS.existsSync(full)) {
			try {
				prefText = Electron_FS.readFileSync(full,"utf8");
			} catch( _g ) {
			}
		}
	} else {
		prefText = window.localStorage.getItem("config/" + "user-preferences");
	}
	var pref = null;
	if(prefText != null) {
		try {
			pref = JSON.parse(prefText);
		} catch( _g ) {
		}
	}
	if(pref != null && pref.theme != null) {
		ui_Theme.set(pref.theme,ui_Starter.ready);
	} else {
		ui_Starter.ready();
	}
};
ui_Starter.ready = function() {
	var files = window.__starterFiles;
	window.__starterFiles = null;
	var log = window.document.querySelector("#source");
	var addScript = function(path,fn) {
		console.log("Loading " + path + "...");
		log.value += "Loading " + path + "... ";
		var then = function(status) {
			log.value += status + "!\n";
			window.setTimeout(function() {
				fn(null);
			},1);
		};
		window.setTimeout(function() {
			var scr = window.document.createElement("script");
			scr.type = "text/javascript";
			scr.charset = "utf-8";
			scr.async = true;
			scr.addEventListener("load",function(_) {
				then("OK");
			});
			scr.addEventListener("error",function(e) {
				console.error(e);
				then("error");
			});
			scr.src = path;
			window.document.body.appendChild(scr);
		},1);
	};
	var cc = new tools_ChainCall();
	var _g = 0;
	while(_g < files.length) cc.call(addScript,files[_g++],function(_) {
	});
	window.document.documentElement.classList.add("starter-loading");
	cc.call(function(_,_1) {
		window.document.documentElement.classList.remove("starter-loading");
		console.log("ready!");
	},null,function(_) {
	});
};
ui_Starter.main = function() {
	window.__hasStarter = true;
	try {
		ui_Starter.initAPI();
		ui_Starter.initAce();
		ui_Starter.initPreferences();
	} catch( _g ) {
		console.error(haxe_Exception.caught(_g).unwrap());
		if(Electron != null) {
			try {
				var w = Electron.remote.getCurrentWindow();
				if(!w.isDevToolsOpened()) {
					w.openDevTools();
				}
			} catch( _g1 ) {
			}
		}
		ui_Starter.ready();
	}
};
var ui_FileSystemBrowser = function() { };
ui_FileSystemBrowser.__name__ = true;
ui_FileSystemBrowser.readFile = function(path,enc,callback) {
	var http = new haxe_http_HttpJs(path);
	http.onError = function(msg) {
		callback(new Error(msg),null);
	};
	http.onData = function(data) {
		callback(null,data);
	};
	http.request();
};
var ui_Theme = function() { };
ui_Theme.__name__ = true;
ui_Theme.setBackgroundColor = function(hexColor) {
	var $require = window.require;
	if($require != null) {
		try {
			var electron = $require("electron");
			electron.remote.getCurrentWindow().setBackgroundColor(hexColor);
		} catch( _g ) {
			var x = haxe_Exception.caught(_g).unwrap();
			console.error(x);
		}
	}
};
ui_Theme.reset = function() {
	var _g = 0;
	var _g1 = ui_Theme.elements;
	while(_g < _g1.length) {
		var el = _g1[_g];
		++_g;
		var par = el.parentElement;
		if(par != null) {
			par.removeChild(el);
		}
	}
	ui_Theme.setDarkTabs(false);
	ui_Theme.setBackgroundColor("#ffffff");
	document.documentElement.removeAttribute("data-theme-uses-bracket-depth");
};
ui_Theme.setDarkTabs = function(z) {
	var _g = [];
	var _g1 = 0;
	var _g2 = document.querySelectorAll(".chrome-tabs");
	while(_g1 < _g2.length) _g.push(_g2[_g1++]);
	_g.push(document.querySelector("#main"));
	var _g1 = 0;
	while(_g1 < _g.length) {
		var el = _g[_g1];
		++_g1;
		if(z) {
			el.classList.add("chrome-tabs-dark-theme");
		} else {
			el.classList.remove("chrome-tabs-dark-theme");
		}
	}
};
ui_Theme.add = function(name,then) {
	var userPath = ui_Starter.userPath;
	var dir = haxe_io_Path.join([ui_Starter.modulePath,"themes",name]);
	var fullConf = haxe_io_Path.join([dir,"config.json"]);
	var procSelf = function(theme) {
		if(theme.darkChromeTabs != null) {
			ui_Theme.setDarkTabs(theme.darkChromeTabs);
		}
		if(theme.windowsAccentColors) {
			electron_WindowsAccentColors.update(true);
		}
		if(theme.backgroundColor != null) {
			ui_Theme.setBackgroundColor(theme.backgroundColor);
		}
		if(theme.useBracketDepth != null) {
			if(theme.useBracketDepth) {
				document.documentElement.setAttribute("data-theme-uses-bracket-depth","");
			} else {
				document.documentElement.removeAttribute("data-theme-uses-bracket-depth");
			}
		}
		if(theme.stylesheets != null) {
			var _g = 0;
			var _g1 = theme.stylesheets;
			while(_g < _g1.length) {
				var rel = _g1[_g++];
				var link = document.createElement("link");
				link.rel = "stylesheet";
				link.href = haxe_io_Path.join([dir,rel]);
				link.setAttribute("data-is-theme","");
				document.head.insertBefore(link,ui_Theme.refElement);
				ui_Theme.elements.push(link);
			}
		}
		then();
	};
	var proc = function(theme) {
		if(theme.parentTheme != null) {
			ui_Theme.add(theme.parentTheme,function() {
				procSelf(theme);
			});
		} else {
			procSelf(theme);
		}
	};
	if(Electron_FS.existsSync != null) {
		try {
			if(Electron_FS.existsSync(fullConf)) {
				proc(JSON.parse(Electron_FS.readFileSync(fullConf,"utf8")));
			} else {
				dir = userPath + "/themes/" + name;
				fullConf = dir + "/config.json";
				if(Electron_FS.existsSync(fullConf)) {
					proc(JSON.parse(Electron_FS.readFileSync(fullConf,"utf8")));
				} else {
					then();
				}
			}
		} catch( _g ) {
			console.log(haxe_Exception.caught(_g).unwrap());
			then();
		}
	} else {
		var callback = function(err,data) {
			if(data != null) {
				proc(data);
			}
		};
		Electron_FS.readFile(fullConf,"utf8",function(e,d) {
			if(d != null) {
				try {
					d = JSON.parse(d);
				} catch( _g ) {
					d = null;
					e = haxe_Exception.caught(_g).unwrap();
				}
			}
			callback(e,d);
		});
	}
};
ui_Theme.set = function(name,cb) {
	if(cb == null) {
		cb = function() {
		};
	}
	document.documentElement.setAttribute("data-theme",name);
	ui_Theme.reset();
	ui_Theme.add(name,cb);
	return name;
};
function $getIterator(o) { if( o instanceof Array ) return new haxe_iterators_ArrayIterator(o); else return o.iterator(); }
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $global.$haxeUID++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = m.bind(o); o.hx__closures__[m.__id__] = f; } return f; }
$global.$haxeUID |= 0;
if(typeof(performance) != "undefined" ? typeof(performance.now) == "function" : false) {
	HxOverrides.now = performance.now.bind(performance);
}
if( String.fromCodePoint == null ) String.fromCodePoint = function(c) { return c < 0x10000 ? String.fromCharCode(c) : String.fromCharCode((c>>10)+0xD7C0)+String.fromCharCode((c&0x3FF)+0xDC00); }
String.__name__ = true;
Array.__name__ = true;
js_Boot.__toStr = ({ }).toString;
electron_WindowsAccentColors.ready = false;
ui_Preferences.path = "user-preferences";
ui_Theme.refElement = document.getElementById("project-style");
ui_Theme.elements = (function($this) {
	var $r;
	var qry = document.querySelectorAll("link[data-is-theme]");
	var arr = [];
	{
		var _g = 0;
		while(_g < qry.length) arr.push(qry[_g++]);
	}
	$r = arr;
	return $r;
}(this));
ui_Starter.main();
})(typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);
