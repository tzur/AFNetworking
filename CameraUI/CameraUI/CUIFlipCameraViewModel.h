// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#include "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CAMFlipDevice;

/// \c CUIMenuItemViewModel that serves as a view model for menu item button that toggles between
/// the available cameras of a given \c CAMFlipDevice instance.
///
/// \c title and \c iconURL hold the button's title and icon URL respectively, unless \c enabled is
/// \c NO, and in such case they are nil.
///
/// \c enabled is \c YES if the toggling between the available cameras is supported by the device.
///
/// The \c hidden and \c selected properties are always \c NO.
///
/// The \c subitems property is always \c nil.
///
/// Calling \c didTap toggles between the available cameras, unless it is not supported by the
/// device, and in such case it does nothing.
@interface CUIFlipCameraViewModel : NSObject <CUIMenuItemViewModel>

/// Initializes this object with the given \c flipDevice, \c title and \c iconURL.
- (instancetype)initWithFlipDevice:(id<CAMFlipDevice>)flipDevice
                             title:(nullable NSString *)title
                           iconURL:(nullable NSURL *)iconURL;

@end

NS_ASSUME_NONNULL_END
