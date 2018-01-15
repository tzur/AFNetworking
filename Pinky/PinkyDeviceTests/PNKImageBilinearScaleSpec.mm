// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageBilinearScale.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKImageBilinearScale)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

context(@"parameter tests", ^{
  __block PNKImageBilinearScale *scale;

  context(@"initialization", ^{
    it(@"should raise when called with illegal combination of channels count", ^{
      expect(^{
        scale = [[PNKImageBilinearScale alloc] initWithDevice:device inputFeatureChannels:2
                                        outputFeatureChannels:4];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"encoding", ^{
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      device = MTLCreateSystemDefaultDevice();
      scale = [[PNKImageBilinearScale alloc] initWithDevice:device inputFeatureChannels:4
                                      outputFeatureChannels:4];
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    it(@"should raise when input image channels count differs from value provided on "
       "initialization", ^{
      MTLSize inputSize{32, 32, 1};
      MTLSize outputSize{32, 32, 4};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage
                         outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output image channels count differs from value provided on "
       "initialization", ^{
      MTLSize inputSize{32, 32, 4};
      MTLSize outputSize{32, 32, 1};

      auto inputImage = [MPSImage pnk_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage
                         outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"resize", ^{
  __block PNKImageBilinearScale *scale;
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  it(@"should resize image correctly", ^{
    scale = [[PNKImageBilinearScale alloc] initWithDevice:device inputFeatureChannels:4
                                    outputFeatureChannels:4];

    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputImage.width * 2.5
                                                    height:inputImage.height * 2.5 channels:4];

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat expectedMat;
    cv::resize(inputMat, expectedMat, cv::Size(0, 0), 2.5, 2.5);

    expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), @1);
  });

  it(@"should resize image and transform Y to RGBA correctly", ^{
    scale = [[PNKImageBilinearScale alloc] initWithDevice:device inputFeatureChannels:1
                                    outputFeatureChannels:4];

    auto inputMatRGBA = LTLoadMat([self class], @"ResizeInput.png");
    cv::Mat inputMat;
    cv::cvtColor(inputMatRGBA, inputMat, CV_RGBA2GRAY);

    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputImage.width * 0.5
                                                    height:inputImage.height * 0.5 channels:4];

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat resizedInputMat;
    cv::resize(inputMat, resizedInputMat, cv::Size(0, 0), 0.5, 0.5);

    cv::Mat expectedMat;
    cv::cvtColor(resizedInputMat, expectedMat, CV_GRAY2RGBA);

    expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), @1);
  });
});

context(@"PNKTemporaryImageExamples", ^{
  it(@"should decrement read count of an input image of class MPSTemporaryImage", ^{
    auto scale = [[PNKImageBilinearScale alloc] initWithDevice:device inputFeatureChannels:4
                                        outputFeatureChannels:4];

    auto commandQueue = [device newCommandQueue];
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    MTLSize outputSize{32, 32, 4};
    auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];

    MTLSize inputSize{64, 64, 4};
    auto inputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                                      size:inputSize];
    expect(inputImage.readCount == 1);

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
    expect(inputImage.readCount == 0);
  });
});

DeviceSpecEnd
