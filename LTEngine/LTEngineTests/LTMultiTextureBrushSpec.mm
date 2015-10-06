// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMultiTextureBrush.h"

#import "LTBrushEffectExamples.h"
#import "LTTextureBrushExamples.h"

#import "LTTexture+Factory.h"

LTSpecBegin(LTMultiTextureBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTMultiTextureBrush class]});

itShouldBehaveLike(kLTBrushEffectLTBrushExamples, @{kLTBrushClass: [LTMultiTextureBrush class]});

itShouldBehaveLike(kLTTextureBrushExamples, @{kLTTextureBrushClass: [LTMultiTextureBrush class]});

__block LTMultiTextureBrush *brush;

context(@"properties", ^{
  const CGSize kSize = CGSizeMakeUniform(2);
  
  beforeEach(^{
    brush = [[LTMultiTextureBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    cv::Mat4b expected(1, 1);
    expected.setTo(cv::Vec4b(255, 255, 255, 255));
    expect(brush.textures.count).to.equal(1);
    expect($([(LTTexture *)brush.textures.firstObject image])).to.equalMat($(expected));
  });
  
  it(@"should set textures", ^{
    LTTexture *byteTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *halfTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionHalfFloat
                                                 format:LTTextureFormatRGBA allocateMemory:YES];
    LTTexture *floatTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionFloat
                                                  format:LTTextureFormatRGBA allocateMemory:YES];
    NSArray *textures = [@[byteTexture, halfTexture, floatTexture] mutableCopy];
    brush.textures = textures;
    expect(brush.textures).notTo.beIdenticalTo(textures);
    expect(brush.textures.count).to.equal(textures.count);
    for (NSUInteger i = 0; i < textures.count; ++i) {
      expect(brush.textures[i]).to.beIdenticalTo(textures[i]);
    }
  });
  
  it(@"should not set non rgba textures", ^{
    expect(^{
      LTTexture *redTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                  format:LTTextureFormatRed allocateMemory:YES];
      brush.textures = @[redTexture];
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      LTTexture *rgTexture = [LTTexture textureWithSize:kSize precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRG allocateMemory:YES];
      brush.textures = @[rgTexture];
    }).to.raise(NSInvalidArgumentException);
  });
});

LTSpecEnd
