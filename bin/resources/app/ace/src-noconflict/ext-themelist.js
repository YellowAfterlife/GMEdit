ace.define("ace/ext/themelist",["require","exports","module","ace/lib/fixoldbrowsers"], function(require, exports, module) {
"use strict";
require("ace/lib/fixoldbrowsers");

var themeData = [
    ["Chrome"         ],
];


exports.themesByName = {};
exports.themes = themeData.map(function(data) {
    var name = data[1] || data[0].replace(/ /g, "_").toLowerCase();
    var theme = {
        caption: data[0],
        theme: "ace/theme/" + name,
        isDark: data[2] == "dark",
        name: name
    };
    exports.themesByName[name] = theme;
    return theme;
});

});
                (function() {
                    ace.require(["ace/ext/themelist"], function() {});
                })();
            
