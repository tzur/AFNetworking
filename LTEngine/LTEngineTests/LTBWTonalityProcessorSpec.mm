// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWTonalityProcessor.h"

#import "LTColorGradient+ForTesting.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBWTonalityProcessor)

__block LTTexture *noise;
__block LTTexture *output;

beforeEach(^{
  noise = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
});

afterEach(^{
  noise = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return identity as default color gradient", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    LTTexture *identityGradientTexture = [[LTColorGradient identityGradient]
                                          textureWithSamplingPoints:256];
    expect(LTFuzzyCompareMat(tone.colorGradientTexture.image,
                             identityGradientTexture.image)).to.beTruthy();
  });
  
  it(@"should fail of invalid brightness parameter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.brightness = 2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid contrast parameter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.contrast = 10.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid exposure parameter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.exposure = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid exposure parameter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.offset = -1.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid structure parameter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.structure = -2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of negative color filter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.colorFilter = LTVector3(-0.1, 0.1, 1.0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on black color filter", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.colorFilter = LTVector3(0.0, 0.0, 0.0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct input", ^{
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.brightness = 0.1;
      tone.contrast = -0.2;
      tone.exposure = 0.5;
      tone.structure = -0.9;
      tone.colorFilter = LTVector3(1.0, 1.0, 0.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should return the input black and white image whithout changes on default parameters", ^{
    LTTexture *deltaTexture = [LTTexture textureWithImage:LTCreateDeltaMat(CGSizeMake(3, 3))];
    LTTexture *deltaOutput = [LTTexture textureWithPropertiesOf:deltaTexture];
    
    // Important: without nearest neighbor magnification filter the test will not pass on the
    // device (iPhone 5).
    // Our current conjecture is that floating point errors for a certain sizes of texture offset
    // the sampling point.
    deltaTexture.magFilterInterpolation = LTTextureInterpolationNearest;
    
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:deltaTexture
                                                                        output:deltaOutput];
    [tone process];

    expect($([deltaOutput image])).to.beCloseToMat($([deltaTexture image]));
  });
  
  it(@"should return black image if blue channel is black and color filter is zero on blue", ^{
    cv::Mat4b greenDelta(3, 3);
    greenDelta = cv::Vec4b(0, 0, 0, 255);
    greenDelta(1, 1) = cv::Vec4b(0, 255, 0, 255);
    
    cv::Mat4b greenDeltaOutput(3, 3);
    greenDeltaOutput = cv::Vec4b(0, 0, 0, 255);
    
    LTTexture *deltaTexture = [LTTexture textureWithImage:greenDelta];
    LTTexture *deltaOutput = [LTTexture textureWithPropertiesOf:deltaTexture];
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:deltaTexture
                                                                        output:deltaOutput];
    tone.colorFilter = LTVector3(0.0, 0.0, 1.0);
    [tone process];

    expect($([deltaOutput image])).to.beCloseToMat($(greenDeltaOutput));
  });
  
  it(@"should increase offset correctly", ^{
    cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
    cv::Mat4b output(1, 1, cv::Vec4b(192, 192, 192, 255));
    LTTexture *inputTexture = [LTTexture textureWithImage:input];
    LTTexture *outputTexture = [LTTexture textureWithPropertiesOf:inputTexture];
    
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:inputTexture
                                                                        output:outputTexture];
    tone.offset = 0.25;
    [tone process];
    expect($(outputTexture.image)).to.beCloseToMat($(output));
  });
  
  sit(@"should create correct conversion", ^{
    LTTexture *lena = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    LTTexture *lenaOutput = [LTTexture textureWithPropertiesOf:lena];
    
    LTBWTonalityProcessor *tone = [[LTBWTonalityProcessor alloc] initWithInput:lena
                                                                        output:lenaOutput];
    tone.exposure = -0.2;
    tone.structure = 0.5;
    tone.brightness = 0.1;
    tone.contrast = -0.2;
    tone.colorFilter = LTVector3(0.1, 0.1, 1.0);
    tone.colorGradientTexture =
        [[LTColorGradient colderThanNeutralGradient] textureWithSamplingPoints:256];
    [tone process];
    
    // Important: this test depends on the performance of other classes and processors, thus is
    // expected to fail once changes introduced to major rendering components, such as smoothing.
    cv::Mat image = LTLoadMat([self class], @"Lena128BWTonality.png");
    expect($([lenaOutput image])).to.beCloseToMat($(image));
  });
});

SpecEnd
