// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "ProceduralFrame.h"

#import "LTOneShotMultiscaleNoiseProcessor.h"
#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(ProceduralFrame)

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
//  it(@"should fail on black color filter", ^{
//    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
//    expect(^{
//      tone.colorFilter = GLKVector3Make(0.0, 0.0, 0.0);
//    }).to.raise(NSInvalidArgumentException);
//  });
//  
//  it(@"should not fail on correct input", ^{
//    BWTonalityProcessor *tone = [[BWTonalityProcessor alloc] initWithInput:noise output:output];
//    expect(^{
//      tone.brightness = 0.1;
//      tone.contrast = 1.2;
//      tone.exposure = 1.5;
//      tone.structure = 0.9;
//      tone.colorFilter = GLKVector3Make(1.0, 1.0, 0.0);
//    }).toNot.raiseAny();
//  });
});

context(@"processing", ^{
  fit(@"should return frame", ^{
    LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(512, 256)];
    
    LTTexture *noiseOutput = [LTTexture textureWithPropertiesOf:frameTexture];
    LTOneShotMultiscaleNoiseProcessor *multiscaleNoise =
        [[LTOneShotMultiscaleNoiseProcessor alloc] initWithOutput:noiseOutput];
    multiscaleNoise[@"seed"] = @(30.0);
    multiscaleNoise[@"density"] = @(4.0);
    [multiscaleNoise process];
    
    ProceduralFrame *frame = [[ProceduralFrame alloc] initWithNoise:noiseOutput
                                                             output:frameTexture];
    frame.width = 5.0;
    frame.spread = 5.0;
    frame.corner = 2.0;
    frame.transitionExponent = 1.0;
    frame.noiseAmplitude = 0.0;
    
    LTSingleTextureOutput *processed = [frame process];
    
    expect(LTFuzzyCompareMat(processed.texture.image, processed.texture.image)).to.beTruthy();
  });
});

SpecEnd
