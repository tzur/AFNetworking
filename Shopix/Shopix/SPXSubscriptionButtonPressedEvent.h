// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTValueObject.h>

#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents the event where a subscription button was pressed.
@interface SPXSubscriptionButtonPressedEvent : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c subscriptionDescriptor describing the subscription of button that was
/// pressed.
- (instancetype)initWithSubscriptionDescriptor:(SPXSubscriptionDescriptor *)subscriptionDescriptor
    NS_DESIGNATED_INITIALIZER;

/// Subscription product identifier.
@property (readonly, nonatomic) NSString *productIdentifier;

/// Subscription price.
@property (readonly, nonatomic) NSDecimalNumber *price;

/// Identifier for the locale. For example "en_GB", "es_ES_PREEURO".
@property (readonly, nonatomic) NSString *localeIdentifier;

/// Item price three-letter currency code. For example "USD", "ILS", "RUB".
@property (readonly, nonatomic, nullable) NSString *currencyCode;

@end

NS_ASSUME_NONNULL_END
