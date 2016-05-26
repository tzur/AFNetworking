// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFormatStrategy.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Factory
#pragma mark -

@implementation CAMFormatStrategy

+ (id<CAMFormatStrategy>)highestResolution420f {
  return [[CAMFormatStrategyHighestResolution420f alloc] init];
}

+ (id<CAMFormatStrategy>)exact420fWidth:(int32_t)width height:(int32_t)height {
  return [[CAMFormatStrategyExactResolution420f alloc] initWithWidth:width height:height];
}

@end

#pragma mark -
#pragma mark Implementations
#pragma mark -

static BOOL CAMFormatHasPixelFormat(AVCaptureDeviceFormat *format, FourCharCode pixelFormat) {
  return CMFormatDescriptionGetMediaSubType(format.formatDescription) == pixelFormat;
}

static int64_t CAMFormatPixelCount(AVCaptureDeviceFormat *format) {
  CMVideoDimensions dimensions =
      CMVideoFormatDescriptionGetDimensions(format.formatDescription);
  return dimensions.width * dimensions.height;
}

@implementation CAMFormatStrategyHighestResolution420f

- (nullable AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> *)formats {
  return [[formats.rac_sequence
      filter:^BOOL(AVCaptureDeviceFormat *format) {
        return CAMFormatHasPixelFormat(format, '420f');
      }]
      foldLeftWithStart:nil reduce:^id(AVCaptureDeviceFormat *currentFormat,
                                       AVCaptureDeviceFormat *nextFormat) {
        if (!currentFormat) {
          return nextFormat;
        }

        if (CAMFormatPixelCount(currentFormat) < CAMFormatPixelCount(nextFormat)) {
          return nextFormat;
        }

        return currentFormat;
      }];
}

@end

@implementation CAMFormatStrategyExactResolution420f

- (instancetype)initWithWidth:(int32_t)width height:(int32_t)height {
  if (self = [super init]) {
    _width = width;
    _height = height;
  }
  return self;
}

- (nullable AVCaptureDeviceFormat *)formatFrom:(NSArray<AVCaptureDeviceFormat *> *)formats {
  return [[[formats.rac_sequence
      filter:^BOOL(AVCaptureDeviceFormat *format) {
        return CAMFormatHasPixelFormat(format, '420f');
      }]
      filter:^BOOL(AVCaptureDeviceFormat *format) {
        CMVideoDimensions dimensions =
            CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        return dimensions.width == self.width && dimensions.height == self.height;
      }]
      head];
}

@end

NS_ASSUME_NONNULL_END
