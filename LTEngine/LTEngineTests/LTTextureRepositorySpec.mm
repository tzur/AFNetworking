// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTTextureRepository.h"

#import "LTTexture+Factory.h"

SpecBegin(LTTextureRepository)
__block LTTextureRepository *repository;
__block LTTexture *texture;

beforeEach(^{
  repository = [[LTTextureRepository alloc] init];
  texture = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 2)];
});

it(@"should return saved texture", ^{
  [repository addTexture:texture];

  expect([repository textureWithGenerationID:texture.generationID]).to.equal(texture);
});

it(@"should return texture after its generation ID has changed", ^{
  [repository addTexture:texture];
  [texture clearWithColor:LTVector4(0.1)];

  expect([repository textureWithGenerationID:texture.generationID]).to.equal(texture);
});

it(@"should weakly hold the textures", ^{
  __block NSString *generationID;
  __block __weak LTTexture *weakTexture;

  @autoreleasepool {
    LTTexture *newTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 2)];
    weakTexture = newTexture;
    [repository addTexture:newTexture];
    generationID = newTexture.generationID;
  }

  expect(weakTexture).to.beNil();
  expect([repository textureWithGenerationID:generationID]).to.beNil();
});

SpecEnd
