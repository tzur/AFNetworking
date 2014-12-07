// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTileableFrameProcessor.h"

#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

/// Changes the \c defaultTileScaling so using small tileable texture for testing will not be scaled
/// too much.
@interface LTImageTileableFrameProcessorForTesting : LTImageTileableFrameProcessor
@end

@implementation LTImageTileableFrameProcessorForTesting

- (CGFloat)defaultTileScaling {
  return 2;
}

@end

LTSpecBegin(LTImageTileableFrameProcessor)

__block LTTexture *frameMask;
__block LTTexture *output;
__block LTImageTileableFrameProcessor *processor;

afterEach(^{
  frameMask = nil;
  output = nil;
  processor = nil;
});

context(@"properties", ^{
  beforeEach(^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
  });

  it(@"should return default angle property correctly", ^{
    expect(processor.angle).to.equal(processor.defaultAngle);
  });

  it(@"should return default translation property correctly", ^{
    expect(processor.translation).to.equal(CGPointZero);
  });

  it(@"should return updated angle and translation properties correctly", ^{
    LTImageFrame *imageFrame = [[LTImageFrame alloc] initWithBaseTexture:nil baseMask:nil
                                                               frameMask:nil
                                                               frameType:LTFrameTypeStretch];
    
    CGFloat angle = 1.0;
    CGPoint translation = CGPointMake(10, 20);
    [processor setImageFrame:imageFrame angle:angle translation:translation];
    expect(processor.angle).to.equal(angle);
    expect(processor.translation).to.equal(translation);
  });
  
  it(@"should reset angle and translation properties correctly", ^{
    LTImageFrame *imageFrame = [[LTImageFrame alloc] initWithBaseTexture:nil baseMask:nil
                                                               frameMask:nil
                                                               frameType:LTFrameTypeStretch];
    
    CGFloat angle = 1.0;
    CGPoint translation = CGPointMake(10, 20);
    [processor setImageFrame:imageFrame angle:angle translation:translation];
    [processor resetInputModel];
    expect(processor.angle).to.equal(processor.defaultAngle);
    expect(processor.translation).to.equal(CGPointZero);
  });
});

context(@"processing portrait tileable frame", ^{
  __block LTTexture *baseTexture;
  __block LTTexture *baseMask;
  __block LTImageFrame *imageFrame;
  
  beforeEach(^{
    const CGSize kImageSize = CGSizeMake(40, 60);
    
    cv::Mat4b inputMat(kImageSize.height, kImageSize.width, cv::Vec4b(100, 100, 255, 255));
    LTTexture *input = [LTTexture textureWithImage:inputMat];
    
    output = [LTTexture textureWithImage:cv::Mat4b::zeros(kImageSize.height, kImageSize.width)];
    baseTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
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
    
    processor = [[LTImageTileableFrameProcessorForTesting alloc] initWithInput:input output:output];
    imageFrame = [[LTImageFrame alloc] initWithBaseTexture:baseTexture baseMask:baseMask
                                                 frameMask:frameMask frameType:LTFrameTypeStretch];
    [processor setImageFrame:imageFrame];
  });
  
  afterEach(^{
    baseTexture = nil;
    baseMask = nil;
    imageFrame = nil;
  });
  
  it(@"should tile input rect from origin to target rect", ^{
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
    [processor setImageFrame:imageFrame angle:M_PI_4 translation:CGPointZero];
    processor.globalBaseMaskAlpha = 0.0;
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithRotatedTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect with translation", ^{
    [processor setImageFrame:imageFrame angle:0 translation:CGPointMake(0.2, 0)];
    processor.globalBaseMaskAlpha = 0.0;
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTranslatedTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should tile input rect from origin to target rect with global frame opacity", ^{
    [processor setImageFrame:imageFrame angle:M_PI_4 translation:CGPointZero];
    processor.globalBaseMaskAlpha = 0.0;
    processor.globalFrameMaskAlpha = 0.5;
    processor.color = LTVector3(0, 1, 0);
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTransparentTiledFrame.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"Should tile mask", ^{
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:nil baseMask:baseMask
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
  __block LTTexture *baseTexture;
  
  beforeEach(^{
    const CGSize kImageSize = CGSizeMake(60, 40);
    
    cv::Mat4b inputMat(kImageSize.height, kImageSize.width, cv::Vec4b(100, 100, 255, 255));
    LTTexture *input = [LTTexture textureWithImage:inputMat];
    
    output = [LTTexture textureWithImage:cv::Mat4b::zeros(kImageSize.height, kImageSize.width)];
    baseTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
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
    
    processor = [[LTImageTileableFrameProcessorForTesting alloc] initWithInput:input output:output];
  });
  
  afterEach(^{
    baseTexture = nil;
  });

  it(@"Should tile translated mask on landscape image", ^{
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:baseTexture baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeStretch]
                       angle:0 translation:CGPointMake(0.2, 0)];
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageLandscapeWithTiledMask.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

context(@"processing to screen", ^{
  __block LTTexture *input;
  
  beforeEach(^{
    cv::Mat4b greyPatch(64, 128, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    [output clearWithColor:LTVector4Zero];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
    processor = [[LTImageTileableFrameProcessorForTesting alloc] initWithInput:input output:input];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeFit]
                       angle:0 translation:CGPointZero];
  });
  
  afterEach(^{
    input = nil;
  });
  
  it(@"should not read color from framebuffer when processing to screen", ^{
    [input cloneTo:output];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo bindAndDraw:^{
      [processor processToFramebufferWithSize:fbo.size outputRect:CGRectFromSize(fbo.size)];
    }];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageTileableProcessedToScreen.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

context(@"processing identity type with tileable frame", ^{
  __block LTTexture *baseTexture;
  
  const CGSize kImageSize = CGSizeMake(60, 40);

  beforeEach(^{
    cv::Mat4b inputMat(kImageSize.height, kImageSize.width, cv::Vec4b(100, 100, 255, 255));
    LTTexture *input = [LTTexture textureWithImage:inputMat];
    
    output = [LTTexture textureWithImage:cv::Mat4b::zeros(kImageSize.height, kImageSize.width)];
    baseTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"TileableBaseTexture.png")];
    
    // Set frame mask.
    cv::Mat1b frameMaskMat(kImageSize.height / 2, kImageSize.width / 2, 255);
    frameMaskMat(cv::Rect(2, 5, 20, 10)) = 0;
    frameMask = [LTTexture textureWithImage:frameMaskMat];
    
    // Interpolation scheme.
    frameMask.magFilterInterpolation = LTTextureInterpolationNearest;
    frameMask.minFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    
    processor = [[LTImageTileableFrameProcessorForTesting alloc] initWithInput:input output:output];
  });
  
  afterEach(^{
    baseTexture = nil;
  });

  it(@"should tile base mask with identity frame mask", ^{
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:baseTexture baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeIdentity]
                       angle:0 translation:CGPointZero];
    [processor process];
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithTiledMaskIdentityType.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should raise exception for identity type mapping tiled frame with wrong aspect ratio", ^{
    cv::Mat1b frameMaskMat(kImageSize.height / 2, kImageSize.width, 255);
    frameMask = [LTTexture textureWithImage:frameMaskMat];
    expect(^{
      [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:baseTexture baseMask:nil
                                                               frameMask:frameMask
                                                               frameType:LTFrameTypeIdentity]
                         angle:0 translation:CGPointZero];
    }).to.raise(NSInvalidArgumentException);
  });
});

LTSpecEnd
