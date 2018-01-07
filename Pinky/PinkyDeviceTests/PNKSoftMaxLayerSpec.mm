// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKSoftMaxLayer.h"

static const NSUInteger kImageWidth = 15;
static const NSUInteger kImageHeight = 16;
static const NSUInteger kFeatureChannels = 32;

DeviceSpecBegin(PNKSoftMaxLayer)

__block id<MTLDevice> device;
__block id<MTLCommandBuffer> commandBuffer;
__block PNKSoftMaxLayer *softMaxOp;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  commandBuffer = [commandQueue commandBuffer];
});

context(@"parameter tests", ^{
  context(@"encodeToCommandBuffer", ^{
    beforeEach(^{
      softMaxOp = [[PNKSoftMaxLayer alloc] initWithDevice:device];
    });

    it(@"should raise when input image width does not fit output image size", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth + 1, kImageHeight, kFeatureChannels};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [softMaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image height does not fit output image size", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth, kImageHeight + 1, kFeatureChannels};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [softMaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input image channel count does not fit output image channel count", ^{
      MTLSize inputSize{kImageWidth, kImageHeight, kFeatureChannels};
      MTLSize outputSize{kImageWidth , kImageHeight, kFeatureChannels + 1};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [softMaxOp encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"kernel input region", ^{
  beforeEach(^{
    softMaxOp = [[PNKSoftMaxLayer alloc] initWithDevice:device];
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kImageWidth, kImageHeight, kFeatureChannels};
    MTLRegion inputRegion = [softMaxOp inputRegionForOutputSize:outputSize];
    expect($(inputRegion.size)).to.equalMTLSize($(outputSize));
  });

  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kImageWidth, kImageHeight, kFeatureChannels};
    MTLSize outputSize = [softMaxOp outputSizeForInputSize:inputSize];
    expect($(inputSize)).to.equalMTLSize($(outputSize));
  });
});

context(@"tensorflow golden standard", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    softMaxOp = [[PNKSoftMaxLayer alloc] initWithDevice:device];

    auto inputMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"softmax_input.tensor");
    auto inputMat = inputMatSingleRow.reshape(kFeatureChannels, kImageHeight);

    auto expectedMatSingleRow =
        PNKLoadHalfFloatTensorFromBundleResource(bundle, @"softmax_output.tensor");
    auto expectedMat = expectedMatSingleRow.reshape(kFeatureChannels, kImageHeight);

    return @{
      kPNKKernelExamplesKernel: softMaxOp,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatFloat16),
      kPNKKernelExamplesOutputChannels: @(kFeatureChannels),
      kPNKKernelExamplesOutputWidth: @(expectedMat.cols),
      kPNKKernelExamplesOutputHeight: @(expectedMat.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputMat),
      kPNKKernelExamplesExpectedMat: $(expectedMat)
    };
  });
});

context(@"PNKTemporaryImageExamples", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    softMaxOp = [[PNKSoftMaxLayer alloc] initWithDevice:device];
    return @{
      kPNKTemporaryImageExamplesKernel: softMaxOp,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesOutputChannels: @(kFeatureChannels)
    };
  });
});

DeviceSpecEnd
