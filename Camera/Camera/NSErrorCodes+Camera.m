// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "NSErrorCodes+Camera.h"

NS_ASSUME_NONNULL_BEGIN

/// All error codes available in Camera.
LTErrorCodesImplement(CameraErrorCodeProductID,
  /// Caused when a frame was dropped.
  CAMErrorCodeDroppedFrame,
  /// Caused when a video device was not found.
  CAMErrorCodeMissingVideoDevice,
  /// Caused when there was an error locking the video device for configuration.
  CAMErrorCodeFailedLockingVideoDevice,
  /// Caused when there was an error configuring the video device.
  CAMErrorCodeFailedConfiguringVideoDevice,
  /// Caused when there was an error creating the video input.
  CAMErrorCodeFailedCreatingVideoInput,
  /// Caused when there was an error attaching the video input to the session.
  CAMErrorCodeFailedAttachingVideoInput,
  /// Caused when there was an error attaching the video output to the session.
  CAMErrorCodeFailedAttachingVideoOutput,
  /// Caused when there was an error creating the audio input.
  CAMErrorCodeFailedCreatingAudioInput,
  /// Caused when an audio device was not found.
  CAMErrorCodeMissingAudioDevice,
  /// Caused when there was an error attaching the audio input to the session.
  CAMErrorCodeFailedAttachingAudioInput,
  /// Caused when there was an error attaching the audio output to the session.
  CAMErrorCodeFailedAttachingAudioOutput,
  /// Caused when there was an error attaching the still image output to the session.
  CAMErrorCodeFailedAttachingStillOutput,
  /// Caused when there was an error capturing an image from the still image output.
  CAMErrorCodeFailedCapturingFromStillOutput,
  /// Caused when the requested focus setting is not supported.
  CAMErrorCodeFocusSettingUnsupported,
  /// Caused when the requested exposure setting is not supported.
  CAMErrorCodeExposureSettingUnsupported,
  /// Caused when the requested white balance setting is not supported.
  CAMErrorCodeWhiteBalanceSettingUnsupported,
  /// Caused when the requested flash setting is not supported.
  CAMErrorCodeFlashModeSettingUnsupported,
  /// Caused when the requested torch setting is not supported.
  CAMErrorCodeTorchModeSettingUnsupported,
  /// Caused when the <tt>CMMotionManager</tt>'s device motion is unavailable.
  CAMErrorCodeDeviceMotionUnavailable,
  /// Caused when the \c CMDeviceMotionHandler receives an error.
  CAMErrorCodeDeviceMotionUpdateError,
  /// Caused when the requested physical camera device is unavailable.
  CAMErrorCodeCameraUnavailable
);

NS_ASSUME_NONNULL_END
