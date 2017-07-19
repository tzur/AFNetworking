// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDeviceFormat.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMFakeAVCaptureDeviceFormat

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width
                           height:(int32_t)height {
  return [self formatWithSubtype:subtype width:width height:height stillWidth:0 stillHeight:0];
}

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height
                       stillWidth:(int32_t)stillWidth stillHeight:(int32_t)stillHeight {
  return [[CAMFakeAVCaptureDeviceFormat alloc] initWithSubtype:subtype width:width height:height
                                                    stillWidth:stillWidth stillHeight:stillHeight];
}

- (instancetype)initWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height
                     stillWidth:(int32_t)stillWidth stillHeight:(int32_t)stillHeight {
  if (self = [super init]) {
    CMVideoFormatDescriptionRef description;
    CMVideoFormatDescriptionCreate(NULL, subtype, width, height, NULL, &description);
    _formatDescriptionToReturn = description;

    CMVideoDimensions stillDimensions = {stillWidth, stillHeight};
    _highResolutionStillImageDimensionsToReturn = stillDimensions;

    _cam_mediaSubType = subtype;
    _cam_width = (NSUInteger)width;
    _cam_height = (NSUInteger)height;
    _cam_pixelCount = (NSUInteger)(width * height);
    _cam_stillPixelCount = (NSUInteger)(stillWidth * stillHeight);
  }
  return self;
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

- (float)minISO {
  return self.minISOToReturn;
}

- (float)maxISO {
  return self.maxISOToReturn;
}

- (CMTime)minExposureDuration {
  return self.minExposureDurationToReturn;
}

- (CMTime)maxExposureDuration {
  return self.maxExposureDurationToReturn;
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
