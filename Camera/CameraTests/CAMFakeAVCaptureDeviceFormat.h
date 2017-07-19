// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c AVCaptureDeviceFormat to be used in testing. To use, explicitly cast to
/// \c AVCaptureDeviceFormat (or \c id).
///
/// Starting with iOS 11, Apple have made it harder to directly subclass \c AVCaptureDeviceFormat.
/// Therefore, this class contains some properties that are needed so compilation and linkage will
/// still work.
@interface CAMFakeAVCaptureDeviceFormat : NSObject

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height;

+ (instancetype)formatWithSubtype:(FourCharCode)subtype width:(int32_t)width height:(int32_t)height
                       stillWidth:(int32_t)stillWidth stillHeight:(int32_t)stillHeight;

@property (nonatomic) CGFloat videoMaxZoomFactorToReturn;

@property (nonatomic) CMFormatDescriptionRef formatDescriptionToReturn;

@property (nonatomic) CMVideoDimensions highResolutionStillImageDimensionsToReturn;

@property (nonatomic) float minISOToReturn;
@property (nonatomic) float maxISOToReturn;
@property (nonatomic) CMTime minExposureDurationToReturn;
@property (nonatomic) CMTime maxExposureDurationToReturn;

// From AVCaptureDeviceFormat+MediaProperties.
@property (readonly, nonatomic) NSUInteger cam_width;
@property (readonly, nonatomic) NSUInteger cam_height;
@property (readonly, nonatomic) NSUInteger cam_pixelCount;
@property (readonly, nonatomic) NSUInteger cam_stillPixelCount;
@property (readonly, nonatomic) NSUInteger cam_mediaSubType;

@end

NS_ASSUME_NONNULL_END
