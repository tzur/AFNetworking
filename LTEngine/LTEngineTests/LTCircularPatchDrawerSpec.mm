// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTCircularPatchDrawer.h"

#import "LTCircularMeshModel.h"
#import "LTFbo.h"
#import "LTOpenCVExtensions.h"
#import "LTProgramFactory.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTCircularPatchDrawer)

__block LTCircularPatchDrawer *drawer;
__block LTTexture *inputTexture;

beforeEach(^{
  inputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
  inputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
  inputTexture.minFilterInterpolation = LTTextureInterpolationNearest;
  
  drawer =
      [[LTCircularPatchDrawer alloc] initWithProgramFactory:[[LTBasicProgramFactory alloc] init]
                                              sourceTexture:inputTexture];
});

afterEach(^{
  drawer = nil;
  inputTexture = nil;
});

context(@"properties", ^{
  it(@"should update circularMeshModel", ^{
    expect(drawer.circularPatchMode).to.equal(LTCircularPatchModePatch);
    drawer.circularPatchMode = LTCircularPatchModeHeal;
    expect(drawer.circularPatchMode).to.equal(LTCircularPatchModeHeal);
  });

  it(@"should update rotation", ^{
    expect(drawer.rotation).to.equal(drawer.defaultRotation);
    CGFloat rotation = 0.9;
    drawer.rotation = rotation;
    expect(drawer.rotation).to.equal(rotation);
  });

  it(@"should update alpha", ^{
    expect(drawer.alpha).to.equal(drawer.defaultAlpha);
    CGFloat alpha = 0.2;
    drawer.alpha = alpha;
    expect(drawer.alpha).to.equal(alpha);
  });
});

context(@"drawing", ^{
  __block LTTexture *outputTexture;
  __block LTFbo *fbo;
  __block CGSize textureSize;
  
  beforeEach(^{
    outputTexture = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    outputTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    outputTexture.minFilterInterpolation = LTTextureInterpolationNearest;

    fbo = [[LTFbo alloc] initWithTexture:outputTexture];
    textureSize = outputTexture.size;
  });
  
  afterEach(^{
    fbo = nil;
    outputTexture = nil;
  });
  
  it(@"should draw with default values", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGSize size = textureSize / 4;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerDefault.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw with rotation", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    CGSize size = textureSize / 5;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    drawer.rotation = M_PI_4;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerRotation.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with alpha", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGSize size = textureSize / 4;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    drawer.alpha = 0.4;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerAlpha.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw flipped", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGSize size = textureSize / 4;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    drawer.flip = YES;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerFlipped.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw with colors", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.6, textureSize.height * 0.6);
    CGSize size = textureSize / 3;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    LTVector4s colors(drawer.circularMeshModel.numberOfVertices);
    std::fill(colors.begin(), colors.end(), LTVector4(1, 0, 0, 1));
    drawer.membraneColors = colors;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerColors.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw with smoothing alpha", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.6, textureSize.height * 0.6);
    CGSize size = textureSize / 3;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    LTVector4s colors(drawer.circularMeshModel.numberOfVertices);
    std::fill(colors.begin(), colors.end(), LTVector4(1, 0, 0, 1));
    drawer.membraneColors = colors;
    drawer.smoothingAlpha = 0.2;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];

    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerSmoothingAlpha.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw with mirror", ^{
    CGPoint sourceOrigin = CGPointMake(-textureSize.width * 0.25, -textureSize.height * 0.25);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGSize size = textureSize / 2;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerMirror.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should draw with different modes", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.1, textureSize.height * 0.1);
    CGSize size = textureSize / 3;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    LTVector4s colors(drawer.circularMeshModel.numberOfVertices);
    std::fill(colors.begin(), colors.end(), LTVector4(1, 0, 0, 1));
    drawer.membraneColors = colors;
    drawer.circularPatchMode = LTCircularPatchModePatch;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerPatch.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
    
    drawer.circularPatchMode = LTCircularPatchModeClone;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    expect($(outputTexture.image)).to.equalMat($(expected));
    
    drawer.circularPatchMode = LTCircularPatchModeHeal;
    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    expected = LTLoadMat([self class], @"CircularPatchDrawerHeal.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw on a screen framebuffer", ^{
    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.25, textureSize.height * 0.25);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.5, textureSize.height * 0.5);
    CGSize size = textureSize / 4;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);
    [fbo bindAndDrawOnScreen:^{
      [drawer drawRect:targetRect inFramebufferWithSize:fbo.size fromRect:sourceRect];
    }];
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerScreen.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });

  it(@"should draw with mask", ^{
    const NSUInteger kWhite = 255;
    const NSUInteger kBlack = 0;

    drawer = [[LTCircularPatchDrawer alloc]
              initWithProgramFactory:[[LTMaskableProgramFactory alloc] init]
              sourceTexture:inputTexture];

    CGPoint sourceOrigin = CGPointMake(textureSize.width * 0.3, textureSize.height * 0.3);
    CGPoint targetOrigin = CGPointMake(textureSize.width * 0.2, textureSize.height * 0.2);
    CGSize size = textureSize / 2;
    CGRect sourceRect = CGRectFromOriginAndSize(sourceOrigin, size);
    CGRect targetRect = CGRectFromOriginAndSize(targetOrigin, size);

    cv::Mat1b maskMat(textureSize.height, textureSize.width, kBlack);
    maskMat(cv::Rect(0, 0, textureSize.width / 2, textureSize.height)).setTo(kWhite);
    LTTexture *maskTexture = [LTTexture textureWithImage:maskMat];

    [drawer setAuxiliaryTexture:maskTexture withName:kLTMaskableProgramMaskUniformName];
    [drawer setAuxiliaryTexture:inputTexture withName:kLTMaskableProgramInputUniformName];

    [drawer drawRect:targetRect inFramebuffer:fbo fromRect:sourceRect];
    cv::Mat expected = LTLoadMat([self class], @"CircularPatchDrawerMasked.png");
    expect($(outputTexture.image)).to.equalMat($(expected));
  });
});

LTSpecEnd
