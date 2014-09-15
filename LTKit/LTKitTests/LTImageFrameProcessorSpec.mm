// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageFrameProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImageFrameProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTImageFrameProcessor *processor;

context(@"properties", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
    output = nil;
  });

  it(@"should return default properties correctly", ^{
    expect(processor.widthFactor).to.equal(1.0);
  });

  it(@"should return updated properties correctly", ^{
    processor.widthFactor = 1.0;
    expect(processor.widthFactor).to.equal(1.0);
    processor.widthFactor = 0.9;
    expect(processor.widthFactor).to.equal(0.90);
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
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"FrameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setFrame:frame andType:LTFrameTypeRepeat];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
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
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameClassic.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setFrame:frame andType:LTFrameTypeStretch];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
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
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameCircle.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setFrame:frame andType:LTFrameTypeFit];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
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

context(@"processing frame color", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(32, 32, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame = [LTTexture textureWithImage:LTLoadMat([self class], @"FrameClassic.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output];
    [processor setFrame:frame andType:LTFrameTypeStretch];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
    output = nil;
  });
  
  it(@"should return red framed image", ^{
    processor.color = LTVector3(1.0, 0.0, 0.0);
    processor.colorAlpha = 1.0;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithRedFrame.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  it(@"should return red framed image with alpha", ^{
    processor.color = LTVector3(1.0, 0.0, 0.0);
    processor.colorAlpha = 0.2;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"ImageWithRedFrameWithAlpha.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

LTSpecEnd
