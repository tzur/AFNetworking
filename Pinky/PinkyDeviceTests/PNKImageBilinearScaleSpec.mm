// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageBilinearScale.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKImageBilinearScale)

__block id<MTLDevice> device;
__block PNKImageBilinearScale *scale;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  scale = [[PNKImageBilinearScale alloc] initWithDevice:device];
});

afterEach(^{
  device = nil;
  scale = nil;
});

context(@"parameter tests", ^{
  context(@"encoding", ^{
    __block id<MTLCommandBuffer> commandBuffer;

    beforeEach(^{
      auto commandQueue = [device newCommandQueue];
      commandBuffer = [commandQueue commandBuffer];
    });

    afterEach(^{
      commandBuffer = nil;
    });

    it(@"should raise when called with illegal combination of channels count", ^{
      MTLSize inputSize{32, 32, 2};
      MTLSize outputSize{32, 32, 4};

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
  __block id<MTLCommandBuffer> commandBuffer;

  beforeEach(^{
    auto commandQueue = [device newCommandQueue];
    commandBuffer = [commandQueue commandBuffer];
  });

  afterEach(^{
    commandBuffer = nil;
  });

  it(@"should resize image correctly", ^{
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

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });

  it(@"should resize image and transform Y to RGBA correctly", ^{
    auto inputMatRGBA = LTLoadMat([self class], @"ResizeInput.png");
    cv::Mat inputMat;
    cv::cvtColor(inputMatRGBA, inputMat, cv::COLOR_RGBA2GRAY);

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
    cv::cvtColor(resizedInputMat, expectedMat, cv::COLOR_GRAY2RGBA);

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });

  it(@"should resize image and transform RGBA to Y correctly", ^{
    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputImage.width * 1.5
                                                    height:inputImage.height * 1.5 channels:1];

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat resizedInputMat;
    cv::resize(inputMat, resizedInputMat, cv::Size(0, 0), 1.5, 1.5);

    cv::Mat expectedMat;
    cv::cvtColor(resizedInputMat, expectedMat, cv::COLOR_RGBA2GRAY);

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });
});

context(@"temporary image read count", ^{
  it(@"should decrement read count of an input image of class MPSTemporaryImage", ^{
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
