// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTColorGradient.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBWProcessor)

__block LTTexture *noise;
__block LTTexture *output;

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

beforeEach(^{
  noise = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
});

afterEach(^{
  noise =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should XXX", ^{
    LTBWProcessor *processor = [[LTBWProcessor alloc] initWithInput:noise output:output];
    expect(^{
      processor.brightness = 0.1;
      processor.contrast = 1.2;
      processor.exposure = 1.5;
      processor.structure = 0.9;
      processor.colorFilter = GLKVector3Make(1.0, 1.0, 0.0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  it(@"should return the input black and white image whithout changes on default parameters", ^{
    LTTexture *input = [LTTexture textureWithImage:LTLoadMat([self class], @"Meal.jpg")];
    LTTexture *lenaOutput = [LTTexture textureWithPropertiesOf:input];
    
    LTTexture *noise = [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
    noise.wrap = LTTextureWrapRepeat;
    
    LTBWProcessor *processor = [[LTBWProcessor alloc] initWithInput:input output:lenaOutput];
    processor.colorFilter = GLKVector3Make(1.0, 0.0, 1.0);
    processor.brightness = 0.1;
    processor.exposure = 1.1;
    processor.structure = 1.5;
    
    processor.vignettingNoise = noise;
    processor.vignetteColor = GLKVector3Make(0.0, 0.0, 0.0);
    processor.vignettingSpread = 25.0;
    processor.vignettingCorner = 8.0;
    processor.vignettingNoiseAmplitude = 10.0;
    processor.vignettingNoiseChannelMixer = GLKVector3Make(1.0, 0.1, 0.2);
    
    processor.grainTexture = noise;
    processor.grainAmplitude = 0.1;
    processor.grainChannelMixer = GLKVector3Make(1.0, 0.0, 1.0);
    
    processor.wideFrameWidth = 4;
    processor.wideFrameSpread = 0.0;
    processor.wideFrameCorner = 0.0;
    processor.wideFrameNoiseAmplitude = 1.0;
    processor.wideFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    processor.wideFrameColor = GLKVector3Make(1.0, 1.0, 1.0);
    
    processor.narrowFrameWidth = 1.5;
    processor.narrowFrameSpread = 0.0;
    processor.narrowFrameCorner = 0.0;
    processor.narrowFrameNoiseAmplitude = 1.0;
    processor.narrowFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    processor.narrowFrameColor = GLKVector3Make(0.0, 0.0, 0.0);
    
    // Scale the red channel slightly to create a "neutral-to-cold" gradient.
    CGFloat redScale = 0.95;
    LTColorGradientControlPoint *controlPoint0 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.0 color:GLKVector3Make(0.0, 0.0, 0.0)];
    LTColorGradientControlPoint *controlPoint1 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.25 color:GLKVector3Make(0.25 * redScale, 0.25, 0.25)];
    LTColorGradientControlPoint *controlPoint2 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.5 color:GLKVector3Make(0.5 * redScale, 0.5, 0.5)];
    LTColorGradientControlPoint *controlPoint3 = [[LTColorGradientControlPoint alloc]
        initWithPosition:0.75 color:GLKVector3Make(0.75 * redScale, 0.75, 0.75)];
    LTColorGradientControlPoint *controlPoint4 = [[LTColorGradientControlPoint alloc]
        initWithPosition:1.0 color:GLKVector3Make(1.0 * redScale, 1.0, 1.0)];
    NSArray *controlPoints = @[controlPoint0, controlPoint1, controlPoint2, controlPoint3,
                               controlPoint4];
    
    LTColorGradient *colorGradient = [[LTColorGradient alloc] initWithControlPoints:controlPoints];
    
    processor.colorGradientTexture = [colorGradient textureWithSamplingPoints:256];;
    
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"Lena128BWTonality.png");
    expect($(lenaOutput.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
