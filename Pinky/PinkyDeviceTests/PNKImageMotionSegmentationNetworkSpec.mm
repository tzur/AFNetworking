// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSegmentationNetwork.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

#import "PNKImageMotionLayerType.h"
#import "PNKOpenCVExtensions.h"

DeviceSpecBegin(PNKImageMotionSegmentationNetwork)

it(@"should produce segmentation with pixels in correct range", ^{
  auto device = MTLCreateSystemDefaultDevice();
  auto commandQueue = [device newCommandQueue];
  auto commandBuffer = [commandQueue commandBuffer];

  NSBundle *bundle = NSBundle.lt_testBundle;
  NSError *error;
  auto networkModelURL =
      [NSURL URLWithString:[bundle lt_pathForResource:@"multiclass_segmentation.nnmodel"]];
  auto network = [[PNKImageMotionSegmentationNetwork alloc] initWithDevice:device
                                                           networkModelURL:networkModelURL
                                                                     error:&error];

  cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"tree.png");

  auto inputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                 height:inputMat.rows channels:3];
  PNKCopyMatToMTLTexture(inputImage.texture, inputMat);

  auto outputImage = [MPSImage pnk_unorm8ImageWithDevice:device width:inputMat.cols
                                                  height:inputMat.rows channels:1];

  [network encodeToCommandBuffer:commandBuffer inputImage:inputImage outputImage:outputImage];
  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];

  cv::Mat1b outputMat((int)outputImage.height, (int)outputImage.width);
  PNKCopyMTLTextureToMat(outputImage.texture, 0, 0, &outputMat);

  cv::Mat1b expectedMat = LTLoadMatFromBundle(bundle, @"tree_segmentation.png");
  expect($(outputMat)).to.beCloseToMatNormalizedHamming($(expectedMat), 0.01);
});

DeviceSpecEnd
