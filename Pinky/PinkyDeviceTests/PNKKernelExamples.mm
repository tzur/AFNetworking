// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKKernelExamples.h"

#import "PNKKernel.h"

NSString * const kPNKUnaryKernelExamples = @"PNKUnaryKernelExamples";
NSString * const kPNKBinaryKernelExamples = @"PNKBinaryKernelExamples";
NSString * const kPNKKernelExamplesKernel = @"PNKKernelExamplesKernel";
NSString * const kPNKKernelExamplesDevice = @"PNKKernelExamplesDevice";
NSString * const kPNKKernelExamplesPixelFormat = @"PNKKernelExamplesPixelFormat";
NSString * const kPNKKernelExamplesPrimaryInputChannels = @"PNKKernelExamplesPrimaryInputChannels";
NSString * const kPNKKernelExamplesSecondaryInputChannels =
    @"PNKKernelExamplesSecondaryInputChannels";
NSString * const kPNKKernelExamplesOutputChannels = @"PNKKernelExamplesOutputChannels";
NSString * const kPNKKernelExamplesOutputWidth = @"PNKKernelExamplesOutputWidth";
NSString * const kPNKKernelExamplesOutputHeight = @"PNKKernelExamplesOutputHeight";
NSString * const kPNKKernelExamplesPrimaryInputMat = @"PNKKernelExamplesPrimaryInputMat";
NSString * const kPNKKernelExamplesSecondaryInputMat = @"PNKKernelExamplesSecondaryInputMat";
NSString * const kPNKKernelExamplesExpectedMat = @"PNKKernelExamplesExpectedMat";

SharedExamplesBegin(PNKKernelExamples)

sharedExamplesFor(kPNKUnaryKernelExamples, ^(NSDictionary *data) {
  context(@"PNKUnaryKernel protocol", ^{
    it(@"should encode correctly", ^{
      id<PNKUnaryKernel> unaryKernel = data[kPNKKernelExamplesKernel];
      id<MTLDevice> device = data[kPNKKernelExamplesDevice];
      MPSImageFeatureChannelFormat pixelFormat =
          (MPSImageFeatureChannelFormat)[data[kPNKKernelExamplesPixelFormat] unsignedIntegerValue];
      NSUInteger outputChannels = [data[kPNKKernelExamplesOutputChannels] unsignedIntegerValue];
      NSUInteger outputWidth = [data[kPNKKernelExamplesOutputWidth] unsignedIntegerValue];
      NSUInteger outputHeight = [data[kPNKKernelExamplesOutputHeight] unsignedIntegerValue];

      MTLSize outputSize{outputWidth, outputHeight, outputChannels};
      auto inputRegion = [unaryKernel inputRegionForOutputSize:outputSize];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      auto inputImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat
                                                 size:inputRegion.size];
      auto outputImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat size:outputSize];
      auto expectedImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat size:outputSize];

      auto inputMat = [data[kPNKKernelExamplesPrimaryInputMat] matValue];
      auto elementsPerSlice = inputImage.width * inputImage.height * 4;
      for (NSUInteger i = 0; i < inputImage.texture.arrayLength; ++i) {
        cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
        PNKCopyMatToMTLTexture(inputImage.texture,
                               inputMat(roi).reshape(4, (int)inputImage.height), i);
      }

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      elementsPerSlice = expectedImage.width * expectedImage.height * 4;
      for (NSUInteger i = 0; i < expectedImage.texture.arrayLength; ++i) {
        cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
        PNKCopyMatToMTLTexture(expectedImage.texture,
                               expectedMat(roi).reshape(4, (int)expectedImage.height), i);
      }

      [unaryKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      for (NSUInteger i = 0; i < outputChannels / 4; ++i) {
        auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
        auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
        expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
      }
    });
  });
});

sharedExamplesFor(kPNKBinaryKernelExamples, ^(NSDictionary *data) {
  context(@"PNKBinaryKernel protocol", ^{
    it(@"should encode correctly", ^{
      id<PNKBinaryKernel> binaryKernel = data[kPNKKernelExamplesKernel];
      id<MTLDevice> device = data[kPNKKernelExamplesDevice];
      MPSImageFeatureChannelFormat pixelFormat =
          (MPSImageFeatureChannelFormat)[data[kPNKKernelExamplesPixelFormat] unsignedIntegerValue];
      NSUInteger primaryInputChannels =
          [data[kPNKKernelExamplesPrimaryInputChannels] unsignedIntegerValue];
      NSUInteger secondaryInputChannels =
          [data[kPNKKernelExamplesSecondaryInputChannels] unsignedIntegerValue];
      NSUInteger outputChannels = [data[kPNKKernelExamplesOutputChannels] unsignedIntegerValue];
      NSUInteger outputWidth = [data[kPNKKernelExamplesOutputWidth] unsignedIntegerValue];
      NSUInteger outputHeight = [data[kPNKKernelExamplesOutputHeight] unsignedIntegerValue];

      MTLSize outputSize{outputWidth, outputHeight, outputChannels};
      auto primaryInputRegion = [binaryKernel primaryInputRegionForOutputSize:outputSize];
      auto secondaryInputRegion = [binaryKernel secondaryInputRegionForOutputSize:outputSize];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      auto primaryInputImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat
                                                       width:primaryInputRegion.size.width
                                                      height:primaryInputRegion.size.height
                                                    channels:primaryInputChannels];
      auto secondaryInputImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat
                                                         width:secondaryInputRegion.size.width
                                                        height:secondaryInputRegion.size.height
                                                      channels:secondaryInputChannels];
      auto outputImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat size:outputSize];
      auto expectedImage = [MPSImage pnk_imageWithDevice:device format:pixelFormat size:outputSize];

      auto primaryInputMat = [data[kPNKKernelExamplesPrimaryInputMat] matValue];
      auto elementsPerSlice = primaryInputImage.width * primaryInputImage.height * 4;
      for (NSUInteger i = 0; i < primaryInputImage.texture.arrayLength; ++i) {
        cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
        PNKCopyMatToMTLTexture(primaryInputImage.texture,
                               primaryInputMat(roi).reshape(4, (int)primaryInputImage.height), i);
      }

      auto secondaryInputMat = [data[kPNKKernelExamplesSecondaryInputMat] matValue];
      elementsPerSlice = secondaryInputImage.width * secondaryInputImage.height * 4;
      for (NSUInteger i = 0; i < secondaryInputImage.texture.arrayLength; ++i) {
        cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
        PNKCopyMatToMTLTexture(secondaryInputImage.texture,
                               secondaryInputMat(roi).reshape(4, (int)secondaryInputImage.height),
                               i);
      }

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      elementsPerSlice = expectedImage.width * expectedImage.height * 4;
      for (NSUInteger i = 0; i < expectedImage.texture.arrayLength; ++i) {
        cv::Rect roi((int)(i * elementsPerSlice), 0, (int)elementsPerSlice, 1);
        PNKCopyMatToMTLTexture(expectedImage.texture,
                               expectedMat(roi).reshape(4, (int)expectedImage.height), i);
      }

      [binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                      secondaryInputImage:secondaryInputImage outputImage:outputImage];
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      for (NSUInteger i = 0; i < outputChannels / 4; ++i) {
        auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
        auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
        expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
      }
    });
  });
});

SharedExamplesEnd
