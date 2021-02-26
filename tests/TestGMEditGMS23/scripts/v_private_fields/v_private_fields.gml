function v_private_fields() constructor {
    __private = 1;
    public = 2;
    self.__private = 1;
    self.public = 2;
    // type `.` to verify that __private is not in completion
}