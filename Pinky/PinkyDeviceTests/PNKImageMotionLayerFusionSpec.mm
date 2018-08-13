// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerFusion.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKImageMotionLayerType.h"

static MPSImage *PNKUniformMotionMap(id<MTLDevice> device, int width, int height, float motionX,
                                     float motionY) {
  cv::Mat2f floatMat(height, width, cv::Vec2f(motionX, motionY));
  cv::Mat halfFloatMat;
  LTConvertMat(floatMat, &halfFloatMat, CV_16FC2);

  auto motionImage = [MPSImage mtb_float16ImageWithDevice:device width:width height:height
                                                 channels:2];
  PNKCopyMatToMTLTexture(motionImage.texture, halfFloatMat);
  return motionImage;
}

DeviceSpecBegin(PNKImageMotionLayerFusion)

it(@"should calculate motion map and segmentation map correctly", ^{
  // Image width and height.
  static const int kSize = 256;

  auto device = MTLCreateSystemDefaultDevice();

  cv::Mat1b segmentation(kSize, kSize);

  segmentation(cv::Rect(0, 0, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeSky;
  segmentation(cv::Rect(kSize / 2, 0, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeTrees;
  segmentation(cv::Rect(0, kSize / 2, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeGrass;
  segmentation(cv::Rect(kSize / 2, kSize / 2, kSize / 2, kSize / 2)) =
      pnk::ImageMotionLayerTypeWater;
  auto segmentationImage = [MPSImage mtb_unorm8ImageWithDevice:device width:kSize height:kSize
                                                      channels:1];
  PNKCopyMatToMTLTexture(segmentationImage.texture, segmentation);

  auto skyMotionImage = PNKUniformMotionMap(device, kSize, kSize, 0.25, 0.25);
  auto treesMotionImage = PNKUniformMotionMap(device, kSize, kSize, -0.25, 0.25);
  auto grassMotionImage = PNKUniformMotionMap(device, kSize, kSize, 0.25, -0.25);
  auto waterMotionImage = PNKUniformMotionMap(device, kSize, kSize, -0.25, -0.25);
  auto staticMotionImage = PNKUniformMotionMap(device, kSize, kSize, 0, 0);

  auto outputSegmentationImage = [MPSImage mtb_unorm8ImageWithDevice:device width:kSize height:kSize
                                                            channels:1];

  auto outputMotionImage = [MPSImage mtb_float16ImageWithDevice:device width:kSize height:kSize
                                                       channels:2];

  auto layerFusion = [[PNKImageMotionLayerFusion alloc] initWithDevice:device];
  auto commandQueue = [device newCommandQueue];
  auto commandBuffer = [commandQueue commandBuffer];
  [layerFusion encodeToCommandBuffer:commandBuffer
              inputSegmentationImage:segmentationImage
             inputDisplacementImages:@[skyMotionImage, staticMotionImage, treesMotionImage,
                                       grassMotionImage, waterMotionImage]
             outputSegmentationImage:outputSegmentationImage
             outputDisplacementImage:outputMotionImage];
  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];

  cv::Mat1b outputSegmentation(kSize, kSize);
  PNKCopyMTLTextureToMat(outputSegmentationImage.texture, 0, 0, &outputSegmentation);

  cv::Mat1b expectedSegmentation(kSize, kSize, (uchar)0);
  expectedSegmentation(cv::Rect(0, 0, kSize / 4, kSize / 4)) = pnk::ImageMotionLayerTypeSky;
  expectedSegmentation(cv::Rect(3 * kSize / 4, 0, kSize / 4, kSize / 4)) =
      pnk::ImageMotionLayerTypeTrees;
  expectedSegmentation(cv::Rect(0, 3 * kSize / 4, kSize / 4, kSize / 4)) =
      pnk::ImageMotionLayerTypeGrass;
  expectedSegmentation(cv::Rect(3 * kSize / 4, 3 * kSize / 4, kSize / 4, kSize / 4)) =
      pnk::ImageMotionLayerTypeWater;
  expect($(outputSegmentation)).to.equalMat($(expectedSegmentation));

  cv::Mat2hf outputMotion(kSize, kSize);
  PNKCopyMTLTextureToMat(outputMotionImage.texture, 0, 0, &outputMotion);

  cv::Mat2f expectedMotionFloat(kSize, kSize, cv::Vec2f(0, 0));
  expectedMotionFloat(cv::Rect(0, 0, kSize / 4, kSize / 4)) = cv::Vec2f(0.25, 0.25);
  expectedMotionFloat(cv::Rect(3 * kSize / 4, 0, kSize / 4, kSize / 4)) = cv::Vec2f(-0.25, 0.25);
  expectedMotionFloat(cv::Rect(0, 3 * kSize / 4, kSize / 4, kSize / 4)) = cv::Vec2f(0.25, -0.25);
  expectedMotionFloat(cv::Rect(3 * kSize / 4, 3 * kSize / 4, kSize / 4, kSize / 4)) =
      cv::Vec2f(-0.25, -0.25);
  cv::Mat expectedMotion;
  LTConvertMat(expectedMotionFloat, &expectedMotion, CV_16FC2);
  expect($(outputMotion)).to.equalMat($(expectedMotion));
});

DeviceSpecEnd
