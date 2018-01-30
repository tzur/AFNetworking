// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTemporaryImageExamples.h"

#import "PNKKernel.h"

NSString * const kPNKTemporaryImageUnaryExamples = @"PNKTemporaryImageUnaryExamples";
NSString * const kPNKTemporaryImageBinaryExamples = @"PNKTemporaryImageBinaryExamples";
NSString * const kPNKTemporaryImageExamplesKernel = @"PNKTemporaryImageExamplesKernel";
NSString * const kPNKTemporaryImageExamplesDevice = @"PNKTemporaryImageExamplesDevice";
NSString * const kPNKTemporaryImageExamplesInputChannels =
    @"PNKTemporaryImageExamplesInputChannels";

SharedExamplesBegin(PNKTemporaryImageExamples)

sharedExamplesFor(kPNKTemporaryImageUnaryExamples, ^(NSDictionary *data) {
  context(@"PNKUnaryKernel protocol", ^{
    it(@"should manage readCount properly upon consumption", ^{
      id<PNKUnaryKernel> unaryKernel = data[kPNKTemporaryImageExamplesKernel];
      id<MTLDevice> device = data[kPNKTemporaryImageExamplesDevice];
      NSUInteger inputChannels = [data[kPNKTemporaryImageExamplesInputChannels]
                                  unsignedIntegerValue];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      MTLSize inputSize{32, 32, inputChannels};
      auto outputSize = [unaryKernel outputSizeForInputSize:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      auto inputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                                               size:inputSize];
      expect(inputImage.readCount == 1);

      [unaryKernel encodeToCommandBuffer:commandBuffer inputImage:inputImage
                             outputImage:outputImage];
      expect(inputImage.readCount == 0);
    });
  });
});

sharedExamplesFor(kPNKTemporaryImageBinaryExamples, ^(NSDictionary *data) {
  context(@"PNKBinaryKernel protocol", ^{
    it(@"should manage readCount properly upon consumption", ^{
      id<PNKBinaryKernel> binaryKernel = data[kPNKTemporaryImageExamplesKernel];
      id<MTLDevice> device = data[kPNKTemporaryImageExamplesDevice];
      NSUInteger inputChannels = [data[kPNKTemporaryImageExamplesInputChannels]
                                  unsignedIntegerValue];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      MTLSize inputSize{32, 32, inputChannels};
      auto outputSize = [binaryKernel outputSizeForPrimaryInputSize:inputSize
                                                 secondaryInputSize:inputSize];
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device size:outputSize];
      auto primaryInputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                                               size:inputSize];
      expect(primaryInputImage.readCount == 1);

      auto secondaryInputImage = [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                                                 size:inputSize];;
      expect(secondaryInputImage.readCount == 1);

      [binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                      secondaryInputImage:secondaryInputImage outputImage:outputImage];
      expect(primaryInputImage.readCount == 0);
      expect(secondaryInputImage.readCount == 0);
    });
  });
});

SharedExamplesEnd
