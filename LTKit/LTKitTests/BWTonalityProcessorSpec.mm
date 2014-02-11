// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "BWTonalityProcessor.h"

#import "LTColorGradient.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(BWTonalityProcessor)

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
  noise = [LTTexture textureWithImage:LTLoadMatWithName([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:noise];
});

afterEach(^{
  noise =  nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should fail of invalid brightness parameter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.brightness = 2.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid contrast parameter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.contrast = 10.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid exposure parameter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.exposure = -1.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of invalid structure parameter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.structure = -1.0;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail of negative color filter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.colorFilter = GLKVector3Make(-0.1, 0.1, 1.0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail on black color filter", ^{
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
    expect(^{
      tone.colorFilter = GLKVector3Make(0.0, 0.0, 0.0);
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should return the input black and white image whithout changes on default parameters", ^{
    LTTexture *deltaTexture = [LTTexture textureWithImage:LTCreateDeltaMat(CGSizeMake(7, 7))];
    LTTexture *deltaOutput = [LTTexture textureWithPropertiesOf:deltaTexture];
    
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:deltaTexture
                                                                    output:deltaOutput];
    LTSingleTextureOutput *processed = [tone process];
    
    expect(LTFuzzyCompareMat(deltaTexture.image, processed.texture.image)).to.beTruthy();
  });
  
  it(@"should return black image if blue channel is black and color filter is zero on blue", ^{
    cv::Mat4b greenDelta(7, 7);
    greenDelta = cv::Vec4b(0, 0, 0, 255);
    greenDelta(3, 3) = cv::Vec4b(0, 255, 0, 255);
    
    cv::Mat4b greenDeltaOutput(7, 7);
    greenDeltaOutput = cv::Vec4b(0, 0, 0, 255);
    
    LTTexture *deltaTexture = [LTTexture textureWithImage:greenDelta];
    LTTexture *deltaOutput = [LTTexture textureWithPropertiesOf:deltaTexture];
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:deltaTexture
                                                                    output:deltaOutput];
    tone.colorFilter = GLKVector3Make(0.0, 0.0, 1.0);
    LTSingleTextureOutput *processed = [tone process];

    expect(LTFuzzyCompareMat(greenDeltaOutput, processed.texture.image)).to.beTruthy();
  });
  
  it(@"should create correct conversion", ^{
    LTTexture *lena = [LTTexture textureWithImage:LTLoadMatWithName([self class], @"Lena128.png")];
    LTTexture *lenaOutput = [LTTexture textureWithPropertiesOf:lena];
    
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
    
    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:lena output:lenaOutput];
    tone.exposure = 0.9;
    tone.structure = 1.5;
    tone.brightness = 0.1;
    tone.contrast = 0.8;
    tone.colorFilter = GLKVector3Make(0.1, 0.1, 1.0);
    tone.colorGradient = colorGradient;
    LTSingleTextureOutput *processed = [tone process];
    
    // Important: this test depends on the performance of other classes and processors, thus is
    // expected to fail once changes introduced to major rendering components, such as smoothing.
    cv::Mat image = LTLoadMatWithName([self class], @"Lena128BWTonality.png");
    expect(LTFuzzyCompareMat(processed.texture.image, image)).to.beTruthy();
  });
});

SpecEnd
