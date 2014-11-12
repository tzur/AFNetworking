// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImageFrameProcessor)

__block LTTexture *frameMask;
__block LTTexture *output;
__block LTImageFrameProcessor *processor;

beforeEach(^{
  cv::Mat1b originalFrameMask(32, 32, 255);
  frameMask = [LTTexture textureWithImage:originalFrameMask];
});

afterEach(^{
  frameMask = nil;
  processor = nil;
  output = nil;
});

context(@"properties", ^{
  beforeEach(^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
  });

  it(@"should return default width factor property correctly", ^{
    expect(processor.widthFactor).to.equal(1.0);
  });

  it(@"should return updated width factor property correctly", ^{
    processor.widthFactor = 1.0;
    expect(processor.widthFactor).to.equal(1.0);
    processor.widthFactor = 0.9;
    expect(processor.widthFactor).to.equal(0.90);
  });
  
  it(@"should return updated color property correctly", ^{
    LTVector3 color = LTVector3(0.5, 1.0, 0.2);
    processor.color = color;
    expect(processor.color).to.equal(color);
  });

  it(@"should return updated width globalBaseMaskAlpha property correctly", ^{
    processor.globalBaseMaskAlpha = 1.0;
    expect(processor.globalBaseMaskAlpha).to.equal(1.0);
    processor.globalBaseMaskAlpha = 0.3;
    expect(processor.globalBaseMaskAlpha).to.equal(0.3);
  });

  it(@"should return updated width globalFrameMaskAlpha property correctly", ^{
    processor.globalFrameMaskAlpha = 0.0;
    expect(processor.globalFrameMaskAlpha).to.equal(0.0);
    processor.globalFrameMaskAlpha = 0.3;
    expect(processor.globalFrameMaskAlpha).to.equal(0.3);
  });

  it(@"should return image without frame", ^{
    [processor process];

    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithoutFrame.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

context(@"copy constructor", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(64, 32, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"FrameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeRepeat]];
  });
  
  it(@"should return same values for copied textures", ^{
    LTImageFrameProcessor *copiedProcessor =
        [[LTImageFrameProcessor alloc] initWithImageFrameProcessor:processor];
    cv::Mat inputMat = processor.inputTexture.image;
    expect($(copiedProcessor.inputTexture.image)).to.beCloseToMatWithin($(inputMat), 2);
    cv::Mat outputMat = processor.outputTexture.image;
    expect($(copiedProcessor.outputTexture.image)).to.beCloseToMatWithin($(outputMat), 2);
  });

  it(@"should return same values for copied properties", ^{
    processor.widthFactor = 1.02;
    processor.color = LTVector3(0.5, 1, 0.2);
    processor.globalBaseMaskAlpha = 0.5;
    processor.globalFrameMaskAlpha = 0.2;
    LTImageFrameProcessor *copiedProcessor =
        [[LTImageFrameProcessor alloc] initWithImageFrameProcessor:processor];
    expect(copiedProcessor.widthFactor).to.equal(processor.widthFactor);
    expect(copiedProcessor.color).to.equal(processor.color);
    expect(copiedProcessor.globalBaseMaskAlpha).to.equal(processor.globalBaseMaskAlpha);
    expect(copiedProcessor.globalFrameMaskAlpha).to.equal(processor.globalFrameMaskAlpha);
  });
});

context(@"processing frame type repeat", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(64, 32, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"FrameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeRepeat]];
  });
  
  it(@"should return image with repeat frame", ^{
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeRepeat.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with narrow repeat frame", ^{
    processor.widthFactor = 0.92;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithNarrowFrameTypeRepeat.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });

  it(@"should return image with wide repeat frame", ^{
    processor.widthFactor = 1.4;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithWideFrameTypeRepeat.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

context(@"processing frame type stretch", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameClassic.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeStretch]];
  });
  
  it(@"should return image with stretch frame", ^{
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeStretch.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  it(@"should return image with narrow stretch frame", ^{
    processor.widthFactor = 0.95;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class],
                                              @"ImageWithNarrowFrameTypeStretch.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should return image with wide stretch frame", ^{
    processor.widthFactor = 1.4;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithWideFrameTypeStretch.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

context(@"processing frame type fit", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];

    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeFit]];
  });
  
  it(@"should return image with fit frame", ^{
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeFit.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  it(@"should return image with narrow fit frame", ^{
    processor.widthFactor = 0.85;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithNarrowFrameTypeFit.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
  
  it(@"should return image with wide fit frame", ^{
    processor.widthFactor = 1.4;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithWideFrameTypeFit.png")];
    expect($(output.image)).to.beCloseToMatWithin($(precomputedResult.image), 2);
  });
});

context(@"reading color from output", ^{
  __block LTTexture *input;
  
  beforeEach(^{
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    [output clearWithColor:LTVector4Zero];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];
    
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:input];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeFit]];
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
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeFit.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  it(@"should read color from framebuffer when input equals output", ^{
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeFit.png")];
    expect($(input.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

context(@"processing identity frame type", ^{
  __block LTTexture *frame;
  
  beforeEach(^{
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];
  });

  afterEach(^{
    frame = nil;
  });

  it(@"should return image with identity type mapping frame", ^{
    cv::Mat1b originalFrameMask(30, 60, 255);
    originalFrameMask(cv::Rect(2, 5, 55, 25)) = 0;
    frameMask = [LTTexture textureWithImage:originalFrameMask];
    [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                             frameMask:frameMask
                                                             frameType:LTFrameTypeIdentity]];
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameTypeIdentity.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should raise exception for identity type mapping frame with wrong aspect ratio", ^{
    cv::Mat1b originalFrameMask(60, 60, 255);
    frameMask = [LTTexture textureWithImage:originalFrameMask];
    expect(^{
      [processor setImageFrame:[[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                               frameMask:frameMask
                                                               frameType:LTFrameTypeIdentity]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing to frame buffer", ^{
  __block LTFbo *fbo;
  __block LTTexture *input;
  __block LTTexture *output;
  __block LTTexture *outputFBO;
  __block LTImageFrame *imageFrame;
  
  beforeEach(^{
    input = [LTTexture textureWithImage:cv::Mat4b(32, 64, cv::Vec4b(128, 128, 128, 255))];
    output = [LTTexture textureWithImage:cv::Mat4b(32, 64, cv::Vec4b(0, 128, 128, 255))];
    outputFBO = [LTTexture textureWithImage:cv::Mat4b(32, 64, cv::Vec4b(255, 0, 0, 255))];
    fbo = [[LTFbo alloc] initWithTexture:outputFBO];

    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];
    cv::Mat1b originalFrameMask(30, 60, 255);
    originalFrameMask(cv::Rect(2, 5, 55, 25)) = 0;
    frameMask = [LTTexture textureWithImage:originalFrameMask];
    imageFrame = [[LTImageFrame alloc] initWithBaseTexture:frame baseMask:nil
                                                 frameMask:frameMask
                                                 frameType:LTFrameTypeIdentity];
});

  afterEach(^{
    fbo = nil;
    input = nil;
    output = nil;
    outputFBO = nil;
    imageFrame = nil;
  });

  it(@"should return image with frame on frame buffer", ^{
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:imageFrame];
    
    [fbo bindAndDraw:^{
      [processor processToFramebufferWithSize:fbo.size outputRect:CGRectFromSize(fbo.size)];
    }];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class],
                                              @"ImageWithFrameWithoutOutputColor.png")];
    expect($(outputFBO.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with frame on frame buffer", ^{
    processor = [[LTImageFrameProcessor alloc] initWithInput:output output:output];
    [processor setImageFrame:imageFrame];

    [fbo bindAndDraw:^{
      [processor processToFramebufferWithSize:fbo.size outputRect:CGRectFromSize(fbo.size)];
    }];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithFrameWithOutputColor.png")];
    expect($(outputFBO.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

LTSpecEnd
