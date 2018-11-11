// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@class EUISMModel, EUISMProductInfo;

/// View model for the upgrade promotion line of the "Your Plan" section of the subscription
/// management screen.
@protocol EUISMYourPlanPromotionViewModel <NSObject>

/// Text of the upgrade promotion line. The text is empty unless a cheeper yearly upgrade is
/// relevant. In this case the text will promote upgrade to yearly and include the saved amount in
/// percents. However, the text is empty if the user has a pending yearly subscription.
@property (readonly, nonatomic) NSString *promotionText;

/// Promotion text color of the upgrade promotion line. Depends on the current application. Defaults
/// to <tt>[UIColor grayColor]</tt>
@property (readonly, nonatomic) UIColor *promotionTextColor;

/// Background color of upgrade button of the upgrade promotion line. Depends on the current
/// application. Defaults to <tt>[UIColor grayColor]</tt>
@property (readonly, nonatomic) UIColor *upgradeButtonColor;

/// Hot signal firing the info of the product to upgrade to. It fires whenever
/// \c upgradeRequested fires.
@property (readonly, nonatomic) RACSignal<EUISMProductInfo *> *upgradeSignal;

/// Signal firing when update is requested. If this signal is set, then whenever it fires the
/// \c upgradeSignal will fire the \c EUISMProductInfo of the product to upgrade to.
@property (strong, nonatomic, nullable) RACSignal<RACUnit *> *upgradeRequested;

@end

/// Concrete implementation of \c EUISMYourPlanPromotionViewModel.
@interface EUISMYourPlanPromotionViewModel : NSObject <EUISMYourPlanPromotionViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c modelSignal. The properties of the
/// \c EUISMYourPlanPromotionViewModel protocol are derived from the last model this signal sent.
- (instancetype)initWithModelSignal:(RACSignal<EUISMModel *> *)modelSignal
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
