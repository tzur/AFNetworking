// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import <AVFoundation/AVFoundation.h>

#include "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CAMFlashDevice;

/// Object that conforms to the \c CUIMenuItemViewModel protocol for a single \c AVCaptureFlashMode
/// (e.g. \c AVCaptureFlashModeAuto) of a given \c CAMFlashDevice object.
///
/// If the current flash mode doesn't match this object's flash mode, calling \c didTap will trigger
/// a call to the \c CAMFlashDevice object to change its flash mode to this object's flash mode.
///
/// The \c hidden property is always \c NO.
///
/// The \c enabled property is always \c YES.
///
/// The \c selected property is \c YES if the this object's \c flashMode matches the
/// \c CAMFlashDevice object's \c currentFlashMode.
///
/// The \c subitems property is always \c nil.
@interface CUIFlashModeViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this object with the given \c flashDevice, the \c flashMode that this object
/// represents, and the \c title and \c iconURL that should be shown for this mode.
- (instancetype)initWithFlashDevice:(id<CAMFlashDevice>)flashDevice
                          flashMode:(AVCaptureFlashMode)flashMode
                              title:(nullable NSString *)title
                            iconURL:(nullable NSURL *)iconURL;

/// Flash mode represented by this object.
@property (readonly, nonatomic) AVCaptureFlashMode flashMode;

@end

NS_ASSUME_NONNULL_END
