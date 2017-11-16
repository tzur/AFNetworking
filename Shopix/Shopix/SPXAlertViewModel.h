// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXAlertButtonViewModel
#pragma mark -

/// Protocol for alert buttons view model.
@protocol SPXAlertButtonViewModel <NSObject>

/// Title for the alert button.
@property (readonly, nonatomic) NSString *title;

/// Action to execute when that button is pressed.
@property (readonly, nonatomic) RACCommand<RACUnit *, id> *action;

@end

/// Implementation of the \c SPXAlertButtonViewModel protocol.
@interface SPXAlertButtonViewModel : NSObject <SPXAlertButtonViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the view model with the given \c title. The receiver's \c action command will
/// subscribe to the given \c action signal on execution.
- (instancetype)initWithTitle:(NSString *)title action:(RACSignal *)action
    NS_DESIGNATED_INITIALIZER;

@end

#pragma mark -
#pragma mark SPXAlertViewModel
#pragma mark -

/// Protocol for alert view model.
///
/// @see UIAlertController+ViewModel, SPXAlertViewModelBuilder
@protocol SPXAlertViewModel <NSObject>

/// Alert's title - describes the reason for displaying the alert.
@property (readonly, nonatomic) NSString *title;

/// Alert's message - gives more context and describes the possible actions the user can take.
/// The message is optional, it can be \c nil if only title is desired.
@property (readonly, nonatomic, nullable) NSString *message;

/// Alert's buttons. Must be a non-empty array.
@property (readonly, nonatomic) NSArray<id<SPXAlertButtonViewModel>> *buttons;

/// Index of the default alert button, or \c nil if no default button. The value must be in the
/// range <tt>[0, buttons.count - 1]</tt>. The default button may be shown highlighted by the
/// alert view.
@property (readonly, nonatomic, nullable) NSNumber *defaultButtonIndex;

@end

/// Default implementation of the \c SPXAlertViewModel protocol.
///
/// Use \c SPXAlertViewModelBuilder which provides a more convenience way to create instances of
/// this view model.
@interface SPXAlertViewModel : NSObject <SPXAlertViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the alert view model with the given \c title and \c buttons. If \c message is not
/// \c nil the alert will have both title and message. If \c defaultButtonIndex is not \c nil it
/// specifies the alert's default button.
///
/// If \c buttons is an empty array or that \c defaultButtonIndex exceeds the \c buttons array size
/// an \c NSInvalidArgumentException is raised.
- (instancetype)initWithTitle:(NSString *)title message:(nullable NSString *)message
                      buttons:(NSArray<SPXAlertButtonViewModel *> *)buttons
           defaultButtonIndex:(nullable NSNumber *)defaultButtonIndex NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
