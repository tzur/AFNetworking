// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSelectiveAdjustProcessor.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTSelectiveAdjustProcessor)

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
    expect(processor.redHue).to.equal(0);
    
    expect(processor.orangeSaturation).to.equal(0);
    expect(processor.orangeLuminance).to.equal(0);
    expect(processor.orangeHue).to.equal(0);
    
    expect(processor.yellowSaturation).to.equal(0);
    expect(processor.yellowLuminance).to.equal(0);
    expect(processor.yellowHue).to.equal(0);
    
    expect(processor.greenSaturation).to.equal(0);
    expect(processor.greenLuminance).to.equal(0);
    expect(processor.greenHue).to.equal(0);
    
    expect(processor.cyanSaturation).to.equal(0);
    expect(processor.cyanLuminance).to.equal(0);
    expect(processor.cyanHue).to.equal(0);
    
    expect(processor.blueSaturation).to.equal(0);
    expect(processor.blueLuminance).to.equal(0);
    expect(processor.blueHue).to.equal(0);
  });
  
  it(@"should fail on incorrect input", ^{
    expect(^{
      processor.redSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.redLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.redHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.orangeSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.orangeLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.orangeHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.yellowSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.yellowLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.yellowHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.greenSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.greenLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.greenHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.cyanSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.cyanLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.cyanHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    
    expect(^{
      processor.blueSaturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.blueLuminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.blueHue = 1.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.redSaturation = -1.0;
      processor.redLuminance = -1.0;
      processor.redHue = 1.0;
      
      processor.orangeSaturation = -1.0;
      processor.orangeLuminance = -1.0;
      processor.orangeHue = 1.0;
      
      processor.yellowSaturation = -1.0;
      processor.yellowLuminance = -1.0;
      processor.yellowHue = -1.0;
      
      processor.greenSaturation = 1.0;
      processor.greenLuminance = 1.0;
      processor.greenHue = 1.0;
      
      processor.cyanSaturation = 1.0;
      processor.cyanLuminance = 1.0;
      processor.cyanHue = -1.0;
      
      processor.blueSaturation = 1.0;
      processor.blueLuminance = 1.0;
      processor.blueHue = 1.0;
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
  
  sit(@"should change the hues of reds and blues", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Macbeth.jpg")];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:std::round(input.size * 0.05)];
    
    LTSelectiveAdjustProcessor *processor =
        [[LTSelectiveAdjustProcessor alloc] initWithInput:input output:output];
    processor.redHue = 1.0;
    processor.blueHue = -1.0;
    
    [processor process];
    cv::Mat image = LTLoadMat([self class], @"MacbethHueChangeRedsAndBlues.png");
    expect($(output.image)).to.beCloseToMat($(image));
  });
});

LTSpecEnd
