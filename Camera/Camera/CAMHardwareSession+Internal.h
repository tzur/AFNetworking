// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "CAMHardwareSession.h"

NS_ASSUME_NONNULL_BEGIN

@class CAMDevicePreset, CAMPixelFormat;

@protocol CAMFormatStrategy;

@interface CAMHardwareSession (Internal)

/// Initialize with the given \c preset and \c session.
- (instancetype)initWithPreset:(CAMDevicePreset *)preset session:(AVCaptureSession *)session;

/// Create preview layer.
- (void)createPreviewLayer;

/// Setup video input with given \c device and \c formatStrategy. On failure return \c NO and set
/// \c error.
- (BOOL)setupVideoInputWithDevice:(AVCaptureDevice *)device
                   formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                            error:(NSError * __autoreleasing *)error;

/// Setup video output. On failure return \c NO and set \c error.
- (BOOL)setupVideoOutputWithError:(NSError * __autoreleasing *)error;

/// Setup photo output with given \c pixelFormat. On failure return \c NO and set \c error.
- (BOOL)setupPhotoOutputWithPixelFormat:(CAMPixelFormat *)pixelFormat
                                  error:(NSError * __autoreleasing *)error;

/// Setup audio input with given \c device. On failure return \c NO and set \c error.
- (BOOL)setupAudioInputWithDevice:(AVCaptureDevice *)device
                            error:(NSError * __autoreleasing *)error;

/// Setup audio output. On failure return \c NO and set \c error.
- (BOOL)setupAudioOutputWithError:(NSError * __autoreleasing *)error;

/// The \c AVCaptureSession object managed by the receiver.
@property (readonly, nonatomic) AVCaptureSession *session;

@end

NS_ASSUME_NONNULL_END
