// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKKernelExamples.h"

#import "PNKKernel.h"

NSString * const kPNKUnaryKernelExamples = @"PNKUnaryKernelExamples";
NSString * const kPNKParametricUnaryKernelExamples = @"PNKParametricUnaryKernelExamples";
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
NSString * const kPNKKernelExamplesInputParameters = @"PNKKernelExamplesInputParameters";
NSString * const kPNKKernelExamplesExpectedMat = @"PNKKernelExamplesExpectedMat";
NSString * const kPNKKernelExamplesInputImageSizeFromInputMat =
    @"PNKKernelExamplesInputImageSizeFromInputMat";

static void PNKCopyMatrixToImage(cv::Mat matrix, MPSImage *image) {
  int total = (int)matrix.total();
  auto matrixWithChannelsAsColumns = matrix.reshape(1, total);

  int channelsPerSlice = (image.featureChannels <= 2) ? (int)image.featureChannels : 4;
  for (NSUInteger i = 0; i < image.texture.arrayLength; ++i) {
    int relevantChannels = std::min(channelsPerSlice,
                                    (int)(image.featureChannels - i * channelsPerSlice));
    cv::Mat slice(total, channelsPerSlice, matrix.depth());
    cv::Rect sourceROI((int)(i * channelsPerSlice), 0, relevantChannels, total);
    cv::Rect destinationROI(0, 0, relevantChannels, total);
    matrixWithChannelsAsColumns(sourceROI).copyTo(slice(destinationROI));
    PNKCopyMatToMTLTexture(image.texture, slice.reshape(channelsPerSlice, matrix.rows), i);
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

      auto inputMat = [data[kPNKKernelExamplesPrimaryInputMat] matValue];
      BOOL inputImageSizeFromInputMat =
      [data[kPNKKernelExamplesInputImageSizeFromInputMat] boolValue];
      MTLSize inputSize;
      if (inputImageSizeFromInputMat) {
        inputSize = {
          (NSUInteger)inputMat.cols,
          (NSUInteger)inputMat.rows,
          (NSUInteger)inputMat.channels()
        };
      } else {
        auto inputRegion = [unaryKernel inputRegionForOutputSize:outputSize];
        inputSize = inputRegion.size;
      }

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      auto inputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];
      auto expectedImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];

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

sharedExamplesFor(kPNKParametricUnaryKernelExamples, ^(NSDictionary *data) {
  context(@"PNKParametricUnaryKernel protocol", ^{
    it(@"should encode correctly", ^{
      id<PNKParametricUnaryKernel> parametricUnaryKernel = data[kPNKKernelExamplesKernel];
      id<MTLDevice> device = data[kPNKKernelExamplesDevice];
      MPSImageFeatureChannelFormat pixelFormat =
          (MPSImageFeatureChannelFormat)[data[kPNKKernelExamplesPixelFormat] unsignedIntegerValue];
      NSUInteger outputChannels = [data[kPNKKernelExamplesOutputChannels] unsignedIntegerValue];
      NSUInteger outputWidth = [data[kPNKKernelExamplesOutputWidth] unsignedIntegerValue];
      NSUInteger outputHeight = [data[kPNKKernelExamplesOutputHeight] unsignedIntegerValue];

      MTLSize outputSize{outputWidth, outputHeight, outputChannels};

      auto inputMat = [data[kPNKKernelExamplesPrimaryInputMat] matValue];
      BOOL inputImageSizeFromInputMat =
          [data[kPNKKernelExamplesInputImageSizeFromInputMat] boolValue];
      MTLSize inputSize;
      if (inputImageSizeFromInputMat) {
        inputSize = {
          (NSUInteger)inputMat.cols,
          (NSUInteger)inputMat.rows,
          (NSUInteger)inputMat.channels()
        };
      } else {
        auto inputRegion = [parametricUnaryKernel inputRegionForOutputSize:outputSize];
        inputSize = inputRegion.size;
      }

      NSDictionary *inputParameters = data[kPNKKernelExamplesInputParameters];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      auto inputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:inputSize];
      auto outputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];
      auto expectedImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];

      PNKCopyMatrixToImage(inputMat, inputImage);

      auto expectedMat = [data[kPNKKernelExamplesExpectedMat] matValue];
      PNKCopyMatrixToImage(expectedMat, expectedImage);

      [parametricUnaryKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                                   inputParameters:inputParameters outputImage:outputImage];
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

      auto primaryInputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat
                                                       width:primaryInputRegion.size.width
                                                      height:primaryInputRegion.size.height
                                                    channels:primaryInputChannels];
      auto secondaryInputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat
                                                         width:secondaryInputRegion.size.width
                                                        height:secondaryInputRegion.size.height
                                                      channels:secondaryInputChannels];
      auto outputImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];
      auto expectedImage = [MPSImage mtb_imageWithDevice:device format:pixelFormat size:outputSize];

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

SharedExamplesEnd
