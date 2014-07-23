// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageFrameProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTImageFrameProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTImageFrameProcessor *processor;

context(@"properties", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:cv::Mat4b(32, 32, cv::Vec4b(128, 64, 255, 255))];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output frame:input
                                                   frameType:LTFrameTypeRepeat];
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
});

context(@"processing", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(64, 32, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"frameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output frame:frame
                                                   frameType:LTFrameTypeRepeat];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
    output = nil;
  });
  
  it(@"should return image with frame", ^{
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithFrame.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with narrow frame", ^{
    processor.widthFactor = 0.97;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithNarrowFrame.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with wide frame", ^{
    processor.widthFactor = 1.4;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithWideFrame.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

context(@"processing frame types", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(32, 64, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
  });
  
  afterEach(^{
    processor = nil;
    input = nil;
    output = nil;
  });
  
  it(@"should return image with frame of type stretch", ^{
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"frameClassic.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output frame:frame
                                                   frameType:LTFrameTypeStretch];
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithFrameTypeStretch.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with frame of type repeat", ^{
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"frameStamp.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output frame:frame
                                                   frameType:LTFrameTypeRepeat];
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithFrameTypeRepeat.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });

  it(@"should return image with frame of type fit", ^{
    LTTexture *frame =
        [LTTexture textureWithImage:LTLoadMat([self class], @"frameCircle.png")];
    processor = [[LTImageFrameProcessor alloc] initWithInput:input output:output frame:frame
                                                   frameType:LTFrameTypeFit];
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"imageWithFrameTypeFit.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

SpecGLEnd
