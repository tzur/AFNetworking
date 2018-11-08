// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageScale.h"

#import <LTEngine/LTOpenCVExtensions.h>

DeviceSpecBegin(PNKImageScale)

__block id<MTLDevice> device;
__block PNKImageScale *scale;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
  scale = [[PNKImageScale alloc] initWithDevice:device];
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
      auto inputSize = MTLSizeMake(32, 32, 2);
      auto outputSize = MTLSizeMake(32, 32, 4);

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];
      expect(^{
        [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage
                         outputImage:outputImage];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input region stretches beyond the input image", ^{
      auto inputSize = MTLSizeMake(32, 32, 1);
      auto outputSize = MTLSizeMake(32, 32, 1);

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];

      auto inputRegion = MTLRegionMake(1, 0, 0, inputSize);
      auto outputRegion = MTLRegionMake(0, 0, 0, outputSize);
      expect(^{
        [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage inputRegion:inputRegion
                         outputImage:outputImage outputRegion:outputRegion];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when output region stretches beyond the output image", ^{
      auto inputSize = MTLSizeMake(32, 32, 1);
      auto outputSize = MTLSizeMake(32, 32, 1);

      auto inputImage = [MPSImage mtb_float16ImageWithDevice:device size:inputSize];
      auto outputImage = [MPSImage mtb_float16ImageWithDevice:device size:outputSize];

      auto inputRegion = MTLRegionMake(0, 0, 0, inputSize);
      auto outputRegion = MTLRegionMake(1, 0, 0, outputSize);
      expect(^{
        [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage inputRegion:inputRegion
                         outputImage:outputImage outputRegion:outputRegion];
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
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width * 2.5
                                                    height:inputImage.height * 2.5 channels:4];

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat expectedMat;
    cv::resize(inputMat, expectedMat, cv::Size(0, 0), 2.5, 2.5);

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });

  it(@"should resize a region of image correctly", ^{
    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    cv::Rect cvRect(0.3 * inputImage.width, 0.3 * inputImage.height, 0.3 * inputImage.width,
                    0.3 * inputImage.height);
    auto inputRegion = MTLRegionMake(cvRect.x, cvRect.y, 0, cvRect.width, cvRect.height,
                                     inputImage.featureChannels);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width * 2.5
                                                    height:inputImage.height * 2.5 channels:4];

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage inputRegion:inputRegion
                     outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat expectedMat;
    cv::resize(inputMat(cvRect), expectedMat,
               cv::Size((int)outputImage.width, (int)outputImage.height));

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });

  it(@"should resize to a region of image correctly", ^{
    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);
    auto inputRegion = MTLRegionMake(0, 0, 0, inputImage.pnk_size);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width * 2.5
                                                    height:inputImage.height * 2.5 channels:4];
    cv::Rect cvRect(0.3 * outputImage.width, 0.3 * outputImage.height, 0.3 * outputImage.width,
                    0.3 * outputImage.height);
    auto outputRegion = MTLRegionMake(cvRect.x, cvRect.y, 0, cvRect.width, cvRect.height, 1);

    [scale encodeToCommandBuffer:commandBuffer inputImage:inputImage inputRegion:inputRegion
                     outputImage:outputImage outputRegion:outputRegion];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTextureRegion(outputImage.texture, outputRegion);

    cv::Mat expectedMat;
    cv::resize(inputMat, expectedMat, cv::Size(cvRect.width, cvRect.height));

    expect($(outputMat)).to.beCloseToMat($(expectedMat));
  });

  it(@"should resize image and transform Y to RGBA correctly", ^{
    auto inputMatRGBA = LTLoadMat([self class], @"ResizeInput.png");
    cv::Mat inputMat;
    cv::cvtColor(inputMatRGBA, inputMat, cv::COLOR_RGBA2GRAY);

    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width * 0.5
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
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];
    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputImage.width * 1.5
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

  it(@"should upscale with nearest neighbor interpolation correctly", ^{
    static const CGFloat kScaleFactor = 1.43;

    auto nearestNeighborScale = [[PNKImageScale alloc] initWithDevice:device
                                 interpolation:PNKInterpolationTypeNearestNeighbor];

    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];

    int outputWidth = inputImage.width * kScaleFactor;
    int outputHeight = inputImage.height * kScaleFactor;

    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:outputWidth
                                                    height:outputHeight channels:4];

    [nearestNeighborScale encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                    outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat expectedMat;
    cv::resize(inputMat, expectedMat, cv::Size(outputWidth, outputHeight), 0, 0, cv::INTER_NEAREST);

    expect($(outputMat)).to.equalMat($(expectedMat));
  });

  it(@"should downscale with nearest neighbor interpolation correctly", ^{
    static const CGFloat kScaleFactor = 0.37;

    auto nearestNeighborScale = [[PNKImageScale alloc] initWithDevice:device
                                 interpolation:PNKInterpolationTypeNearestNeighbor];

    auto inputMat = LTLoadMat([self class], @"ResizeInput.png");
    auto inputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:inputMat.cols
                                                   height:inputMat.rows
                                                 channels:inputMat.channels()];

    int outputWidth = inputImage.width * kScaleFactor;
    int outputHeight = inputImage.height * kScaleFactor;

    PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

    auto outputImage = [MPSImage mtb_unorm8ImageWithDevice:device width:outputWidth
                                                    height:outputHeight channels:4];

    [nearestNeighborScale encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                    outputImage:outputImage];

    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    auto outputMat = PNKMatFromMTLTexture(outputImage.texture);

    cv::Mat expectedMat;
    cv::resize(inputMat, expectedMat, cv::Size(outputWidth, outputHeight), 0, 0, cv::INTER_NEAREST);

    expect($(outputMat)).to.equalMat($(expectedMat));
  });
});

DeviceSpecEnd
