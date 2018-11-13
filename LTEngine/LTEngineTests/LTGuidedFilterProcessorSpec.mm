// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGuidedFilterProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTGuidedFilterProcessor)

context(@"initialization", ^{
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    input = nil;
    output = nil;
  });

  it(@"should fail initialization on zero scale factor", ^{
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:input
                                         downscaleFactor:0 kernelSize:3
                                                  output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on too small kernelSize parameter", ^{
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:input
                                         downscaleFactor:4 kernelSize:1
                                                  output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on too large kernelSize parameter", ^{
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:input
                                         downscaleFactor:4 kernelSize:1001
                                                  output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on even kernelSize parameter", ^{
    expect(^{
       LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:input
                                         downscaleFactor:4 kernelSize:30
                                                  output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid input texture format", ^{
    LTTexture *inputRG = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                        pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                     allocateMemory:YES];
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:inputRG
                                                   guide:input
                                         downscaleFactor:4 kernelSize:31
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail on invalid guide texture format", ^{
    LTTexture *guideRG = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                        pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                     allocateMemory:YES];
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:guideRG
                                         downscaleFactor:4 kernelSize:31
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should fail initialization on incorrect input and guide texture format combination", ^{
    LTTexture *guideR = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                       pixelFormat:$(LTGLPixelFormatR8Unorm)
                                    allocateMemory:YES];
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:guideR
                                         downscaleFactor:4 kernelSize:31
                                              output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize successfully with correct parameters", ^{
    expect(^{
      LTGuidedFilterProcessor __unused *guidedFilter =
          [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                   guide:input
                                         downscaleFactor:4 kernelSize:3
                                                  output:output];
    }).toNot.raiseAny();
  });
});

context(@"properties", ^{
  __block LTTexture *input;
  __block LTTexture *output;
  __block LTGuidedFilterProcessor *guidedFilter;

  beforeEach(^{
    input = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    guidedFilter = nil;
    input = nil;
    output = nil;
  });

  it(@"should fail on invalid smoothingDegree parameter", ^{
    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                            guide:input
                                                  downscaleFactor:4 kernelSize:31
                                                           output:output];
    expect(^{
      guidedFilter.smoothingDegree = 0;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not fail on correct input", ^{
    expect(^{
      guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                              guide:input
                                                    downscaleFactor:4 kernelSize:31
                                                             output:output];
      guidedFilter.smoothingDegree = 0.1;
    }).toNot.raiseAny();
  });
});

context(@"processing with guide equals input", ^{
  __block LTTexture *input;
  __block LTTexture *output;
  __block LTGuidedFilterProcessor *guidedFilter;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    output = [LTTexture textureWithPropertiesOf:input];
  });

  afterEach(^{
    guidedFilter = nil;
    input = nil;
    output = nil;
  });

  it(@"should process correctly on default parameters", ^{
    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input guide:input
                                                  downscaleFactor:1 kernelSize:9
                                                           output:output];
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterLenna128_R9S1.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should process correctly with smaller kernelSize", ^{
    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input guide:input
                                                  downscaleFactor:2 kernelSize:7
                                                           output:output];
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterLenna128_R7S2.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should produce similar result with higher downscaleFactor", ^{
    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input guide:input
                                                  downscaleFactor:2 kernelSize:9
                                                           output:output];
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterLenna128_R9S1.png");

    cv::Mat diff;
    cv::absdiff([output image], expected, diff);
    cv::Vec4d channelDiff = cv::sum(diff) / expected.rows / expected.cols;
    double allChannelDiff = (channelDiff[0] + channelDiff[1] + channelDiff[2]) / 3;
    expect(allChannelDiff).to.beCloseToWithin(0, 2);
  });

  it(@"should process correctly with larger smoothing degree", ^{
    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input guide:input
                                                  downscaleFactor:1 kernelSize:9
                                                           output:output];
    guidedFilter.smoothingDegree = 0.03;
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterLenna128_R9S1_Smooth.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should process correctly with non-square image", ^{
    LTTexture *nonSquareInput =
      [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterLenna67x128.png")];
    LTTexture *nonSquareOutput = [LTTexture textureWithPropertiesOf:nonSquareInput];

    guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:nonSquareInput
                                                            guide:nonSquareInput
                                                  downscaleFactor:3 kernelSize:7
                                                           output:nonSquareOutput];
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterLenna67x128_R7S3.png");
    expect($([nonSquareOutput image])).to.beCloseToMatPSNR($(expected), 47);
  });

  it(@"should not fail on one pixel image input", ^{
    LTTexture *onePixelInput = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    LTTexture *onePixelOutput = [LTTexture textureWithPropertiesOf:onePixelInput];

    expect(^{
      guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:onePixelInput
                                                              guide:onePixelInput
                                                    downscaleFactor:3 kernelSize:7
                                                             output:onePixelOutput];
      [guidedFilter process];
    }).toNot.raiseAny();
  });
});

context(@"processing with guide different from input", ^{
  dit(@"should process correctly with BW input and RGBA guide", ^{
    LTTexture *input =
        [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterBWMask.png")];
    LTTexture *guide =
        [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterInput.jpg")];

    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LTGuidedFilterProcessor *guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                                                     guide:guide
                                                                           downscaleFactor:4
                                                                                kernelSize:11
                                                                                    output:output];
    guidedFilter.smoothingDegree = 0.0001;
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterBWMaskResult.png");

    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  dit(@"should process correctly with different RGBA input and RGBA guide", ^{
    LTTexture *input =
        [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterAmphorasNoFlash.png")];
    LTTexture *guide =
        [LTTexture textureWithImage:LTLoadMat([self class], @"GuidedFilterAmphorasFlash.png")];

    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    LTGuidedFilterProcessor *guidedFilter = [[LTGuidedFilterProcessor alloc] initWithInput:input
                                                                                     guide:guide
                                                                           downscaleFactor:4
                                                                                kernelSize:9
                                                                                    output:output];
    guidedFilter.smoothingDegree = 0.001;
    [guidedFilter process];
    cv::Mat expected = LTLoadMat([self class], @"GuidedFilterAmphorasResult.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });
});

SpecEnd
