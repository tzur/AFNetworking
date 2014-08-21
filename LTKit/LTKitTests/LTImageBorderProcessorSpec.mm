// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageBorderProcessor.h"

//#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImageBorderProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTImageBorderProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:LTLoadMat([self class], @"Noise.png")];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTImageBorderProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default outer frame properties correctly", ^{
    expect(processor.outerFrameWidth).to.equal(0);
    expect(processor.outerFrameSpread).to.equal(0);
    expect(processor.outerFrameCorner).to.equal(0);
    expect(processor.outerFrameNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.outerFrameNoiseAmplitude).to.equal(0);
    expect(processor.outerFrameColor == GLKVector3Make(1, 1, 1)).to.beTruthy();
  });
  
  it(@"should return default inner frame properties correctly", ^{
    expect(processor.innerFrameWidth).to.equal(0);
    expect(processor.innerFrameSpread).to.equal(0);
    expect(processor.innerFrameCorner).to.equal(0);
    expect(processor.innerFrameNoiseChannelMixer == GLKVector3Make(1, 0, 0)).to.beTruthy();
    expect(processor.innerFrameNoiseAmplitude).to.equal(0);
    expect(processor.innerFrameColor == GLKVector3Make(1, 1, 1)).to.beTruthy();
  });
  
  it(@"should return default roughness property correctly", ^{
    expect(processor.roughness).to.equal(0);
  });
  
  it(@"should not update noise amplitude values on roughness change", ^{
    processor.outerFrameNoiseAmplitude = 1.0;
    processor.innerFrameNoiseAmplitude = 2.0;
    processor.roughness = 0;
    expect(processor.outerFrameNoiseAmplitude).to.equal(1.0);
    expect(processor.innerFrameNoiseAmplitude).to.equal(2.0);
    processor.roughness = 1;
    expect(processor.outerFrameNoiseAmplitude).to.equal(1.0);
    expect(processor.innerFrameNoiseAmplitude).to.equal(2.0);
  });
  
  it(@"should not update noise amplitude values on roughness change", ^{
    [processor process];
    processor.outerFrameNoiseAmplitude = 1.0;
    processor.innerFrameNoiseAmplitude = 2.0;
    expect(processor.outerFrameNoiseAmplitude).to.equal(1.0);
    expect(processor.innerFrameNoiseAmplitude).to.equal(2.0);
  });
});

context(@"processing", ^{
  beforeEach(^{
    cv::Mat4b greyPatch(32, 32, cv::Vec4b(128, 128, 128, 255));
    input = [LTTexture textureWithImage:greyPatch];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTImageBorderProcessor alloc] initWithInput:input output:output];
  });
  
  sit(@"should return outer frame with abrupt transition and no noise", ^{
    processor.outerFrameWidth = 25;
    processor.outerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    [processor process];
    
    LTTexture *precomputedResult =
       [LTTexture textureWithImage:LTLoadMat([self class], @"RedBorder.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  sit(@"should return outer frame with no noise on clear background", ^{
    [input clearWithColor:GLKVector4Zero];
    processor.outerFrameWidth = 25;
    processor.outerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"RedBorderOnClearBackground.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  sit(@"should return outer + inner frames with rounded corners on both frames", ^{
    processor.outerFrameWidth = 10;
    processor.outerFrameCorner = 15;
    processor.outerFrameColor = GLKVector3Make(0.0, 0.0, 1.0);
    processor.innerFrameWidth = 10;
    processor.innerFrameCorner = 15;
    processor.innerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"BlueRedBorderRoundedCorners.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
  
  sit(@"should return same result on same parameters, but different history", ^{
    // Create thick red frame.
    processor.outerFrameWidth = 25;
    processor.outerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    [processor process];
    
    LTTexture *alternativeOutput = [LTTexture textureWithPropertiesOf:input];
    LTImageBorderProcessor *anotherProcessor =
        [[LTImageBorderProcessor alloc] initWithInput:input output:alternativeOutput];
    // Create thin blue frame.
    anotherProcessor.outerFrameWidth = 10;
    anotherProcessor.outerFrameColor = GLKVector3Make(0.0, 1.0, 0.0);
    [anotherProcessor process];
    // Create thick red frame.
    anotherProcessor.outerFrameWidth = 25;
    anotherProcessor.outerFrameColor = GLKVector3Make(1.0, 0.0, 0.0);
    [anotherProcessor process];
    
    expect($(output.image)).to.beCloseToMat($(alternativeOutput.image));
  });
  
  sit(@"should return rectangular noisy frame with different degrees of roughness", ^{
    LTTexture *noise = [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
    noise.wrap = LTTextureWrapRepeat;
    // Outer frame.
    processor.outerFrameWidth = 10.0;
    processor.outerFrameSpread = 10.0;
    processor.outerFrameNoise = noise;
    processor.outerFrameNoiseAmplitude = 1.0;
    processor.outerFrameColor = GLKVector3Make(0.0, 0.0, 0.0);
    // Inner frame.
    processor.innerFrameWidth = 10.0;
    processor.innerFrameSpread = 5.0;
    processor.innerFrameNoise = noise;
    processor.innerFrameNoiseAmplitude = 1.0;
    processor.innerFrameNoiseChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);
    // Both.
    processor.roughness = 1.0;
    [processor process];
    
    LTTexture *precomputedResult =
        [LTTexture textureWithImage:LTLoadMat([self class], @"NoisyBorder.png")];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
    
    precomputedResult = [LTTexture textureWithImage:LTLoadMat([self class], @"SmoothBorder.png")];
    processor.roughness = -1.0;
    [processor process];
    expect($(output.image)).to.beCloseToMat($(precomputedResult.image));
  });
});

LTSpecEnd
