// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for controlling the time interval of a timer.
@protocol CUITimerContainer <NSObject>

/// Time interval of the timer.
@property (nonatomic) NSTimeInterval interval;

@end

/// \c CUIMenuItemViewModel representing a single interval value of a \c id<CUITimerContainer>.
///
/// Calling \c didTap sets the \c id<CUITimerContainer>'s interval to this object's value.
///
/// \c selected is \c YES when the \c id<CUITimerContainer>'s interval is within \c precision of
/// this object's.
///
/// By default, \c enabledSignal sends \c YES.
///
/// The \c hidden property is always \c NO and \c subitems is always \c nil.
@interface CUITimerModeViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Creates and returns a view model created with the given parameters.
+ (instancetype)viewModelWithTimerContainer:(id<CUITimerContainer>)timerContainer
                                   interval:(NSTimeInterval)interval
                                  precision:(NSTimeInterval)precision
                                      title:(nullable NSString *)title
                                    iconURL:(nullable NSURL *)iconURL;

/// Initializes this object with the given \c id<CUITimerContainer>, the \c interval and
/// \c precision that this object represents, and the \c title and \c iconURL that should be shown
/// for this mode. Raises \c NSInvalidArgumentException if \c interval is negative or \c precision
/// is non-positive.
- (instancetype)initWithTimerContainer:(id<CUITimerContainer>)timerContainer
                              interval:(NSTimeInterval)interval
                             precision:(NSTimeInterval)precision
                                 title:(nullable NSString *)title
                               iconURL:(nullable NSURL *)iconURL NS_DESIGNATED_INITIALIZER;

/// Time interval represented by the receiver.
@property (readonly, nonatomic) NSTimeInterval interval;

/// Precision represented by the receiver.
@property (readonly, nonatomic) NSTimeInterval precision;

@end

NS_ASSUME_NONNULL_END
