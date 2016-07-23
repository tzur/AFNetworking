// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CAMFlashDevice;

@class CUIFlashModeViewModel;

/// \c CUIMenuItemViewModel that serves as a view model for menu item button that toggles between
/// the available flash modes of a \c CAMFlashDevice instance.
///
/// \c subitems contain the available \c CUIFlashModeViewModel objects for the \c CAMFlashDevice
/// instance.
///
/// \c title and \c iconURL are taken from the \c CUIFlashModeViewModel that matches the
/// \c currentFlashMode of the \c CAMFlashDevice instance, unless \c enabled is \c NO, and in such
/// case they are nil.
///
/// \c enabled is \c YES if the toggling between the flash modes is supported by the device.
///
/// The \c hidden and \c selected properties are always \c NO.
///
/// Calling \c didTap doesn't do anything.
@interface CUIFlashMenuViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this object with the given \c flashDevice, and \c flashModes that contains the
/// available <tt>CUIFlashModeViewModel</tt>s for the given \c CAMFlashDevice.
///
/// @note this object doesn't validate that the given flash modes are supported by the given
/// \c CAMFlashDevice, and it is the responsibility of the caller to do so.
- (instancetype)initWithFlashDevice:(id<CAMFlashDevice>)flashDevice
                         flashModes:(NSArray<CUIFlashModeViewModel *> *)flashModes
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
