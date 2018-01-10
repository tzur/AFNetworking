// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class WFVideoView;

#pragma mark -
#pragma mark SPXSubscriptionButtonsContainerView
#pragma mark -

/// View used as a container presenting a group of subscription products. Displays a rounded corners
/// box containing title, subtitle and a set of subscription buttons. \c backgroundColor defaults to
/// black with opacity \c 0.6. \c borderColor defaults to white with opacity \c 0.3 and
/// \c borderWidth defaults to \c 0.6.
@interface SPXSubscriptionButtonsContainerView : UIView

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Title presented on top of the page. If \c nil no title is shown.
@property (strong, nonatomic, nullable) NSAttributedString *title;

/// Secondary title presented below \c title. If \c nil no subtitle is shown.
@property (strong, nonatomic, nullable) NSAttributedString *subtitle;

/// Subscription buttons, will be centered and horizontally aligned from left to right.
@property (copy, nonatomic) NSArray<UIControl *> *buttons;

/// Hot signal that sends the button's index when a button is pressed.
@property (readonly, nonatomic) RACSignal<NSNumber *> *buttonPressed;

@end

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageView
#pragma mark -

/// View used as a page presenting a group of subscription products in a rounded corners box and
/// video on the background.
@interface SPXSubscriptionButtonsPageView : UIView

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Page's background video view.
@property (readonly, nonatomic) WFVideoView *backgroundVideoView;

/// Buttons container containing title, subtitle and a set of subscription buttons.
@property (readonly, nonatomic) SPXSubscriptionButtonsContainerView *buttonsContainer;

@end

NS_ASSUME_NONNULL_END
