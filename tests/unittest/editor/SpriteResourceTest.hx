package editor;

import yy.YySprite.SpriteOriginType;
import yy.YySprite.YySprite23;
import editors.sprite.SpriteResource;
import massive.munit.Assert;

class SpriteResourceTest {

	@Test public function TestOriginEvents() {
		
		var spriteResource = new SpriteResource(YySprite23.generateDefault({path: "", name: "test"}, "testSprite"));
		spriteResource.setOriginType(SpriteOriginType.Custom);
		spriteResource.width = 100;
		spriteResource.height = 100;
		spriteResource.originX = 123;
		spriteResource.originY = 123;

		var originXSet = false;
		spriteResource.onOriginXChanged.add(x -> {
			if (originXSet) Assert.fail("originXSet already set");
			originXSet = true;
		});
		var originYSet = false;
		spriteResource.onOriginYChanged.add(y -> {
			if (originYSet) Assert.fail("originYSet already set");
			originYSet = true;
		});

		spriteResource.setOriginType(SpriteOriginType.Custom);
		spriteResource.originX = 123;
		spriteResource.originY = 123;

		if (originXSet || originYSet) {
			Assert.fail("Events were called with no change");
		}

		spriteResource.originX = 120;
		if (originXSet == false) {
			Assert.fail("originX event was not called");
		}
		if (originYSet) {
			Assert.fail("originY was called even though only x changed");
		}

		originXSet = false;
		spriteResource.setOriginType(SpriteOriginType.BottomRight);
		if (originXSet == false || originYSet == false) {
			Assert.fail("Event were not called");
		}

		Assert.areEqual( spriteResource.originX, spriteResource.width );
		Assert.areEqual( spriteResource.originY, spriteResource.height );

		originXSet = false;
		originYSet = false;
		spriteResource.setOriginType(SpriteOriginType.BottomRight);
		if (originXSet || originYSet) {
			Assert.fail("Event were called even though nothing changed");
		}
	}

}