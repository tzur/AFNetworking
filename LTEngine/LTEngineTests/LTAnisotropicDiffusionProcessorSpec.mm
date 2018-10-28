// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTAnisotropicDiffusionProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

static LTTexture *LTAnisotropicDiffusionTestInput() {
  cv::Mat4b inputMat(4, 4);
  inputMat(cv::Rect(0, 0, 2, 2)).setTo(cv::Vec4b(255, 0, 0, 255));
  inputMat(cv::Rect(0, 2, 2, 2)).setTo(cv::Vec4b(0, 255, 0, 255));
  inputMat(cv::Rect(2, 0, 2, 2)).setTo(cv::Vec4b(0, 0, 255, 255));
  inputMat(cv::Rect(2, 2, 2, 2)).setTo(cv::Vec4b(255, 0, 255, 255));
  return [LTTexture textureWithImage:inputMat];
}

static LTTexture *LTAnisotropicDiffusionTestGuide() {
  cv::Mat4b guideMat(8, 8);
  guideMat(cv::Rect(0, 0, 4, 8)).setTo(cv::Vec4b(0, 0, 0, 255));
  guideMat(cv::Rect(4, 0, 4, 8)).setTo(cv::Vec4b(255, 255, 255, 255));
  return [LTTexture textureWithImage:guideMat];
}

SpecBegin(LTAnisotropicDiffusionProcessor)

context(@"initialization", ^{
  __block LTTexture *input;
  __block LTTexture *guide;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
    guide = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
    output = [LTTexture byteRedTextureWithSize:CGSizeMake(4, 4)];
  });

  afterEach(^{
    input = nil;
    guide = nil;
    output = nil;
  });

  it(@"should raise when input width is greater than the output width", ^{
    LTTexture *inputWithInvalidWidth = [LTTexture byteRGBATextureWithSize:CGSizeMake(9, 1)];
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:inputWithInvalidWidth guide:guide
                                                          output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input height is greater than the output height", ^{
    LTTexture *inputWithInvalidHeight = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 9)];
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:inputWithInvalidHeight guide:guide
                                                          output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input width is greater than the guide width", ^{
    LTTexture *inputWithInvalidWidth = [LTTexture byteRGBATextureWithSize:CGSizeMake(3, 1)];
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:inputWithInvalidWidth guide:guide
                                                          output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input height is greater than the guide height", ^{
    LTTexture *inputWithInvalidHeight = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 3)];
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:inputWithInvalidHeight guide:guide
                                                          output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when input and output pixel formats have different number of components", ^{
    LTTexture *outputWithInvalidPixelFormat = [LTTexture byteRGBATextureWithSize:output.size];
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input guide:guide
                                                          output:outputWithInvalidPixelFormat];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize without guide", ^{
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input output:output];
    }).notTo.raiseAny();
  });

  it(@"should initialize with guide", ^{
    expect(^{
      LTAnisotropicDiffusionProcessor __unused *processor =
          [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input guide:guide output:output];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  __block LTTexture *input;
  __block LTTexture *guide;
  __block LTTexture *output;
  __block LTAnisotropicDiffusionProcessor *processor;

  beforeEach(^{
    input = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
    guide = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
    output = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
    processor = [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input guide:guide
                                                                output:output];
  });

  afterEach(^{
    input = nil;
    guide = nil;
    output = nil;
    processor = nil;
  });

  context(@"range sigma", ^{
    it(@"should set default range sigma correctly", ^{
      expect(processor.rangeSigma).to.equal(0.1);
    });

    it(@"should raise when setting range sigma with a negative value", ^{
      expect(^{
        processor.rangeSigma = -0.1;
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when setting range sigma with zero", ^{
      expect(^{
        processor.rangeSigma = 0;
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"kernel size", ^{
    it(@"should set default kernel size correctly", ^{
      expect(processor.kernelSize).to.equal(15);
    });

    it(@"should raise when setting kernel size with 0", ^{
      expect(^{
        processor.kernelSize = 0;
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when setting kernel size with a value larger than kKernelSizeUpperBound", ^{
      expect(^{
        processor.kernelSize = kKernelSizeUpperBound + 2;
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when setting kernel size with an even number", ^{
      expect(^{
        processor.kernelSize = 2;
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"processing", ^{
  __block LTTexture *input;

  beforeEach(^{
    input = LTAnisotropicDiffusionTestInput();
  });

  afterEach(^{
    input = nil;
  });

  it(@"should apply non guided diffusion with different sigmas and kernel sizes correctly", ^{
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];
    LTAnisotropicDiffusionProcessor *processor =
        [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input output:output];

    processor.rangeSigma = 0.1;
    processor.kernelSize = 3;
    [processor process];
    cv::Mat4b expected =
        LTLoadMat([self class], @"LTAnisotropicDiffusion_non_guided_kernel_3_sigma_0_1.png");
    expect($([output image])).to.equalMat($(expected));

    processor.rangeSigma = 0.8;
    processor.kernelSize = 3;
    [processor process];
    expected =
        LTLoadMat([self class], @"LTAnisotropicDiffusion_non_guided_kernel_3_sigma_0_8.png");
    expect($([output image])).to.equalMat($(expected));

    processor.rangeSigma = 0.8;
    processor.kernelSize = 5;
    [processor process];
    expected =
        LTLoadMat([self class], @"LTAnisotropicDiffusion_non_guided_kernel_5_sigma_0_8.png");

    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);
  });

  it(@"should apply guided diffusion with different sigams and kernel sizes correctly", ^{
    LTTexture *guide = LTAnisotropicDiffusionTestGuide();
    LTTexture *output = [LTTexture textureWithPropertiesOf:guide];
    LTAnisotropicDiffusionProcessor *processor =
        [[LTAnisotropicDiffusionProcessor alloc] initWithInput:input guide:guide output:output];

    processor.rangeSigma = 0.1;
    processor.kernelSize = 3;
    [processor process];
    cv::Mat4b expected =
        LTLoadMat([self class], @"LTAnisotropicDiffusion_guided_kernel_3_sigma_0_1.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);

    processor.rangeSigma = 0.8;
    processor.kernelSize = 3;
    [processor process];
    expected = LTLoadMat([self class], @"LTAnisotropicDiffusion_guided_kernel_3_sigma_0_8.png");
    expect($([output image])).to.beCloseToMatPSNR($(expected), 50);

    processor.rangeSigma = 0.8;
    processor.kernelSize = 5;
    [processor process];
    expected = LTLoadMat([self class], @"LTAnisotropicDiffusion_guided_kernel_5_sigma_0_8.png");
    expect($([output image])).to.equalMat($(expected));
  });
});

SpecEnd
