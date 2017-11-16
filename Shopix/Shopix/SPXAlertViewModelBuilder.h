// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class SPXAlertViewModelBuilder;
@protocol SPXAlertViewModel;

/// Interface for easily and dynamically building an \c SPXAlertViewModel.
///
/// For example the code below will show an alert with title that says "Ooops", the alert message
/// will be "Something went wrong" and it will have three buttons:
/// 1. "Try Again" button that when pressed subscribes to \c tryAgainSignal.
/// 2. "Contact Us" button that when pressed subscribes to \c sendFeedbackEmailSignal.
/// 3. "Cancel" button that when pressed subscribes to \c dismissViewControllerSignal.
///
/// @code
/// auto alertViewModel = [SPXAlertViewModelBuilder builder]
///     .title(@"Ooops")
///     .message(@"Something went wrong")
///     .addButton(@"Try Again", tryAgainSignal)
///     .addButton(@"Contact Us", sendFeedbackEmailSignal)
///     .addButton(@"Cancel", dismissViewControllerSignal)
///     .defaultButtonIndex(2)
///     .build();
/// auto alertController = [UIAlertController spx_alertControllerWithViewModel:alertViewModel];
/// [self presentViewController:alertController animation:YES];
/// @endcode
///
/// @see SPXAlertViewModel, SPXAlertButtonViewModel, UIAlertController+ViewModel
@interface SPXAlertViewModelBuilder : NSObject

/// Returns a new builder with empty alert view model.
///
/// @note Title must be set and buttons must be added before the view model can be built.
+ (instancetype)builder;

/// Block used to create a new builder that builds an \c SPXAlertViewModel with the given \c title.
typedef SPXAlertViewModelBuilder * _Nonnull (^SPXSetAlertTitleBlock)(NSString *title);

/// Set the alert's title.
@property (readonly, nonatomic) SPXSetAlertTitleBlock setTitle;

/// Block used to create a new builder that builds an \c SPXAlertViewModel with the given
/// \c message.
typedef SPXAlertViewModelBuilder * _Nonnull (^SPXSetAlertMessageBlock)(NSString *message);

/// Set the alert's message.
@property (readonly, nonatomic) SPXSetAlertMessageBlock setMessage;

/// Block used to create a new builder that builds an \c SPXAlerViewModel with additional button.
/// The additional button will have the given \c title and \c action.
typedef SPXAlertViewModelBuilder * _Nonnull (^SPXAddAlertButtonBlock)(NSString *title,
                                                                      RACSignal *action);

/// Add an alert button.
@property (readonly, nonatomic) SPXAddAlertButtonBlock addButton;

/// Add a default alert button. If there's already a default button it will be overwritten.
@property (readonly, nonatomic) SPXAddAlertButtonBlock addDefaultButton;

/// Block used to create a new builder that builds an \c SPXAlertViewModel with the given
/// \c defaultButtonIndex.
typedef SPXAlertViewModelBuilder * _Nonnull (^SPXSetDefaultAlertButtonIndexBlock)
    (NSUInteger defaultButtonIndex);

/// Set the alert's default button index. If a default button is already defined it will be
/// overwritten. If the new index is larger than the total number of buttons configured an
/// \c NSInvalidParameterException is raised.
@property (readonly, nonatomic) SPXSetDefaultAlertButtonIndexBlock setDefaultButtonIndex;

/// Block used to build and return the \c SPXAlertViewModel.
typedef id<SPXAlertViewModel> _Nonnull (^SPXBuildAlertViewModelBlock)();

/// Builds the \c SPXAlertViewModel. If not all required parameters are set an
/// \c NSInternalInconsistencyException is raised.
@property (readonly, nonatomic) SPXBuildAlertViewModelBlock build;

@end

NS_ASSUME_NONNULL_END
