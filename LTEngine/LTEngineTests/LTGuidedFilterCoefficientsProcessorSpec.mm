// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGuidedFilterCoefficientsProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTGuidedFilterCoefficientsProcessor)

context(@"initialization", ^{
  __block LTTexture *input;
  __block LTTexture *scaleCoefficients;
  __block LTTexture *shiftCoefficients;

  beforeEach(^{
    input = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 4)];
    scaleCoefficients = [LTTexture textureWithPropertiesOf:input];
    shiftCoefficients = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    input = nil;
    scaleCoefficients = nil;
    shiftCoefficients = nil;
  });

  it(@"should fail initialization on nil input", ^{
    LTTexture *nilInput = nil;
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:nilInput
                                                               guide:nilInput
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{3}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on nil scaleCoefficients", ^{
    NSArray *nilScaleCoefficients = nil;
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:nilScaleCoefficients
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{3}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on nil shiftCoefficients", ^{
    NSArray *nilShiftCoefficients = nil;
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:nilShiftCoefficients
                                                         kernelSizes:{3}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on even kernelSize", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
      [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                           guide:input
                                               scaleCoefficients:@[scaleCoefficients]
                                               shiftCoefficients:@[shiftCoefficients]
                                                     kernelSizes:{10}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on too small kernelSize", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
      [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                           guide:input
                                               scaleCoefficients:@[scaleCoefficients]
                                               shiftCoefficients:@[shiftCoefficients]
                                                     kernelSizes:{1}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on too large kernelSize", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{1001}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect sizes of coefficients arrays", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients,
                                                                       scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect sizes of coefficients textures", ^{
    LTTexture *smallScaleCoefficients =
        [LTTexture byteRGBATextureWithSize:std::ceil(input.size / 2)];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[smallScaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on non equal sizes of coefficients textures", ^{
    LTTexture *smallScaleCoefficients =
        [LTTexture byteRGBATextureWithSize:std::ceil(input.size / 2)];
    LTTexture *smallShiftCoefficients =
        [LTTexture byteRGBATextureWithSize:std::ceil(input.size / 2)];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients,
                                                                       smallScaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients,
                                                                       smallShiftCoefficients]
                                                         kernelSizes:{11, 11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect length of kernelSizes array", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11, 13}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect input texture channels count", ^{
    LTTexture *inputRG = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                        pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                     allocateMemory:YES];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:inputRG
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect guide texture channels count", ^{
    LTTexture *guideRG = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                        pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                     allocateMemory:YES];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:guideRG
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect input and guide texture format combination", ^{
    LTTexture *guideR = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                       pixelFormat:$(LTGLPixelFormatR8Unorm)
                                    allocateMemory:YES];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:guideR
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on scale coefficients with different texture components from the"
     @"input's",^{
    LTTexture *scaleCoefficientsR = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                                   pixelFormat:$(LTGLPixelFormatR8Unorm)
                                                allocateMemory:YES];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficientsR]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on shift coefficients with different texture components from the"
     @"input's",^{
     LTTexture *shiftCoefficientsR = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                                    pixelFormat:$(LTGLPixelFormatR8Unorm)
                                                 allocateMemory:YES];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficientsR]
                                                         kernelSizes:{11}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize successfully with correct parameters", ^{
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{33}];
    }).toNot.raiseAny();
  });

  it(@"should initialize successfully with downscaled coefficients", ^{
    LTTexture *smallScaleCoefficients =
        [LTTexture byteRGBATextureWithSize:std::ceil(input.size / 2)];
    LTTexture *smallShiftCoefficients =
        [LTTexture textureWithPropertiesOf:smallScaleCoefficients];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[smallScaleCoefficients]
                                                   shiftCoefficients:@[smallShiftCoefficients]
                                                         kernelSizes:{5}];
    }).toNot.raiseAny();
  });

  it(@"should fail initialization with guide different from input and coefficients of wrong "
     @"format", ^{
    LTTexture *guide = [LTTexture byteRGBATextureWithSize:input.size];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:guide
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{5}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize successfully with guide different from input", ^{
    LTTexture *floatScaleCoefficients = [LTTexture textureWithSize:input.size
                                                       pixelFormat:$(LTGLPixelFormatRGBA16Float)
                                                    allocateMemory:YES];
    LTTexture *floatShiftCoefficients =
        [LTTexture textureWithPropertiesOf:floatScaleCoefficients];
    LTTexture *guide = [LTTexture byteRGBATextureWithSize:input.size];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:guide
                                                   scaleCoefficients:@[floatScaleCoefficients]
                                                   shiftCoefficients:@[floatShiftCoefficients]
                                                         kernelSizes:{5}];
    }).toNot.raiseAny();
  });

  it(@"should initialize successfully with RGBA guide and BW input", ^{
    LTTexture *floatScaleCoefficients = [LTTexture textureWithSize:input.size
                                                       pixelFormat:$(LTGLPixelFormatR16Float)
                                                    allocateMemory:YES];
    LTTexture *floatShiftCoefficients =
        [LTTexture textureWithPropertiesOf:floatScaleCoefficients];
    LTTexture *guide = [LTTexture byteRGBATextureWithSize:input.size];
    LTTexture *bwInput = [LTTexture byteRedTextureWithSize:input.size];
    expect(^{
      LTGuidedFilterCoefficientsProcessor __unused *guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:bwInput
                                                               guide:guide
                                                   scaleCoefficients:@[floatScaleCoefficients]
                                                   shiftCoefficients:@[floatShiftCoefficients]
                                                         kernelSizes:{5}];
    }).toNot.raiseAny();
  });
});

