// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureMetadata.h"

#import "LTJSONSerializationAdapter.h"
#import "LTTexture+Factory.h"

SpecBegin(LTTextureMetadata)

__block LTTextureMetadata *metadata;

afterEach(^{
  metadata = nil;
});

context(@"deserialize", ^{
  __block NSError *error;

  beforeEach(^{
    NSDictionary *json = @{
      @"size": @"(1, 2)",
      @"format": @(LTTextureFormatRGBA),
      @"precision": @(LTTexturePrecisionHalfFloat),
      @"maxMipmapLevel": @3,
      @"usingAlphaChannel": @YES,
      @"minFilterInterpolation": @(LTTextureInterpolationLinear),
      @"magFilterInterpolation": @(LTTextureInterpolationLinear),
      @"wrap": @(LTTextureWrapRepeat),
      @"generationID": @"someID",
      @"fillColor": @"(0, 0.25, 0.5, 1.0)"
    };

    metadata = [MTLJSONAdapter modelOfClass:[LTTextureMetadata class] fromJSONDictionary:json
                                      error:&error];
  });

  it(@"should deserialize without errors", ^{
    expect(error).to.beNil();
  });

  it(@"should deserialize correctly", ^{
    expect(metadata.size).to.equal(CGSizeMake(1, 2));
    expect(metadata.format).to.equal(LTTextureFormatRGBA);
    expect(metadata.precision).to.equal(LTTexturePrecisionHalfFloat);
    expect(metadata.maxMipmapLevel).to.equal(3);
    expect(metadata.usingAlphaChannel).to.beTruthy();
    expect(metadata.minFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(metadata.magFilterInterpolation).to.equal(LTTextureInterpolationLinear);
    expect(metadata.wrap).to.equal(LTTextureWrapRepeat);
    expect(metadata.generationID).to.equal(@"someID");
    expect(metadata.fillColor).to.equal(LTVector4(0, 0.25, 0.5, 1.0));
  });
});

it(@"should extract metadata from texture", ^{
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 8)];
  texture.usingAlphaChannel = YES;
  texture.minFilterInterpolation = LTTextureInterpolationLinear;
  texture.magFilterInterpolation = LTTextureInterpolationLinear;
  texture.wrap = LTTextureWrapRepeat;
  [texture clearWithColor:LTVector4One];
  LTTextureMetadata *metadata = texture.metadata;

  expect(metadata.size).to.equal(texture.size);
  expect(metadata.format).to.equal(texture.format);
  expect(metadata.precision).to.equal(texture.precision);
  expect(metadata.maxMipmapLevel).to.equal(texture.maxMipmapLevel);
  expect(metadata.usingAlphaChannel).to.equal(texture.usingAlphaChannel);
  expect(metadata.minFilterInterpolation).to.equal(texture.minFilterInterpolation);
  expect(metadata.magFilterInterpolation).to.equal(texture.magFilterInterpolation);
  expect(metadata.wrap).to.equal(texture.wrap);
  expect(metadata.generationID).to.equal(texture.generationID);
  expect(metadata.fillColor).to.equal(texture.fillColor);
});

context(@"create texture with metadata", ^{
  __block NSMutableDictionary *json;

  beforeEach(^{
    json = [@{
      @"size": @"(4, 8)",
      @"format": @(LTTextureFormatRGBA),
      @"precision": @(LTTexturePrecisionHalfFloat),
      @"usingAlphaChannel": @YES,
      @"minFilterInterpolation": @(LTTextureInterpolationLinear),
      @"magFilterInterpolation": @(LTTextureInterpolationLinear),
      @"wrap": @(LTTextureWrapRepeat),
      @"generationID": @"someID",
      @"fillColor": @"(0, 0.25, 0.5, 1.0)"
    } mutableCopy];
  });

  it(@"should create regular texture", ^{
    json[@"maxMipmapLevel"] = @0;
    metadata = [MTLJSONAdapter modelOfClass:[LTTextureMetadata class] fromJSONDictionary:json
                                      error:nil];

    LTTexture *texture = [LTTexture textureWithMetadata:metadata];
    expect(texture.size).to.equal(metadata.size);
    expect(texture.format).to.equal(metadata.format);
    expect(texture.precision).to.equal(metadata.precision);
    expect(texture.maxMipmapLevel).to.equal(metadata.maxMipmapLevel);
    expect(texture.usingAlphaChannel).to.equal(metadata.usingAlphaChannel);
    expect(texture.minFilterInterpolation).to.equal(metadata.minFilterInterpolation);
    expect(texture.magFilterInterpolation).to.equal(metadata.magFilterInterpolation);
    expect(texture.wrap).to.equal(metadata.wrap);
    expect(texture.generationID).notTo.equal(metadata.generationID);
    expect(texture.fillColor).notTo.equal(metadata.fillColor);
    expect(texture.fillColor.isNull()).to.beTruthy();

    expect(^{
      [texture clearWithColor:LTVector4Zero];
    }).notTo.raiseAny();
  });

  it(@"should create mipmap texture", ^{
    json[@"maxMipmapLevel"] = @3;
    metadata = [MTLJSONAdapter modelOfClass:[LTTextureMetadata class] fromJSONDictionary:json
                                      error:nil];

    LTTexture *texture = [LTTexture textureWithMetadata:metadata];
    expect(texture.size).to.equal(metadata.size);
    expect(texture.format).to.equal(metadata.format);
    expect(texture.precision).to.equal(metadata.precision);
    expect(texture.maxMipmapLevel).to.equal(metadata.maxMipmapLevel);
    expect(texture.usingAlphaChannel).to.equal(metadata.usingAlphaChannel);
    expect(texture.minFilterInterpolation).to.equal(metadata.minFilterInterpolation);
    expect(texture.magFilterInterpolation).to.equal(metadata.magFilterInterpolation);
    expect(texture.wrap).to.equal(metadata.wrap);
    expect(texture.generationID).notTo.equal(metadata.generationID);
    expect(texture.fillColor).notTo.equal(metadata.fillColor);
    expect(texture.fillColor.isNull()).to.beTruthy();

    expect(^{
      [texture clearWithColor:LTVector4Zero];
    }).notTo.raiseAny();
  });
});

SpecEnd
