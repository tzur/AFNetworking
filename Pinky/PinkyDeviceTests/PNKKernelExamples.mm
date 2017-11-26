// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKKernelExamples.h"

#import "PNKKernel.h"

NSString * const kPNKUnaryKernelExamples = @"PNKUnaryKernelExamples";
NSString * const kPNKBinaryKernelExamples = @"PNKBinaryKernelExamples";
NSString * const kPNKBinaryImageKernelExamples = @"PNKBinaryImageKernelExamples";
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

static void PNKCopyMatrixToImage(cv::Mat matrix, MPSImage *image) {
  auto matrixWithChannelsAsColumns = matrix.reshape(1, (int)matrix.total());

  int channelsPerSlice = (image.featureChannels <= 2) ? (int)image.featureChannels : 4;
  for (NSUInteger i = 0; i < image.texture.arrayLength; ++i) {
    cv::Rect roi((int)(i * channelsPerSlice), 0, channelsPerSlice, (int)matrix.total());
    cv::Mat slice = matrixWithChannelsAsColumns(roi).clone().reshape(channelsPerSlice, matrix.rows);
    PNKCopyMatToMTLTexture(image.texture, slice, i);
  }
}

static void PNKResetIrrelevantChannels(cv::Mat *matrix, int relevantChannels) {
  if (relevantChannels < matrix->channels()) {
    cv::Mat channelsAsColums = matrix->reshape(1, (int)matrix->total());
    channelsAsColums(cv::Rect(relevantChannels, 0, matrix->channels() - relevantChannels,
                              (int)matrix->total())) = 0;
  }
}

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
      PNKCopyMatrixToImage(inputMat, inputImage);

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      PNKCopyMatrixToImage(expectedMat, expectedImage);

      [unaryKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      for (NSUInteger i = 0; i < (outputChannels + 3) / 4; ++i) {
        int relevantChannels = std::min(4, (int)(outputChannels - i * 4));

        auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
        PNKResetIrrelevantChannels(&outputSlice, relevantChannels);

        auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
        PNKResetIrrelevantChannels(&expectedSlice, relevantChannels);

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
      PNKCopyMatrixToImage(primaryInputMat, primaryInputImage);

      auto secondaryInputMat = [data[kPNKKernelExamplesSecondaryInputMat] matValue];
      PNKCopyMatrixToImage(secondaryInputMat, secondaryInputImage);

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      PNKCopyMatrixToImage(expectedMat, expectedImage);

      [binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                      secondaryInputImage:secondaryInputImage outputImage:outputImage];
      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      for (NSUInteger i = 0; i < (outputChannels + 3) / 4; ++i) {
        int relevantChannels = std::min(4, (int)(outputChannels - i * 4));

        auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
        PNKResetIrrelevantChannels(&outputSlice, relevantChannels);

        auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
        PNKResetIrrelevantChannels(&expectedSlice, relevantChannels);

        expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
      }
    });
  });
});

sharedExamplesFor(kPNKBinaryImageKernelExamples, ^(NSDictionary *data) {
  context(@"PNKBinaryKernel protocol", ^{
    it(@"should encode correctly", ^{
      id<PNKBinaryImageKernel> binaryKernel = data[kPNKKernelExamplesKernel];
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
      PNKCopyMatrixToImage(primaryInputMat, primaryInputImage);

      auto secondaryInputMat = [data[kPNKKernelExamplesSecondaryInputMat] matValue];
      PNKCopyMatrixToImage(secondaryInputMat, secondaryInputImage);

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      PNKCopyMatrixToImage(expectedMat, expectedImage);

      [binaryKernel encodeToCommandBuffer:commandBuffer
                      primaryInputTexture:primaryInputImage.texture
                    secondaryInputTexture:secondaryInputImage.texture
                            outputTexture:outputImage.texture];

      [commandBuffer commit];
      [commandBuffer waitUntilCompleted];

      for (NSUInteger i = 0; i < (outputChannels + 3) / 4; ++i) {
        int relevantChannels = std::min(4, (int)(outputChannels - i * 4));

        auto outputSlice = PNKMatFromMTLTexture(outputImage.texture, i);
        PNKResetIrrelevantChannels(&outputSlice, relevantChannels);

        auto expectedSlice = PNKMatFromMTLTexture(expectedImage.texture, i);
        PNKResetIrrelevantChannels(&expectedSlice, relevantChannels);

        expect($(outputSlice)).to.beCloseToMatWithin($(expectedSlice), @(5e-2));
      }
    });
  });
});

SharedExamplesEnd
