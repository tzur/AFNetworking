// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageFrameProcessor.h"

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
});

context(@"properties", ^{
  beforeEach(^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
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

context(@"processing frame type repeat", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(64, 32, cv::Vec4b(128, 128, 128, 255));
    LTTexture *input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"FrameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:frame baseMask:nil
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeRepeat]];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
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
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:frame baseMask:nil
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeStretch]];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
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
    [processor setImageFrame:[[LTImageFrame alloc] initBaseTexture:frame baseMask:nil
                                                         frameMask:frameMask
                                                         frameType:LTFrameTypeFit]];
  });
  
  afterEach(^{
    processor = nil;
    output = nil;
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

LTSpecEnd
