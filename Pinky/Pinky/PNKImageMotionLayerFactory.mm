// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerFactory.h"

#import "PNKImageMotionGrassLayer.h"
#import "PNKImageMotionSkyLayer.h"
#import "PNKImageMotionStaticLayer.h"
#import "PNKImageMotionTreeLayer.h"
#import "PNKImageMotionWaterLayer.h"
#import "PNKImageMotionWavePatch.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PNKImageMotionLayerFactory

+ (nullable id<PNKImageMotionLayer>)layerWithType:(pnk::ImageMotionLayerType)type
                                        imageSize:(cv::Size)imageSize {
  switch (type) {
    case pnk::ImageMotionLayerTypeWater:
      return [[PNKImageMotionWaterLayer alloc] initWithImageSize:imageSize patchSize:32
                                                       amplitude:10];
    case pnk::ImageMotionLayerTypeGrass:
      return [[PNKImageMotionGrassLayer alloc] initWithImageSize:imageSize patchSize:32
                                                       amplitude:10];
    case pnk::ImageMotionLayerTypeTrees:
      return [[PNKImageMotionTreeLayer alloc] initWithImageSize:imageSize numberOfSamples:64
                                                      amplitude:10];
    case pnk::ImageMotionLayerTypeStatic:
      return [[PNKImageMotionStaticLayer alloc] initWithImageSize:imageSize];
    case pnk::ImageMotionLayerTypeSky:
      return [[PNKImageMotionSkyLayer alloc]initWithImageSize:imageSize angle:0 speed:100.0];
    default:
      return nil;
  }
}

@end

NS_ASSUME_NONNULL_END
