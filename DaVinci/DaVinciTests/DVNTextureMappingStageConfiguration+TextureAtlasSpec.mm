// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration+TextureAtlas.h"

#import <LTEngine/LTQuad.h>
#import <LTEngine/LTTexture+Factory.h>
#import <LTEngine/LTTextureAtlas.h>

#import "DVNRandomTexCoordProvider.h"
#import "DVNTexCoordProvider.h"

SpecBegin(DVNTextureMappingStageConfiguration_TextureAtlas)

it(@"should create a configuration from a given texture atlas", ^{
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 2)];
  CGRect rect0 = CGRectFromSize(CGSizeMakeUniform(0.5));
  CGRect rect1 = CGRectFromOriginAndSize(CGPointMake(0.5, 0.5), CGSizeMake(0.5, 1.5));
  lt::unordered_map<NSString *, CGRect> areas{{@"0", rect0}, {@"1", rect1}};
  LTTextureAtlas *atlas =
      [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:areas];

  DVNTextureMappingStageConfiguration *configuration =
      [DVNTextureMappingStageConfiguration configurationFromTextureAtlas:atlas];

  expect(configuration.texture).to.beIdenticalTo(atlas.texture);
  DVNRandomTexCoordProviderModel *model = configuration.model;
  expect(model).to.beKindOf([DVNRandomTexCoordProviderModel class]);
  expect(model.textureMapQuads.size()).to.equal(2);
  NSSet<LTQuad *> *quads =
      [NSSet setWithArray:@[[[LTQuad alloc] initWithCorners:model.textureMapQuads[0].corners()],
                            [[LTQuad alloc] initWithCorners:model.textureMapQuads[1].corners()]]];
  NSSet<LTQuad *> *expectedQuads = [NSSet setWithArray:@[
    [LTQuad quadFromRectWithOrigin:CGPointMake(0, 0) andSize:CGSizeMake(0.5, 0.25)],
    [LTQuad quadFromRectWithOrigin:CGPointMake(0.5, 0.25) andSize:CGSizeMake(0.5, 0.75)]
  ]];
  expect(quads).to.equal(expectedQuads);
});

SpecEnd
