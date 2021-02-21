package tools;

import haxe.macro.Context;
import haxe.macro.Expr;

class EventBuildingMacro {
	/** 
		Creates a getter, setter and changed event for any fields annotated with :observable(sourceValue)  
		where sourceValue is the underlying value you want to return. Example:

		@:observable(mySource)
		myVar: Int

		Will change the myVar field into a property and create an accompanying onMyVarChanged event that gets fired whenever myVar
		is set and it's value changes.
	*/
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        for (fd in fields.copy()) {
            var observeableTag = fd.meta.filter((m) -> m.name == ":observable")[0];
			if (observeableTag == null) continue;

			var sourceData = observeableTag.params[0];

            var fdName = fd.name;
            var fdType;
            switch (fd.kind) {
                case FVar(t, e): fdType = t;
                default: continue;
            }
		    var upperCase = fdName.charAt(0).toUpperCase() + fdName.substr(1);
			var eventName = 'on${upperCase}Changed';
            var getter = "get_" + fdName;
            var setter = "set_" + fdName;
            var mc = macro class Wow {
                public var $eventName:Dynamic;
                public var $fdName(get, set):$fdType;
                public function $getter():$fdType {
                    return $sourceData;
                }
                public function $setter(value:$fdType):$fdType {
					if (value == $sourceData) return value;
                    $sourceData = value;
					$i{eventName}.invoke(value);
                    return value;
                }
            };
            fields.remove(fd);
            for (mcf in mc.fields) fields.push(mcf);
        }

        return fields;
    }
}