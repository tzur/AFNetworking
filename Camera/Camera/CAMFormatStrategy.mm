// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFormatStrategy.h"

#import <AVFoundation/AVFoundation.h>

#import "AVCaptureDeviceFormat+MediaProperties.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMFormatStrategyHighestResolution420f

- (nullable AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> *)formats {
  return [[formats.rac_sequence
      filter:^BOOL(AVCaptureDeviceFormat *format) {
        return format.cam_mediaSubType == '420f';
      }]
      foldLeftWithStart:nil reduce:^id(AVCaptureDeviceFormat *currentFormat,
                                       AVCaptureDeviceFormat *nextFormat) {
        if (!currentFormat) {
          return nextFormat;
        }
        if (currentFormat.cam_pixelCount < nextFormat.cam_pixelCount) {
          return nextFormat;
        }
        return currentFormat;
      }];
}

@end

@implementation CAMFormatStrategyExactResolution420f

- (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height {
  if (self = [super init]) {
    _width = width;
    _height = height;
  }
  return self;
}

- (nullable AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> *)formats {
  return [formats.rac_sequence
      objectPassingTest:^BOOL(AVCaptureDeviceFormat *format) {
        return format.cam_mediaSubType == '420f' &&
            format.cam_width == self.width && format.cam_height == self.height;
      }];
}

@end

NS_ASSUME_NONNULL_END
