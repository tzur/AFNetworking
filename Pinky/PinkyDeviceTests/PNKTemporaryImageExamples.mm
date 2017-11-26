// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTemporaryImageExamples.h"

#import "PNKKernel.h"

NSString * const kPNKTemporaryImageUnaryExamples = @"PNKTemporaryImageUnaryExamples";
NSString * const kPNKTemporaryImageBinaryExamples = @"PNKTemporaryImageBinaryExamples";
NSString * const kPNKTemporaryImageExamplesKernel = @"PNKTemporaryImageExamplesKernel";
NSString * const kPNKTemporaryImageExamplesDevice = @"PNKTemporaryImageExamplesDevice";
NSString * const kPNKTemporaryImageExamplesOutputChannels =
    @"PNKTemporaryImageExamplesOutputChannels";

SharedExamplesBegin(PNKTemporaryImageExamples)

sharedExamplesFor(kPNKTemporaryImageUnaryExamples, ^(NSDictionary *data) {
  context(@"PNKUnaryKernel protocol", ^{
    it(@"should manage readCount properly upon consumption", ^{
      id<PNKUnaryKernel> unaryKernel = data[kPNKTemporaryImageExamplesKernel];
      id<MTLDevice> device = data[kPNKTemporaryImageExamplesDevice];
      NSUInteger outputChannels = [data[kPNKTemporaryImageExamplesOutputChannels]
                                   unsignedIntegerValue];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      MTLSize outputSize{32, 32, outputChannels};
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device
                                                        width:outputSize.width
                                                       height:outputSize.height
                                                     channels:outputSize.depth];
      auto inputRegion = [unaryKernel inputRegionForOutputSize:outputSize];

      auto inputImage =
          [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                         width:inputRegion.size.width
                                                        height:inputRegion.size.height
                                                      channels:inputRegion.size.depth];
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
      NSUInteger outputChannels = [data[kPNKTemporaryImageExamplesOutputChannels]
                                   unsignedIntegerValue];

      auto commandQueue = [device newCommandQueue];
      id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

      MTLSize outputSize{32, 32, outputChannels};
      auto outputImage = [MPSImage pnk_float16ImageWithDevice:device
                                                        width:outputSize.width
                                                       height:outputSize.height
                                                     channels:outputSize.depth];
      auto primaryInputRegion = [binaryKernel primaryInputRegionForOutputSize:outputSize];
      auto secondaryInputRegion = [binaryKernel secondaryInputRegionForOutputSize:outputSize];

      auto primaryInputImage =
          [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                         width:primaryInputRegion.size.width
                                                        height:primaryInputRegion.size.height
                                                      channels:primaryInputRegion.size.depth];
      expect(primaryInputImage.readCount == 1);

      auto secondaryInputImage =
          [MPSTemporaryImage pnk_float16ImageWithCommandBuffer:commandBuffer
                                                         width:secondaryInputRegion.size.width
                                                        height:secondaryInputRegion.size.height
                                                      channels:secondaryInputRegion.size.depth];
      expect(secondaryInputImage.readCount == 1);

      [binaryKernel encodeToCommandBuffer:commandBuffer primaryInputImage:primaryInputImage
                      secondaryInputImage:secondaryInputImage outputImage:outputImage];
      expect(primaryInputImage.readCount == 0);
      expect(secondaryInputImage.readCount == 0);
    });
  });
});

SharedExamplesEnd