context(@"properties", ^{
  __block LTGuidedFilterCoefficientsProcessor *guidedFilterCoefficientsProcessor;

  beforeEach(^{
    LTTexture *input = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
    LTTexture *scaleCoefficients = [LTTexture textureWithPropertiesOf:input];
    LTTexture *shiftCoefficients = [LTTexture textureWithPropertiesOf:input];
    guidedFilterCoefficientsProcessor =
        [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                             guide:input
                                                 scaleCoefficients:@[scaleCoefficients]
                                                 shiftCoefficients:@[shiftCoefficients]
                                                       kernelSizes:{3}];
  });

  afterEach(^{
    guidedFilterCoefficientsProcessor = nil;
  });

  it(@"should fail on invalid smoothingDegree parameter", ^{
    expect(^{
      guidedFilterCoefficientsProcessor.smoothingDegree = 0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not fail on correct input", ^{
    expect(^{
      guidedFilterCoefficientsProcessor.smoothingDegree = 0.1;
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  __block LTTexture *input;
  __block LTTexture *scaleCoefficients;
  __block LTTexture *shiftCoefficients;
  __block LTGuidedFilterCoefficientsProcessor *guidedFilterCoefficientsProcessor;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
  });

  afterEach(^{
    guidedFilterCoefficientsProcessor = nil;
    input = nil;
    scaleCoefficients = nil;
    shiftCoefficients = nil;
  });

  it(@"should process correctly on 1:1 scale", ^{
    scaleCoefficients = [LTTexture textureWithPropertiesOf:input];
    shiftCoefficients = [LTTexture textureWithPropertiesOf:scaleCoefficients];
    guidedFilterCoefficientsProcessor =
        [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                             guide:input
                                                 scaleCoefficients:@[scaleCoefficients]
                                                 shiftCoefficients:@[shiftCoefficients]
                                                       kernelSizes:{9}];
    [guidedFilterCoefficientsProcessor process];
    cv::Mat expectedScale = LTLoadMat([self class], @"GuidedFilterLenna128_R9S1_Scale.png");
    cv::Mat expectedShift = LTLoadMat([self class], @"GuidedFilterLenna128_R9S1_Shift.png");
    expect($([scaleCoefficients image])).to.equalMat($(expectedScale));
    expect($([shiftCoefficients image])).to.equalMat($(expectedShift));
  });

  it(@"should process correctly with downscaled coefficients", ^{
    scaleCoefficients = [LTTexture byteRGBATextureWithSize:input.size / 2];
    shiftCoefficients = [LTTexture textureWithPropertiesOf:scaleCoefficients];
    guidedFilterCoefficientsProcessor =
        [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                             guide:input
                                                 scaleCoefficients:@[scaleCoefficients]
                                                 shiftCoefficients:@[shiftCoefficients]
                                                       kernelSizes:{7}];
    [guidedFilterCoefficientsProcessor process];
    cv::Mat expectedScale = LTLoadMat([self class], @"GuidedFilterLenna128_R7S2_Scale.png");
    cv::Mat expectedShift = LTLoadMat([self class], @"GuidedFilterLenna128_R7S2_Shift.png");
    expect($([scaleCoefficients image])).to.equalMat($(expectedScale));
    expect($([shiftCoefficients image])).to.equalMat($(expectedShift));
  });

  it(@"should process correctly with coefficients aspect ratio a bit different from input", ^{
    LTTexture *nonSquareInput =
        [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterLenna67x128.png")];

    scaleCoefficients = [LTTexture byteRGBATextureWithSize:std::ceil(nonSquareInput.size / 3)];
    shiftCoefficients = [LTTexture textureWithPropertiesOf:scaleCoefficients];
    guidedFilterCoefficientsProcessor =
        [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:nonSquareInput
                                                             guide:nonSquareInput
                                                 scaleCoefficients:@[scaleCoefficients]
                                                 shiftCoefficients:@[shiftCoefficients]
                                                       kernelSizes:{7}];
    [guidedFilterCoefficientsProcessor process];
    cv::Mat expectedScale = LTLoadMat([self class], @"GuidedFilterLenna67x128_R7S3_Scale.png");
    cv::Mat expectedShift = LTLoadMat([self class], @"GuidedFilterLenna67x128_R7S3_Shift.png");
    expect($([scaleCoefficients image])).to.equalMat($(expectedScale));
    expect($([shiftCoefficients image])).to.equalMat($(expectedShift));
  });

  it(@"shouldn't raise exceptions when processing with coefficients with aspect ratio very "
     "different from input", ^{
    scaleCoefficients = [LTTexture byteRGBATextureWithSize:CGSizeMake(input.size.width, 1)];
    shiftCoefficients = [LTTexture textureWithPropertiesOf:scaleCoefficients];
    expect(^{
      guidedFilterCoefficientsProcessor =
          [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                               guide:input
                                                   scaleCoefficients:@[scaleCoefficients]
                                                   shiftCoefficients:@[shiftCoefficients]
                                                         kernelSizes:{7}];
      [guidedFilterCoefficientsProcessor process];
    }).toNot.raiseAny();
  });
});

SpecEnd
