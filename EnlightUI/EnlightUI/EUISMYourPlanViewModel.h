// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@class EUISMModel;

/// View model for the "your plan" section of the subscription management screen.
@protocol EUISMYourPlanViewModel <NSObject>

/// Text of the title line inside the "your plan" section. If the user is subscribed to eco system
/// the title is the eco system name. Otherwise, it is the full name of the current application.
/// Defaults to empty string.
@property (readonly, nonatomic) NSString *title;

/// Text of the subtitle line inside the "your plan" section. The text describes whether the user is
/// or was subscribed and for what billing period. In case the subscription will renew to a product
/// with a different billing period, the billing period of the pending product will be used instead
/// of the billing period of the current product. Defaults to empty string.
@property (readonly, nonatomic) NSString *subtitle;

/// Text of the body inside the "your plan" section. The text contains the current subscription's
/// expiration date and will the subscription renew, will it end, or did it already expire. Defaults
/// to empty string.
@property (readonly, nonatomic) NSString *body;

/// URL of the current application thumbnail to present inside the "your plan" section. \c nil if no
/// available thumbnail.
@property (readonly, nonatomic, nullable) NSURL *currentAppThumbnailURL;

/// URL of the icon that reflects the current subscription plan status. \c nil if no icon for the
/// current status.
@property (readonly, nonatomic, nullable) NSURL *statusIconURL;

@end

/// Concrete implementation of \c EUISMYourPlanViewModel.
@interface EUISMYourPlanViewModel : NSObject <EUISMYourPlanViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c modelSignal. The properties of the \c EUISMYourPlanViewModel
/// protocol are derived from the last model this signal sent.
- (instancetype)initWithModelSignal:(RACSignal<EUISMModel *> *)modelSignal
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
