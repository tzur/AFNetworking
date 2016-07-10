// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CAMFlashDevice;

@class CUIFlashModeViewModel;

/// Object that conforms to the \c CUIMenuItemViewModel protocol for a given \c CAMFlashDevice
/// instance. This object holds the \c title and \c iconURL of the \c CUIFlashModeViewModel that
/// matches the \c currentFlashMode of the given \c CAMFlashDevice instance, and its \c subitems
/// contain the availble <tt>CUIFlashModeViewModel</tt>s for the given \c CAMFlashDevice instance.
///
/// The \c hidden and \c selected properties are always \c NO.
///
/// Calling \c didTap doesn't do anything.
@interface CUIFlashMenuViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this object with the given \c flashDevice, and \c flashModes that contains the
/// availble <tt>CUIFlashModeViewModel</tt>s for the given \c CAMFlashDevice.
///
/// @note this obect doesn't validate that the given flash modes are supported by the given
/// \c CAMFlashDevice, and it is the responsibility of the caller to do so.
- (instancetype)initWithFlashDevice:(id<CAMFlashDevice>)flashDevice
                         flashModes:(NSArray<CUIFlashModeViewModel *> *)flashModes;

@end

NS_ASSUME_NONNULL_END
