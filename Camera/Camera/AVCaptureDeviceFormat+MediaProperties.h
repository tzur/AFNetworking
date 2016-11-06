// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Category adding media-related properties for \c AVCaptureDeviceFormat.
@interface AVCaptureDeviceFormat (MediaProperties)

/// Width of the video, in pixels.
@property (readonly, nonatomic) NSUInteger cam_width;

/// Height of the video, in pixels.
@property (readonly, nonatomic) NSUInteger cam_height;

/// Total number of pixels in the video.
@property (readonly, nonatomic) NSUInteger cam_pixelCount;

/// Total number of pixels of the output of High Resolution Still Image output.
@property (readonly, nonatomic) NSUInteger cam_stillPixelCount;

/// Media subtype.
@property (readonly, nonatomic) NSUInteger cam_mediaSubType;

@end

NS_ASSUME_NONNULL_END
