// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Object that represents information of a single consumable item.
@interface SPXConsumableItemStatus : MTLModel

/// Unique identifier of the consumable item.
@property (readonly, nonatomic) NSString *consumableItemID;

/// Credit required to obtain the consumable item. Should be \0 when the item is already owned.
/// Credit required may be different from \c creditWorth, e.g. in case of special discounts.
@property (readonly, nonatomic) NSUInteger creditRequired;

/// The type of the consumable item.
@property (readonly, nonatomic) NSString *consumableType;

/// \c YES if the item is already owned, \c NO otherwise.
@property (readonly, nonatomic) BOOL isOwned;

/// Credit worth of the consumable item, regardless of if it is owned or not.
@property (readonly, nonatomic) NSUInteger creditWorth;

@end

/// Object that represents the summary of the consumable items before placing the order. It contains
/// the credit the user currently has and the amount required to be redeemed for each consumable
/// item.
@interface SPXConsumablesOrderSummary : MTLModel

/// Type of the credit that is used to get the consumable items.
@property (readonly, nonatomic) NSString *creditType;

/// The user's credit balance of type \c creditType.
@property (readonly, nonatomic) NSUInteger currentCredit;

/// Dictionary mapping consumable items ID's to their status.
@property (readonly, nonatomic) NSDictionary<NSString *, SPXConsumableItemStatus *> *
    consumableItemsStatus;

@end

/// Represents status of an item that was requested to be redeemed.
@interface SPXRedeemedItemStatus : MTLModel

/// Unique identifier of the consumable item.
@property (readonly, nonatomic) NSString *consumableItemID;

/// The type of the consumable item.
@property (readonly, nonatomic) NSString *consumableType;

/// Credit redeemed for the item after the redeem request. May be \c 0 in case the user already owns
/// the item.
@property (readonly, nonatomic) NSUInteger redeemedCredit;

@end

/// Object that represents the status after redeeming successfully. It contains the user's credit
/// after redeeming and for each consumable item the amount of credit redeemed for it.
@interface SPXRedeemStatus : MTLModel

/// Type of the credit that was used to get the consumable items.
@property (readonly, nonatomic) NSString *creditType;

/// Credit left after the redeem request.
@property (readonly, nonatomic) NSUInteger currentCredit;

/// Dictionary mapping between consumable items ID's to their status after the redeem request.
@property (readonly, nonatomic) NSDictionary<NSString *, SPXRedeemedItemStatus *> *redeemedItems;

@end

NS_ASSUME_NONNULL_END
