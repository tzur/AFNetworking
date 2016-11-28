// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMAudioDevice.h"
#import "CAMExposureDevice.h"
#import "CAMFlashDevice.h"
#import "CAMFlipDevice.h"
#import "CAMFocusDevice.h"
#import "CAMPreviewLayerDevice.h"
#import "CAMTorchDevice.h"
#import "CAMVideoDevice.h"
#import "CAMWhiteBalanceDevice.h"
#import "CAMZoomDevice.h"

@class CAMHardwareSession;

NS_ASSUME_NONNULL_BEGIN

/// Implementation of a camera based on camera hardware.
///
/// It is important to retain the frames on \c videoFrames for as little time as possible. Retaining
/// them for long can cause delays in receiving the next frames. If non-trivial processing needs
/// to be done, copy the \c LTTextures and release the video frame.
///
/// \c videoFrames is guaranteed to deliver (by default) on the queue given in the \c
/// CAMDevicePreset used to initialize \c CAMHardwareSession. It is important to leave this queue
/// free for receiving the next frames. If non-trivial, non-GPU processing needs to be done, do the
/// work on a different queue.
@interface CAMHardwareDevice : NSObject <CAMAudioDevice, CAMExposureDevice, CAMFlashDevice,
    CAMFlipDevice, CAMFocusDevice, CAMPreviewLayerDevice, CAMTorchDevice, CAMVideoDevice,
    CAMWhiteBalanceDevice, CAMZoomDevice>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c session and \c sessionQueue to run all \c session mutations on.
- (instancetype)initWithSession:(CAMHardwareSession *)session
                   sessionQueue:(dispatch_queue_t)sessionQueue NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
