// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDeviceFormat.h"

#import "AVCaptureDeviceFormat+MediaProperties.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMFakeAVCaptureDeviceFormat

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width
                           height:(int32_t)height {
  return [self formatWithSubtype:subtype width:width height:height stillWidth:0 stillHeight:0];
}

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height
                       stillWidth:(int32_t)stillWidth stillHeight:(int32_t)stillHeight {
  CAMFakeAVCaptureDeviceFormat *format = [[CAMFakeAVCaptureDeviceFormat alloc] init];

  CMVideoFormatDescriptionRef description;
  CMVideoFormatDescriptionCreate(NULL, subtype, width, height, NULL, &description);
  format.formatDescriptionToReturn = description;

  CMVideoDimensions stillDimensions = {stillWidth, stillHeight};
  format.highResolutionStillImageDimensionsToReturn = stillDimensions;

  return format;
}

- (CGFloat)videoMaxZoomFactor {
  return self.videoMaxZoomFactorToReturn;
}

- (CMFormatDescriptionRef)formatDescription {
  return self.formatDescriptionToReturn;
}

- (CMVideoDimensions)highResolutionStillImageDimensions {
  return self.highResolutionStillImageDimensionsToReturn;
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p", self.class, self];
  [description appendFormat:@", subtype: %lu", (unsigned long)self.cam_mediaSubType];
  [description appendFormat:@", dimensions: (%lu, %lu)", (unsigned long)self.cam_width,
                            (unsigned long)self.cam_height];
  [description appendFormat:@", still dimensions: (%d, %d)",
                            self.highResolutionStillImageDimensions.width,
                            self.highResolutionStillImageDimensions.height];
  [description appendString:@">"];
  return [description copy];
}

@end

NS_ASSUME_NONNULL_END
