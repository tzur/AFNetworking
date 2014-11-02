// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageTileableFrameProcessor.h"

#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImageTileableFrameProcessor)

__block LTTexture *frameMask;
__block LTTexture *output;
__block LTImageTileableFrameProcessor *processor;

afterEach(^{
  frameMask = nil;
  output = nil;
  processor = nil;
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
    
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
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
    frameMaskMat.create(20, 16);
    frameMaskMat(cv::Rect(0, 0, 16, 20)) = 255;
    frameMaskMat(cv::Rect(2, 2, 12, 12)) = 0;
    frameMask = [LTTexture textureWithImage:frameMaskMat];
    
    // Interpolation scheme.
    frameMask.magFilterInterpolation = LTTextureInterpolationNearest;
    frameMask.minFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    baseTexture.minFilterInterpolation = LTTextureInterpolationNearest;
    
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:output];
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
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    [output clearWithColor:LTVector4Zero];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];
    
    processor = [[LTImageTileableFrameProcessor alloc] initWithInput:input output:input];
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

LTSpecEnd
