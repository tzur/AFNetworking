// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDuoProcessor.h"

#import "LTCGExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTDuoProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTDuoProcessor *processor;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(16, 16)];
  processor = [[LTDuoProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default mask properties correctly", ^{
    expect(processor.maskType).to.equal(LTDualMaskTypeRadial);
    expect(GLKVector2AllEqualToVector2(processor.center, GLKVector2Make(8, 8))).to.beTruthy();
    expect(processor.diameter).to.equal(8);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.blueColor).to.equal(GLKVector4Make(0, 0, 1, 1));
    expect(processor.redColor).to.equal(GLKVector4Make(1, 0, 0, 1));
  });
  
  it(@"should fail when passing incorrect red color", ^{
    expect(^{
      processor.blueColor = GLKVector4Make(-0.1, 0, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should fail when passing incorrect blue color", ^{
    expect(^{
      processor.redColor = GLKVector4Make(1.1, 0, 0, 0);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct input", ^{
    expect(^{
      processor.blueColor = GLKVector4Make(0.2, 0, 0, 0.9);
      processor.redColor = GLKVector4Make(1, 1, 0, 0);
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"SanFrancisco.jpg")];
    CGSize outputSize = input.size * 0.1;
    output = [LTTexture byteRGBATextureWithSize:std::round(outputSize)];
    processor = [[LTDuoProcessor alloc] initWithInput:input output:output];
    // Configure mask.
    processor.maskType = LTDualMaskTypeLinear;
    processor.center = GLKVector2Make(0.5 * outputSize.width, 0.64 * outputSize.height);
    processor.spread = 0.75;
    processor.angle = 0.19;
    processor.opacity = 1.0;
  });
  
  sit(@"should apply blue and red colors", ^{
    processor.blueColor = GLKVector4Make(0.6, 0.5, 0.2, 1.0);
    processor.redColor = GLKVector4Make(0.0, 0.2, 0.3, 1.0);
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoBlueRed.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply only blue color", ^{
    processor.blueColor = GLKVector4Make(0.6, 0.5, 0.2, 1.0);
    processor.redColor = GLKVector4Make(0.0, 0.2, 0.3, 0.0);
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoBlue.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
  
  sit(@"should apply only blue color", ^{
    processor.blueColor = GLKVector4Make(0.6, 0.5, 0.2, 0.0);
    processor.redColor = GLKVector4Make(0.0, 0.2, 0.3, 1.0);
    [processor process];
    
    cv::Mat image = LTLoadMat([self class], @"DuoRed.png");
    expect($(output.image)).to.beCloseToMatWithin($(image), 1);
  });
});
  
SpecEnd
