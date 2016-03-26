// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleTextureBrush.h"

#import "LTBrushEffectExamples.h"
#import "LTTextureBrushExamples.h"

#import "LTTexture+Factory.h"

SpecBegin(LTSingleTextureBrush)

itShouldBehaveLike(kLTBrushExamples, @{kLTBrushClass: [LTSingleTextureBrush class]});

itShouldBehaveLike(kLTBrushEffectLTBrushExamples, @{kLTBrushClass: [LTSingleTextureBrush class]});

itShouldBehaveLike(kLTTextureBrushExamples, @{kLTTextureBrushClass: [LTSingleTextureBrush class]});

__block LTSingleTextureBrush *brush;

context(@"properties", ^{
  const CGSize kSize = CGSizeMakeUniform(2);

  beforeEach(^{
    brush = [[LTSingleTextureBrush alloc] init];
  });
  
  afterEach(^{
    brush = nil;
  });
  
  it(@"should have default properties", ^{
    cv::Mat4b expected(1, 1);
    expected.setTo(cv::Vec4b(255, 255, 255, 255));
    expect($(brush.texture.image)).to.equalMat($(expected));
  });

  it(@"should set texture", ^{
    LTTexture *byteTexture = [LTTexture byteRGBATextureWithSize:kSize];
    LTTexture *halfTexture = [LTTexture textureWithSize:kSize
                                            pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                         allocateMemory:YES];
    LTTexture *floatTexture = [LTTexture textureWithSize:kSize
                                             pixelFormat:$(LTGLPixelFormatRGBA32Float)
                                          allocateMemory:YES];
    brush.texture = byteTexture;
    expect(brush.texture).to.beIdenticalTo(byteTexture);
    brush.texture = halfTexture;
    expect(brush.texture).to.beIdenticalTo(halfTexture);
    brush.texture = floatTexture;
    expect(brush.texture).to.beIdenticalTo(floatTexture);
  });
  
  it(@"should not set non rgba textures", ^{
    expect(^{
      LTTexture *redTexture = [LTTexture textureWithSize:kSize
                                             pixelFormat:$(LTGLPixelFormatR8Unorm)
                                          allocateMemory:YES];
      brush.texture = redTexture;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      LTTexture *rgTexture = [LTTexture textureWithSize:kSize
                                            pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                         allocateMemory:YES];
      brush.texture = rgTexture;
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
