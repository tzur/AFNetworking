// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTileableFrameProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImageTileableFrameProcessor)

__block LTTexture *frameMask;
__block LTTexture *output;
__block LTImageTileableFrameProcessor *processor;

beforeEach(^{
  cv::Mat1b originalFrameMask(32, 32, 255);
  frameMask = [LTTexture textureWithImage:originalFrameMask];
});

afterEach(^{
  frameMask = nil;
});

context(@"properties", ^{
  beforeEach(^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
  });
  
  it(@"should return updated angle property correctly", ^{
    processor.angle = M_PI_4;
    expect(processor.angle).to.equal(M_PI_4);
    processor.angle = -M_PI;
    expect(processor.angle).to.equal(-M_PI);
  });
  
  it(@"should return updated translation property correctly", ^{
    LTVector2 translationVec = LTVector2(0.5, 0.2);
    processor.translation = translationVec;
    expect(processor.translation).to.equal(translationVec);
    translationVec = LTVector2(-0.8, -1.0);
    processor.translation = translationVec;
    expect(processor.translation).to.equal(translationVec);
  });
});

context(@"processing portrait tileable frame", ^{
  __block LTTexture *baseMask;
  
  beforeEach(^{
    const CGSize kImageSize = CGSizeMake(40, 60);
    
    cv::Mat4b inputMat(kImageSize.height, kImageSize.width, cv::Vec4b(100, 100, 255, 255));
    LTTexture *input = [LTTexture textureWithImage:inputMat];
    
    output = [LTTexture textureWithImage:cv::Mat4b::zeros(kImageSize.height, kImageSize.width)];
    LTTexture *baseTexture =
        [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
    // Set base mask. Quarter of the mask is with alpha zero.
    cv::Mat1b baseMaskMat;
    baseMaskMat.create(baseTexture.size.width, baseTexture.size.height);
    baseMaskMat(cv::Rect(0, 0, baseTexture.size.width, baseTexture.size.height)) = 255;
    baseMaskMat(cv::Rect(0, 0, baseTexture.size.width / 2, baseTexture.size.height / 2)) = 0;
    baseMask = [LTTexture textureWithImage:baseMaskMat];
    
    // Set frame mask.
    cv::Mat1b frameMaskMat;
    frameMaskMat.create(32, 32);
    frameMaskMat(cv::Rect(0, 0, 32, 32)) = 255;
    frameMaskMat(cv::Rect(5, 5, 22, 22)) = 0;
    frameMask = [LTTexture textureWithImage:frameMaskMat];
    
    // Interpolation scheme.
    frameMask.magFilterInterpolation = LTTextureInterpolationNearest;
    frameMask.minFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    baseMask.magFilterInterpolation = LTTextureInterpolationNearest;
    baseMask.minFilterInterpolation = LTTextureInterpolationNearest;
    
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:baseTexture baseMask:baseMask
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeStretch]];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
    baseMask = nil;
  });
  
  it(@"should tile input rect from origin to target rect", ^{
    processor.translation = LTVector2Zero;
    processor.globalBaseMaskAlpha = 0.0;
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect only with color", ^{
    processor.globalBaseMaskAlpha = 1.0;
    processor.color = LTVector3(0, 1, 0);
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithColoredTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect with angle", ^{
    processor.angle = M_PI_4;
    processor.globalBaseMaskAlpha = 0.0;
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithRotatedTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect with translation", ^{
    processor.translation = LTVector2(0.2, 0);
    processor.globalBaseMaskAlpha = 0.0;
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTranslatedTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect with global frame opacity", ^{
    processor.angle = M_PI_4;
    processor.globalBaseMaskAlpha = 0.0;
    processor.globalFrameMaskAlpha = 0.5;
    processor.color = LTVector3(0, 1, 0);
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTransparentTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"Should tile mask", ^{
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:nil baseMask:baseMask
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeStretch]];
    processor.color = LTVector3(1, 0, 0);
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTransparentTiledMask.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

context(@"processing landscape image with tileable frame", ^{
  beforeEach(^{
    const CGSize kImageSize = CGSizeMake(60, 40);
    
    cv::Mat4b inputMat(kImageSize.height, kImageSize.width, cv::Vec4b(100, 100, 255, 255));
    LTTexture *input = [LTTexture textureWithImage:inputMat];
    
    output = [LTTexture textureWithImage:cv::Mat4b::zeros(kImageSize.height, kImageSize.width)];
    LTTexture *baseTexture =
        [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
    // Set frame mask.
    cv::Mat1b frameMaskMat;
    frameMaskMat.create(16, 16);
    frameMaskMat(cv::Rect(0, 0, 16, 16)) = 255;
    frameMaskMat(cv::Rect(2, 2, 12, 12)) = 0;
    frameMask = [LTTexture textureWithImage:frameMaskMat];
    
    // Interpolation scheme.
    frameMask.magFilterInterpolation = LTTextureInterpolationNearest;
    frameMask.minFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:baseTexture baseMask:nil
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeStretch]];
  });

  it(@"Should tile translated mask on landscape image", ^{
    processor.translation = LTVector2(0.2, 0);
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageLandscapeWithTiledMask.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

LTSpecEnd
