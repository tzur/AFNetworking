// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureAtlas.h"

#import "LTTexture+Factory.h"

SpecBegin(LTTextureAtlas)

context(@"initialization", ^{
  __block LTTexture *texture;

  beforeEach(^{
    texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(2)];
  });

  afterEach(^{
    texture = nil;
  });

  it(@"should initialize with atlas texture and image areas correctly", ^{
    lt::unordered_map<NSString *, CGRect> areas{{@"1", CGRectMake(0, 0, 1, 1)},
                                                {@"2", CGRectMake(1, 1, 1, 1)}};

    LTTextureAtlas *textureAtlas =
        [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:areas];

    expect(textureAtlas.texture).to.beIdenticalTo(texture);
    expect(textureAtlas.areas == areas).to.beTruthy();
  });

  it(@"should raise when initializing with an empty areas dictionary", ^{
    expect(^{
      LTTextureAtlas __unused *textureAtlas =
          [[LTTextureAtlas alloc] initWithAtlasTexture:texture
                                            imageAreas:lt::unordered_map<NSString *, CGRect>{}];

    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when passing an image area without positive width or height", ^{
    lt::unordered_map<NSString *, CGRect> zeroWidthAreas{{@"1", CGRectMake(0, 0, 0, 1)}};

    expect(^{
      LTTextureAtlas __unused *textureAtlas =
          [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:zeroWidthAreas];
    }).to.raise(NSInvalidArgumentException);

    lt::unordered_map<NSString *, CGRect> zeroHeightAreas{{@"1", CGRectMake(0, 0, 1, 0)}};
    
    expect(^{
      LTTextureAtlas __unused *textureAtlas =
          [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:zeroHeightAreas];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when passing an image area that is outside of the atlas texture bounds", ^{
    lt::unordered_map<NSString *, CGRect> outOfBoundsWidthAreas{{@"1", CGRectMake(0, 0, 3, 1)}};

    expect(^{
      LTTextureAtlas __unused *textureAtlas =
          [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:outOfBoundsWidthAreas];
    }).to.raise(NSInvalidArgumentException);

    lt::unordered_map<NSString *, CGRect> outOfBoundsHeightAreas{{@"1", CGRectMake(0, 0, 1, 3)}};

    expect(^{
      LTTextureAtlas __unused *textureAtlas =
          [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:outOfBoundsHeightAreas];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
