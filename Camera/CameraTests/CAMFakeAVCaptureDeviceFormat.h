// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAMFakeAVCaptureDeviceFormat : AVCaptureDeviceFormat

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height;

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height
                       stillWidth:(int32_t)stillWidth stillHeight:(int32_t)stillHeight;

@property (nonatomic) CGFloat videoMaxZoomFactorToReturn;

@property (nonatomic) CMFormatDescriptionRef formatDescriptionToReturn;

@property (nonatomic) CMVideoDimensions highResolutionStillImageDimensionsToReturn;

@end

NS_ASSUME_NONNULL_END
