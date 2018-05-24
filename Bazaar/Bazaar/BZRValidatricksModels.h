// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRValidatricksErrorInfo
#pragma mark -

/// Model representing Validatricks server response is case of an error.
@interface BZRValidatricksErrorInfo : BZRModel <MTLJSONSerializing>

/// Unique identifier of the request. Can be used later to collect logs related to that request.
@property (readonly, nonatomic) NSString *requestId;

/// Short descriptive error name.
@property (readonly, nonatomic) NSString *error;

/// Optional error message.
@property (readonly, nonatomic, nullable) NSString *message;

@end

#pragma mark -
#pragma mark BZRValidatricksNotEnoughCreditErrorInfo
#pragma mark -

/// Model representing Validatricks server response is case of an error caused due to insufficient
/// credit.
@interface BZRValidatricksNotEnoughCreditErrorInfo : BZRValidatricksErrorInfo

/// Type of the credit the request was made for.
@property (readonly, nonatomic) NSString *creditType;

/// Credit of \c creditType in the user's balance.
@property (readonly, nonatomic) NSUInteger currentCredit;

/// Total amount of credit required for the redeem request to succeed.
@property (readonly, nonatomic) NSUInteger requiredCredit;

@end

#pragma mark -
#pragma mark BZRConsumableItemDescriptor
#pragma mark -

/// Model describing and identifying a consumable item. A consumable item is identified by two
/// properties - a \c consumableType which indicates the category or type of the item and a
/// \c consumableItemId which uniquely identifies the item.
///
/// @note The \c consumableType used by the server to determine the amount of credit to deduce from
/// the user's balance. Hence when redeeming consumable items it is important to specify the correct
/// \c consumableType, and when checking user's eligibility to some consumable item it is important
/// to verify the consumable type and not only the item ID.
@interface BZRConsumableItemDescriptor : BZRModel <MTLJSONSerializing>

/// Initializes the receiver with the given \c consumableItemId and \c consumableType.
- (instancetype)initWithConsumableItemId:(NSString *)consumableItemId
                                  ofType:(NSString *)consumableType NS_DESIGNATED_INITIALIZER;

/// The type of the consumable item.
@property (readonly, nonatomic) NSString *consumableType;

/// Unique identifier of the consumable item.
@property (readonly, nonatomic) NSString *consumableItemId;

@end

#pragma mark -
#pragma mark BZRUserCreditStatus
#pragma mark -

/// Model representing Validatrics server response for a "get user credit" request.
@interface BZRUserCreditStatus : BZRModel <MTLJSONSerializing>

/// Unique identifier of the request. Can be used later to collect logs related to that request.
@property (readonly, nonatomic) NSString *requestId;

/// Type of the credit the request was made for.
///
/// @note Since Validatricks can manage multiple credit balances for every user, each with different
/// `creditType`. This has to be specified in the request.
@property (readonly, nonatomic) NSString *creditType;

/// The user's credit balance.
@property (readonly, nonatomic) NSUInteger credit;

/// Array of all consumable items user has previously consumed using credit of type \c creditType.
@property (readonly, nonatomic) NSArray<BZRConsumableItemDescriptor *> *consumedItems;

@end

#pragma mark -
#pragma mark BZRConsumableTypesPriceInfo
#pragma mark -

/// Model representing Validatricks server response for a "get consumables prices" request.
@interface BZRConsumableTypesPriceInfo : BZRModel <MTLJSONSerializing>

/// Unique identifier of the request. Can be used later to collect logs related to that request.
@property (readonly, nonatomic) NSString *requestId;

/// Type of the credit the request was made for.
///
/// @note Since Validatricks can manage multiple credit balances for every user, each with different
/// `creditType`. This has to be specified in the request.
@property (readonly, nonatomic) NSString *creditType;

/// Dictionary mapping from consumable type to the credit it will cost the user if redeemed.
@property (readonly, nonatomic) NSDictionary<NSString *, NSNumber *> *consumableTypesPrices;

@end

#pragma mark -
#pragma mark BZRConsumedItemDescriptor
#pragma mark -

/// Model of an object describing a consumed item. It extends \c BZRConsumableItemDescriptor, as
/// a consumed item is necessarily a consumable item, and it adds properties relevant for consumed
/// items only.
@interface BZRConsumedItemDescriptor : BZRConsumableItemDescriptor

/// Units of credit deduced from user's balance to redeem this item.
@property (readonly, nonatomic) NSUInteger redeemedCredit;

@end

#pragma mark -
#pragma mark BZRRedeemConsumablesStatus
#pragma mark -

/// Model reperesenting Validatricks server response for a "redeem consumable items" request.
@interface BZRRedeemConsumablesStatus : BZRModel <MTLJSONSerializing>

/// Unique identifier of the request. Can be used later to collect logs related to that request.
@property (readonly, nonatomic) NSString *requestId;

/// Type of the credit the request was made for.
///
/// @note Since Validatricks can manage multiple credit balances for every user, each with different
/// `creditType`. This has to be specified in the request.
@property (readonly, nonatomic) NSString *creditType;

/// Credit of \c creditType left in the user's balance.
@property (readonly, nonatomic) NSUInteger currentCredit;

/// Array of items successfully consumed by this request, listing their IDs and prices.
///
/// @note For consumable items that were already consumed by the user prior to this request, the
/// \c redeemedCredit field will be \c 0.
@property (readonly, nonatomic) NSArray<BZRConsumedItemDescriptor *> *consumedItems;

@end

NS_ASSUME_NONNULL_END
