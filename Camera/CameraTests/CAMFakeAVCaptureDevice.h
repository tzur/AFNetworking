// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fake \c AVCaptureDevice for testing purposes. Records whether \c lockForConfiguration: and
/// \c unlockForConfiguration were called, and in what order they were called. Can be configured to
/// err in \c lockForConfiguration:.
@interface CAMFakeAVCaptureDevice : AVCaptureDevice

/// Error to return in \c lockForConfiguration:. If \c nil, \c lockForConfiguration: will succeed.
@property (strong, nonatomic) NSError *lockError;

/// Set to \c YES after \c lockForConfiguration: is called.
@property (readonly, nonatomic) BOOL didLock;

/// Set to \c YES after \c unlockForConfiguration is called.
@property (readonly, nonatomic) BOOL didUnlock;

/// Set to \c YES when \c unlockForConfiguration is called, and \c lockForConfiguration: was called
/// before.
@property (readonly, nonatomic) BOOL didUnlockWhileLocked;

/// Media types the receiver will report to "have", when queried using \c hasMediaType:.
@property (copy, nonatomic) NSArray<NSString *> *mediaTypes;

@end

NS_ASSUME_NONNULL_END
