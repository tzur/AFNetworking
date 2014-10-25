// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTOpenCVExtensions.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTAdjustProcessor)

__block LTTexture *input;
__block LTTexture *output;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should fail on invalid brightness parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.brightness = 2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid contrast parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.contrast = 10.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid exposure parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.exposure = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid whitePoint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.whitePoint = LTVector3(1, 1, 4);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid blackPoint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.blackPoint = LTVector3(4, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid midPoint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.midPoint = LTVector3(3, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid saturation parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.saturation = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid temperature parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.temperature = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid tint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.tint = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid shadows parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.shadows = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid fillLight parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.fillLight = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid highlights parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.highlights = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid details parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.highlights = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid darksSaturation parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.darksSaturation = 1.1;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid darksHue parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.darksHue = -1.0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid balance parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.balance = -1.1;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid lightsSaturation parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.lightsSaturation = -1.0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid lightsHue parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.lightsHue = -1.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid grey curve", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      cv::Mat1b mat = cv::Mat1b::zeros(1, 100);
      adjust.greyCurve = mat;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid red curve", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      cv::Mat1b mat = cv::Mat1b::zeros(1, 100);
      adjust.redCurve = mat;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid green curve", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      cv::Mat1b mat = cv::Mat1b::zeros(1, 100);
      adjust.greenCurve = mat;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid blue curve", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      cv::Mat1b mat = cv::Mat1b::zeros(1, 100);
      adjust.blueCurve = mat;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct input", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      // Luminance.
      adjust.brightness = 0.1;
      adjust.contrast = 1.0;
      adjust.exposure = 1.0;
      adjust.offset = 0.9;
      // Levels.
      adjust.whitePoint = LTVector3(0.9, 1.0, 1.0);
      adjust.blackPoint = LTVector3(-0.1, 0.0, 0.1);
      adjust.midPoint = LTVector3(-0.1, 0.9, 0.1);
      // Curves.
      cv::Mat1b mat = cv::Mat1b::zeros(1, 256);
      adjust.greyCurve = mat;
      adjust.redCurve = mat;
      adjust.greenCurve = mat;
      adjust.blueCurve = mat;
      // Color.
      adjust.saturation = 0.2;
      adjust.temperature = 0.5;
      adjust.tint = 0.9;
      // Details.
      adjust.details = 1.0;
      adjust.shadows = 0.2;
      adjust.fillLight = 0.1;
      adjust.highlights = 0.3;
      // Split Tone.
      adjust.darksSaturation = 1.0;
      adjust.darksHue = 0.2;
      adjust.balance = 0.1;
      adjust.lightsSaturation = 0.1;
      adjust.lightsHue = 0.1;
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should process positive brightness and contrast correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(64, 64, 64, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(98, 98, 98, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.brightness = 0.5;
    adjust.contrast = 0.15;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process negative contrast correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(192, 128, 64, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(174, 134, 88, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.contrast = -1.0;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process offset correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 0, 0, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(128, 128, 128, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.offset = 0.5;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process exposure correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(255, 255, 255, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.exposure = 1.0;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process black point correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 192, 255, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(0, 128, 255, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.blackPoint = -LTVector3(0.5, 0.5, 0.5);
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 3);
  });
  
  it(@"should process white point correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(64, 64, 64, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(124, 124, 124, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.whitePoint = LTVector3(1.5, 1.5, 1.5);
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process mid point correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(128, 222, 74, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.midPoint = LTVector3(0.0, -1.0, 1.0);
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process curves correctly", ^{
    cv::Mat4b input(11, 11, cv::Vec4b(64, 64, 64, 255));
    cv::Mat4b output(11, 11, cv::Vec4b(1, 65, 129, 255));
    
    std::vector<cv::Mat1b> rgbCurves = {cv::Mat1b(1, 256), cv::Mat1b(1, 256), cv::Mat1b(1, 256)};
    for (NSUInteger i = 0; i < 3; ++i) {
      rgbCurves[i].setTo(i * 64);
    }
    cv::Mat1b greyCurve = cv::Mat1b::zeros(1, 256);
    for (int i = 0; i < 256; ++i) {
      greyCurve(0, i) = std::clamp(i + 1, 0.0, 255);
    }
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.redCurve = rgbCurves[0];
    adjust.greenCurve = rgbCurves[1];
    adjust.blueCurve = rgbCurves[2];
    adjust.greyCurve = greyCurve;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process saturation correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(0, 128, 255, 255));
    // round(dot((0, 128, 255), (0.299, 0.587, 0.114))) = 104
    cv::Mat4b output(1, 1, cv::Vec4b(104,104,104,255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.saturation = -1.0;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process temperature correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(51, 77, 102, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(64, 71, 83, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.temperature = 0.2;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process tint correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(51, 77, 102, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(61, 67, 128, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.tint = 0.2;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });
  
  it(@"should process tonality correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
    // See lightricks-research/enlight/Adjust/runmeAdjustTonalityTest.m to reproduce this result.
    // Minor differences (~1-3 on 0-255 scale) are expected.
    cv::Mat4b output(1, 1, cv::Vec4b(195, 195, 195, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.brightness = 0.3;
    adjust.contrast = 0.2;
    adjust.exposure = 0.05;
    adjust.offset = 0.1;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  it(@"should process color correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(51, 77, 102, 255));
    // See lightricks-research/enlight/Adjust/runmeAdjustColorTest.m to reproduce this result.
    // Minor differences (~1-3 on 0-255 scale) are expected.
    cv::Mat4b output(1, 1, cv::Vec4b(59, 79, 73, 255));
    
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.saturation = 0.2;
    adjust.temperature = 0.2;
    adjust.tint = -0.1;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 3);
  });

  it(@"should process split tone correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(51, 77, 102, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(52, 83, 90, 255));

    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:inputTexture
                                                                  output:outputTexture];
    adjust.darksSaturation = 0.2;
    adjust.darksHue = 0.2;
    adjust.balance = 0.1;
    adjust.lightsSaturation = 0.5;
    adjust.lightsHue = 0.5;
    [adjust process];
    expect($(outputTexture.image)).to.beCloseToMatWithin($(output), 2);
  });

  sit(@"should create correct conversion of luminance, color, details and split-tone", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Meal.jpg")];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];
    
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];

    // Luminance.
    adjust.exposure = 0.05;
    adjust.brightness = -0.1;
    adjust.contrast = 0.1;
    adjust.offset = 0.05;
    adjust.blackPoint = LTVector3(0.1, 0.1, 0.0);
    adjust.whitePoint = LTVector3(1.0, 1.0, 1.0);
    // Color.
    adjust.saturation = -0.3;
    adjust.temperature = 0.05;
    adjust.tint = -0.05;
    // Details.
    adjust.details = 0.2;
    adjust.shadows = 0.2;
    adjust.fillLight = 0.4;
    adjust.highlights = 0.3;
    // Split Tone.
    adjust.darksSaturation = 0.2;
    adjust.darksHue = 0.2;
    adjust.balance = 0.1;
    adjust.lightsSaturation = 0.5;
    adjust.lightsHue = 0.5;

    [adjust process];

    cv::Mat image = LTLoadMat([self class], @"MealAdjusted.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 4);
  });
});

LTSpecEnd
