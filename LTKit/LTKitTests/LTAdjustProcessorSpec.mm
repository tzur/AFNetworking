// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAdjustProcessor.h"

#import "LTColorGradient.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAdjustProcessor)

__block LTTexture *input;
__block LTTexture *output;

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMatWithName([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:input];
});

afterEach(^{
  input =  nil;
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
      adjust.exposure = -1.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid whitePoint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.whitePoint = GLKVector3Make(4, 4, 4);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on invalid blackPoint parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.blackPoint = GLKVector3Make(4, 4, 4);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid saturation parameter", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      adjust.saturation = -1.0;
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
  
  it(@"should not fail on correct input", ^{
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:input output:output];
    expect(^{
      // Luminance.
      adjust.brightness = 0.1;
      adjust.contrast = 1.2;
      adjust.exposure = 1.5;
      adjust.offset = 0.9;
      // Levels.
      adjust.whitePoint = GLKVector3Make(0.9, 1.0, 1.0);
      adjust.blackPoint = GLKVector3Make(-0.1, 0.0, 0.1);
      // Color.
      adjust.saturation = 1.2;
      adjust.temperature = 0.5;
      adjust.tint = 0.9;
      // Details.
      adjust.details = 1.5;
      adjust.shadows = 0.2;
      adjust.fillLight = 0.1;
      adjust.highlights = 0.3;
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should create correct conversion", ^{
    LTTexture *lena = [LTTexture textureWithImage:LTLoadMatWithName([self class], @"Lena.png")];
    LTTexture *lenaOutput = [LTTexture textureWithPropertiesOf:lena];
  
    LTAdjustProcessor *adjust = [[LTAdjustProcessor alloc] initWithInput:lena output:lenaOutput];
    
    adjust.exposure = 0.9;
    adjust.brightness = 0.1;
    adjust.contrast = 0.8;
    adjust.saturation = 1.0;
    adjust.temperature = 0.0;
    adjust.tint = 0.0;
    adjust.exposure = 1.0;
    adjust.offset = 0.0;
    adjust.blackPoint = GLKVector3Make(0.0, 0.0, 0.0);
    adjust.whitePoint = GLKVector3Make(1.0, 1.0, 1.0);
    // TODO: Add more parameters.
    [adjust process];
    
    // Important: this test depends on the performance of other classes and processors, thus is
    // expected to fail once changes introduced to major rendering components, such as smoothing.
    cv::Mat image = LTLoadMatWithName([self class], @"Lena128BWTonality.png");
    expect($(lenaOutput.image)).to.beCloseToMat($(image));

  });
});

SpecEnd
