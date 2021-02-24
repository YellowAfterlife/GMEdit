package tools;

import haxe.macro.Context;
import haxe.macro.Expr;

class EventBuildingMacro {
	/** 
		Creates a getter, setter and changed event for any fields annotated with :observable(sourceValue)  
		where sourceValue is the underlying value you want to return. Example:

		@:observable(mySource, ?extraOnChangeCode)
		myVar: Int

		Will change the myVar field into a property and create an accompanying onMyVarChanged event that gets fired whenever myVar
		is set and it's value changes.
	*/
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        for (field in fields.copy()) {
            var observeableTag = field.meta.filter((m) -> m.name == ":observable")[0];
			if (observeableTag == null) continue;

			var sourceData = observeableTag.params[0];
            var onChangedExtraCode = observeableTag.params[1];
            if (onChangedExtraCode == null) {
                onChangedExtraCode = macro {};
            }
            var fieldName = field.name;
            var fieldType;
            switch (field.kind) {
                case FVar(t, e): fieldType = t;
                default: continue;
            }
		    var upperCase = fieldName.charAt(0).toUpperCase() + fieldName.substr(1);
			var eventName = 'on${upperCase}Changed';
            var docs:String = field.doc;
            var getter = "get_" + fieldName;
            var setter = "set_" + fieldName;
            var macroTempClass = macro class Wow {
                public var $eventName:EventHandler<$fieldType> = new EventHandler();
                public var $fieldName(get, set):$fieldType;
                private function $getter():$fieldType {
                    return $sourceData;
                }
                private function $setter(value:$fieldType):$fieldType {
					if (value == $sourceData) return value;
                    $sourceData = value;
                    $onChangedExtraCode;
					$i{eventName}.invoke(value);
                    return value;
                }
            };
            fields.remove(field);

            for (tempField in macroTempClass.fields) {
                if (tempField.name == fieldName) {
                    tempField.doc = docs;
                } else if (tempField.name == eventName) {
                    tempField.doc = 'Raised whenever $fieldName is modified';
                }

                fields.push(tempField);
            }
        }

        return fields;
    }
}