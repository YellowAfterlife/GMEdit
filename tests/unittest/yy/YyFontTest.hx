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

	@Test public function TestAddRange() {
		var myFont:YyFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		
		myFont.ranges = [];

		myFont.addRange({lower: 64, upper: 64});
		Assert.areEqual([{lower: 64, upper: 64}], myFont.ranges);

		myFont.addRange({lower: 32, upper: 32});
		Assert.areEqual([
			{lower: 32, upper: 32},
			{lower: 64, upper: 64}],
		myFont.ranges);

		myFont.addRange({lower: 96, upper: 96});
		Assert.areEqual([
			{lower: 32, upper: 32},
			{lower: 64, upper: 64},
			{lower: 96, upper: 96}],
		myFont.ranges);
	}

	@Test public function TestAddRangeMerge() {
		var myFont:YyFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		myFont.ranges = [];

		myFont.addRange({lower: 64, upper: 64});
		myFont.addRange({lower: 65, upper: 65});

		Assert.areEqual([{lower: 64, upper: 65}], myFont.ranges);

		myFont.addRange({lower: 63, upper: 63});
		Assert.areEqual([{lower: 63, upper: 65}], myFont.ranges);

		myFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		myFont.ranges = [];
		myFont.addRange({lower: 60, upper: 70});
		myFont.addRange({lower: 65, upper: 75});

		Assert.areEqual([{lower: 60, upper: 75}], myFont.ranges);

		myFont.addRange({lower: 55, upper: 65});
		Assert.areEqual([{lower: 55, upper: 75}], myFont.ranges);

		myFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		myFont.ranges = [];
		myFont.addRange({lower: 32, upper: 123});
		myFont.addRange({lower: 123, upper: 123});
		Assert.areEqual([{lower: 32, upper: 123}], myFont.ranges);
	}

	@Test public function TestAddRangeMultiMerge() {
		var myFont:YyFont = YyFont.generateDefault({name: "", path: ""}, "myFont");
		myFont.ranges = [];

		myFont.addRange({lower: 64, upper: 64});
		myFont.addRange({lower: 66, upper: 66});
		myFont.addRange({lower: 65, upper: 65});

		Assert.areEqual([{lower: 64, upper: 66}], myFont.ranges);


		myFont.ranges = [];
		myFont.addRange({lower: 60, upper: 65});
		myFont.addRange({lower: 70, upper: 75});
		myFont.addRange({lower: 80, upper: 85});

		myFont.addRange({lower: 50, upper: 82});
		Assert.areEqual([{lower: 50, upper: 85}], myFont.ranges);
	}
}