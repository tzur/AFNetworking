// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSelectiveAdjustProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTSelectiveAdjustProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTSelectiveAdjustProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTSelectiveAdjustProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default tone properties correctly", ^{
    expect(processor.redSaturation).to.equal(0);
    expect(processor.redLuminance).to.equal(0);
  });
  
  it(@"should fail on incorrect input", ^{
    expect(^{
      processor.redSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.redSaturation = -1.0;
      processor.redLuminance = -1.0;
      processor.orangeSaturation = -1.0;
      processor.orangeLuminance = -1.0;
      processor.yellowSaturation = -1.0;
      processor.yellowLuminance = -1.0;
      processor.greenSaturation = 1.0;
      processor.greenLuminance = 1.0;
      processor.cyanSaturation = 1.0;
      processor.cyanLuminance = 1.0;
      processor.blueSaturation = 1.0;
      processor.blueLuminance = 1.0;
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  sit(@"should reduce saturation of greens and blues and preserve their luminance", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Macbeth.jpg")];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.05)];
    
    LTSelectiveAdjustProcessor *processor =
        [[LTSelectiveAdjustProcessor alloc] initWithInput:input output:output];
    processor.greenSaturation = -1.0;
    processor.blueSaturation = -1.0;
    
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethDesaturatedGreenAndBlue.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
  
  sit(@"should reduce saturation of reds and oranges and increase their luminance", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Macbeth.jpg")];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.05)];
    
    LTSelectiveAdjustProcessor *processor =
        [[LTSelectiveAdjustProcessor alloc] initWithInput:input output:output];
    processor.redSaturation = -1.0;
    processor.orangeSaturation = -1.0;
    processor.redLuminance = 1.0;
    processor.orangeLuminance = 1.0;
    
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethSaturatedBrightenedRedAndOrange.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

SpecGLEnd
