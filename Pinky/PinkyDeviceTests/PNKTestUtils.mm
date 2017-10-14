// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTestUtils.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSBundle+Path.h>

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels) {
  return [MPSImage pnk_imageWithDevice:device format:format width:width height:height
                              channels:channels];
}

MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels) {
  return [MPSImage pnk_unorm8ImageWithDevice:device width:width height:height channels:channels];
}

cv::Mat1f PNKLoadFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(float) == 0, @"File size must be a multiply of "
                    "%lu, got %lu", sizeof(float), tensorFile.size);

  cv::Mat1f tensorData(1, (int)tensorFile.size / sizeof(float));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

cv::Mat1hf PNKLoadHalfFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(half_float::half) == 0, @"File size must be a "
                    "multiply of %lu, got %lu", sizeof(float) / 2, tensorFile.size);

  cv::Mat1hf tensorData(1, (int)tensorFile.size / sizeof(half_float::half));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

NS_ASSUME_NONNULL_END
