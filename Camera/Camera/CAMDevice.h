// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

@class CAMCameraPreset;

@protocol CAMAudioDevice, CAMExposureDevice, CAMFlashDevice, CAMFlipDevice, CAMFocusDevice,
    CAMPreviewLayerDevice, CAMVideoDevice, CAMWhiteBalanceDevice, CAMZoomDevice;

NS_ASSUME_NONNULL_BEGIN

/// Protocol representing a camera device capable of providing a signal of video and audio frames
/// as well as controlling various camera-related settings such as focus, exposure, flash, etc.
///
/// An instance is initialized with a \c CAMCameraPreset object. While some of the settings may be
/// changed later at will, using the initializer is both more convenient and will assure that the
/// first frame arriving will already be with the correct settings.
@protocol CAMDevice <CAMAudioDevice, CAMExposureDevice, CAMFlashDevice, CAMFlipDevice,
    CAMFocusDevice, CAMPreviewLayerDevice, CAMVideoDevice, CAMWhiteBalanceDevice, CAMZoomDevice>

/// Initializes an instance with the given preset.
- (instancetype)initWithPreset:(CAMCameraPreset *)preset;

@end

NS_ASSUME_NONNULL_END
