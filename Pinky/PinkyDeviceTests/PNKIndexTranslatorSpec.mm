// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKIndexTranslator.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKIndexTranslator)

static const NSUInteger kImageWidth = 8;
static const NSUInteger kImageHeight = 8;
static const NSUInteger kSingleChannel = 1;

__block id<MTLDevice> device;
__block PNKIndexTranslator *translator;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();

  std::array<uchar, 256> translationTable;
  for (int i = 0; i < 256; ++i) {
    translationTable[i] = (uchar)(255 - i);
  }

  translator = [[PNKIndexTranslator alloc] initWithDevice:device translationTable:translationTable];
});

afterEach(^{
  device = nil;
  translator = nil;
});

context(@"kernel input verification", ^{
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should raise an exception when output width differs from input width", ^{
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                   height:kImageHeight channels:kSingleChannel];
    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth - 1
                                                    height:kImageHeight channels:kSingleChannel];
    expect(^{
      [translator encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output height differs from input height", ^{
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                   height:kImageHeight channels:kSingleChannel];
    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                    height:kImageHeight - 1
                                                  channels:kSingleChannel];
    expect(^{
      [translator encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when input has more than one channel", ^{
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                   height:kImageHeight channels:2];
    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                    height:kImageHeight channels:kSingleChannel];
    expect(^{
      [translator encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when output has more than one channel", ^{
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                   height:kImageHeight channels:kSingleChannel];
    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:kImageWidth
                                                    height:kImageHeight channels:2];
    expect(^{
      [translator encodeToCommandBuffer:commandBuffer inputImage:inputImage
                            outputImage:outputImage];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"translation", ^{
  itShouldBehaveLike(kPNKUnaryKernelExamples, ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    cv::Mat rgbaImage = LTLoadMatFromBundle(bundle, @"Lena128.png");
    cv::Mat1b inputImage;
    cv::cvtColor(rgbaImage, inputImage, CV_RGBA2GRAY);
    cv::Mat1b expectedOutputImage = 255 - inputImage;

    return @{
      kPNKKernelExamplesKernel: translator,
      kPNKKernelExamplesDevice: device,
      kPNKKernelExamplesPixelFormat: @(MPSImageFeatureChannelFormatUnorm8),
      kPNKKernelExamplesOutputChannels: @1,
      kPNKKernelExamplesOutputWidth: @(expectedOutputImage.cols),
      kPNKKernelExamplesOutputHeight: @(expectedOutputImage.rows),
      kPNKKernelExamplesPrimaryInputMat: $(inputImage),
      kPNKKernelExamplesExpectedMat: $(expectedOutputImage)
    };
  });
});

context(@"kernel output size", ^{
  it(@"should calculate output size correctly", ^{
    MTLSize inputSize = {kImageWidth, kImageHeight, kSingleChannel};
    MTLSize expectedOutputSize = inputSize;
    MTLSize outputSize = [translator outputSizeForInputSize:inputSize];

    expect($(outputSize)).to.equalMTLSize($(expectedOutputSize));
  });

  it(@"should calculate input region correctly", ^{
    MTLSize outputSize = {kImageWidth, kImageHeight, kSingleChannel};
    MTLSize expectedInputSize = outputSize;
    MTLSize inputSize = [translator inputRegionForOutputSize:outputSize].size;

    expect($(inputSize)).to.equalMTLSize($(expectedInputSize));
  });
});

context(@"PNKUnaryKernel with MPSTemporaryImage", ^{
  itShouldBehaveLike(kPNKTemporaryImageUnaryExamples, ^{
    return @{
      kPNKTemporaryImageExamplesKernel: translator,
      kPNKTemporaryImageExamplesDevice: device,
      kPNKTemporaryImageExamplesInputChannels: @(kSingleChannel)
    };
  });
});
DeviceSpecEnd
