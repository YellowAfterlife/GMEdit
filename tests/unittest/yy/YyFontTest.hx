package yy;

import massive.munit.Assert;

class YyFontTest {

	@Test public function TestaddCharacters() {
		var myFont:YyFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		
		myFont.ranges = [];
		myFont.addCharacters("abc");

		Assert.areEqual([{lower: 'a'.code, upper: 'c'.code}], myFont.ranges);

		myFont.addCharacters("bef");

		Assert.areEqual([
			{lower: 'a'.code, upper: 'c'.code},
			{lower: 'e'.code, upper: 'f'.code}
		], myFont.ranges);

		myFont.addCharacters("Az");
		Assert.areEqual([
			{lower: 'A'.code, upper: 'A'.code},
			{lower: 'a'.code, upper: 'c'.code},
			{lower: 'e'.code, upper: 'f'.code},
			{lower: 'z'.code, upper: 'z'.code}
		], myFont.ranges);
	}

	@Test public function TestJoinLetters() {
		var myFont:YyFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		
		myFont.ranges = [];
		myFont.addCharacters("abde");

		Assert.areEqual([
			{lower: 'a'.code, upper: 'b'.code},
			{lower: 'd'.code, upper: 'e'.code}
		], myFont.ranges);

		myFont.addCharacters("c");

		Assert.areEqual([{lower: 'a'.code, upper: 'e'.code}], myFont.ranges);


		myFont.ranges = [];
		myFont.addCharacters("abde");
		myFont.addCharacters("cf");
		Assert.areEqual([{lower: 'a'.code, upper:'f'.code}], myFont.ranges);

		myFont.ranges = [];
		myFont.addCharacters("abde");
		myFont.addCharacters("cfz");
		Assert.areEqual([
			{lower: 'a'.code, upper:'f'.code},
			{lower: 'z'.code, upper:'z'.code}
		], myFont.ranges);
	}
}