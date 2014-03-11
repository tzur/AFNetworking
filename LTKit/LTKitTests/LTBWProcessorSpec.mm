// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

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
    LTTexture *lena = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena.png")];
    LTTexture *lenaOutput = [LTTexture textureWithPropertiesOf:lena];
    
    LTBWProcessor *processor = [[LTBWProcessor alloc] initWithInput:lena output:lenaOutput];
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"Lena128BWTonality.png");
    expect($(lenaOutput.image)).to.beCloseToMat($(image));
  });
});

SpecEnd
