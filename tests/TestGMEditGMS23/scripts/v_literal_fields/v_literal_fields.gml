// Context: fields in object literals are hacky
function v_literal_fields() constructor {
    one = 1;
    obj = {
        one: 1,
        two: 2 ///note: should not highlight as a missing field
    }
    switch (0) {
        case two: ///want_warn should highlight as a missing field
    }
    one = 0 ? two : 1; ///want_warn should highlight as a missing field
    one = 0 ?
        two : 1; ///note: will not highlight as a missing field, but linter will catch it anyway
}