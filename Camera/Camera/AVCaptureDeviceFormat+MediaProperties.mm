// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "AVCaptureDeviceFormat+MediaProperties.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AVCaptureDeviceFormat (MediaProperties)

- (NSUInteger)cam_width {
  return (NSUInteger)CMVideoFormatDescriptionGetDimensions(self.formatDescription).width;
}

- (NSUInteger)cam_height {
  return (NSUInteger)CMVideoFormatDescriptionGetDimensions(self.formatDescription).height;
}

- (NSUInteger)cam_pixelCount {
  return self.cam_width * self.cam_height;
}

- (NSUInteger)cam_stillPixelCount {
  CMVideoDimensions dimensions = self.highResolutionStillImageDimensions;
  return (NSUInteger)(dimensions.width * dimensions.height);
}

- (NSUInteger)cam_mediaSubType {
  return CMFormatDescriptionGetMediaSubType(self.formatDescription);
}

@end

NS_ASSUME_NONNULL_END
