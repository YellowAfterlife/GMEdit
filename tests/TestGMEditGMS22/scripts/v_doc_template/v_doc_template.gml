var s/*:string*/ = select(1, "hi", "hello");
var i/*:int*/ = select(1, "hi", "hello"); // want warn
select(1, "hi", 0); // want warn