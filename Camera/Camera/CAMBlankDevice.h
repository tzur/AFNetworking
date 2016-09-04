// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMAudioDevice.h"
#import "CAMExposureDevice.h"
#import "CAMFlashDevice.h"
#import "CAMFlipDevice.h"
#import "CAMFocusDevice.h"
#import "CAMPreviewLayerDevice.h"
#import "CAMVideoDevice.h"
#import "CAMWhiteBalanceDevice.h"
#import "CAMZoomDevice.h"

NS_ASSUME_NONNULL_BEGIN

/// Implementation of a camera that does nothing.
///
/// This device can be used as a placeholder for a 'real' camera in tests, simulator, or before
/// another device has finished initializing.
@interface CAMBlankDevice : NSObject <CAMAudioDevice, CAMExposureDevice, CAMFlashDevice,
    CAMFlipDevice, CAMFocusDevice, CAMPreviewLayerDevice, CAMVideoDevice, CAMWhiteBalanceDevice,
    CAMZoomDevice>
@end

NS_ASSUME_NONNULL_END
