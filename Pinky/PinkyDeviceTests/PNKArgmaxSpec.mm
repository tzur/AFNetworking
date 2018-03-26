// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKArgmax.h"

static const NSUInteger kImageWidth = 16;
static const NSUInteger kImageHeight = 15;
static const NSUInteger kFeatureChannels = 32;

static NSDictionary *PNKBuildUnormDataForKernelExamples(id<MTLDevice> device, NSUInteger channels) {
  auto kernel = [[PNKArgmax alloc] initWithDevice:device];

  cv::Mat inputMatSingleChannel = cv::Mat((int)(kImageWidth * kImageHeight), (int)channels, CV_8U);
  cv::Mat expectedMatSingleChannel = cv::Mat((int)(kImageWidth * kImageHeight), 1, CV_8U);

  // Each pixel of the input matrix will have channel values of <tt>0, 1, ... channels - 1</tt> with
  // some cyclic permutation.
  for (int i = 0; i < inputMatSingleChannel.rows; i++) {
    for (int j = 0; j < (int)channels; j++) {
      inputMatSingleChannel.at<uchar>(i, j) = (uchar)((i + j) % channels);
      if (inputMatSingleChannel.at<uchar>(i, j) == (uchar)(channels - 1)) {
        expectedMatSingleChannel.at<uchar>(i, 0) = (uchar)j;
      }
    }
  }

  cv::Mat inputMat =  inputMatSingleChannel.reshape((int)channels, (int)kImageHeight);
  cv::Mat expectedMat =  expectedMatSingleChannel.reshape(1, (int)kImageHeight);

  return @{
    kPNKKernelExamplesKernel: kernel,
    kPNKKernelExamplesDevice: device,
    kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
    kPNKKernelExamplesOutputChannels: @1,
    kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
    kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
    kPNKKernelExamplesPrimaryInputMat: $(inputMat),
    kPNKKernelExamplesExpectedMat: $(expectedMat),
    kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
  };
}

DeviceSpecBegin(PNKArgmax)

__block id<MTLDevice> device;
__block PNKArgmax *argmaxOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  argmaxOp = [[PNKArgmax alloc] initWithDevice:device];
});

afterEach(^{
  device = nil;
  argmaxOp = nil;
});

context(@"parameter tests", ^{
  context(@"encodeToCommandBuffer", ^{
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    afterEach(^{
      commandBuffer = nil;
    });

    it(@"should raise when input image width does not fit output image width", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth + 1, kImageHeight, kFeatureChannels};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [argmaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image height does not fit output image height", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth, kImageHeight + 1, kFeatureChannels};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [argmaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image has more than one channel", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth , kImageHeight, 2};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [argmaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image has more than 256 channels and output image has unorm8 "
       "pixel format", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, 260};
      MTLSize outputSize{kImageWidth , kImageHeight, 1};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device size:outputSize];
      expect(^{
        [argmaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kImageWidth, kImageHeight, kFeatureChannels};
    MTLRegion inputRegion = [argmaxOp inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kImageWidth, kImageHeight, kFeatureChannels};
    MTLSize expectedSize = {kImageWidth, kImageHeight, 1};
    MTLSize outputSize = [argmaxOp outputSizeForInputSize:inputSize];
    expect($(outputSize)).to.equalMTLSize($(expectedSize));
  });
});

context(@"argmax operation with Unorm8 channel format", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, 4);
  });

  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    return PNKBuildUnormDataForKernelExamples(device, kFeatureChannels);
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    auto inputMat = PNKLoadStructuredHalfFloatTensorFromResource(bundle,
                                                                 @"argmax_input_15x16x32.tensor");
    auto expectedMat =
        PNKLoadStructuredHalfFloatTensorFromResource(bundle, @"argmax_output_15x16x1.tensor");

    return @{
      kPNKKernelExamplesKernel: argmaxOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(expectedMat.channels()),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat),
      kPNKKernelExamplesInputImageSizeFromInputMat: @(YES)
    };
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    return @{
      kPNKTemporaryImageExamplesKernel: argmaxOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kFeatureChannels)
    };
  });
});

DeviceSpecEnd
