function assert(_val, _want, _label) {
	//trace("assert", _val, _want, _label);
	if (_label == undefined) _label = "?";
	var _error = false;
	if (is_array(_want)) {
		if (is_array(_val)) {
			var n = array_length(_want);
			if (n != array_length(_val)) {
				_error = true;
			} else for (var i = 0; i < n; i++) {
				if (!assert(_val[i], _want[i], noone)) {
					_error = true;
					break;
				}
			}
		} else _error = true;
	}
	else if (is_struct(_want)) {
		if (is_struct(_val)) {
			var _keys = variable_struct_get_names(_want);
			var n = array_length(_keys);
			if (n != variable_struct_names_count(_val)) {
				_error = true;
			} else for (var i = 0; i < n; i++) {
				var _key = _keys[i];
				if (!assert(_want[$ _key], _val[$ _key], noone)) {
					_error = true;
					break;
				}
			}
		} else _error = true;
	}
	else if (_val != _want) {
		_error = true;
	}
	if (_error) {
		if (_label != noone) show_error(
			sfmt("Expected `%` (%), got `%` (%) for %", _want, typeof(_want), _val, typeof(_val), _label)
		, true);
		return false;
	}
	return true;
}