// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksModels.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRValidatricksErrorInfo
#pragma mark -

@implementation BZRValidatricksErrorInfo

/// Error code reported by Validatricks in response to a redeem request in case the user does not
/// have enough credit to complete the request.
static NSString * const kNotEnoughCreditError = @"NotEnoughCredit";

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys =
        [NSSet setWithObject:@instanceKeypath(BZRValidatricksErrorInfo, message)];
  });

  return optionalPropertyKeys;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksErrorInfo, requestId): @"requestId",
    @instanceKeypath(BZRValidatricksErrorInfo, error): @"error",
    @instanceKeypath(BZRValidatricksErrorInfo, message): @"message"
  };
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
  // If this is an error stating the user does not have enough credit to complete the redeem request
  // as it was made, parse the \c JSONDictionary as a \c BZRValidatricksNotEnoughCreditErrorInfo.
  if ([JSONDictionary[@"error"] isEqualToString:kNotEnoughCreditError]) {
    return [BZRValidatricksNotEnoughCreditErrorInfo class];
  }

  return self;
}

@end

#pragma mark -
#pragma mark BZRValidatricksNotEnoughCreditErrorInfo
#pragma mark -

@implementation BZRValidatricksNotEnoughCreditErrorInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRValidatricksNotEnoughCreditErrorInfo, creditType): @"creditType",
    @instanceKeypath(BZRValidatricksNotEnoughCreditErrorInfo, currentCredit): @"currentCredit",
    @instanceKeypath(BZRValidatricksNotEnoughCreditErrorInfo, requiredCredit): @"requiredCredit"
  }];
}

@end

#pragma mark -
#pragma mark BZRConsumableItemDescriptor
#pragma mark -

@implementation BZRConsumableItemDescriptor

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRConsumableItemDescriptor, consumableType): @"consumableType",
    @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): @"consumableItemId"
  };
}

- (instancetype)initWithConsumableItemId:(NSString *)consumableItemId
                                  ofType:(NSString *)consumableType {
  if (self = [super init]) {
    _consumableItemId = [consumableItemId copy];
    _consumableType = [consumableType copy];
  }
  return self;
}

@end

#pragma mark -
#pragma mark BZRUserCreditStatus
#pragma mark -

@implementation BZRUserCreditStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRUserCreditStatus, requestId): @"requestId",
    @instanceKeypath(BZRUserCreditStatus, creditType): @"creditType",
    @instanceKeypath(BZRUserCreditStatus, credit): @"credit",
    @instanceKeypath(BZRUserCreditStatus, consumedItems): @"consumedItems"
  };
}

+ (NSValueTransformer *)consumedItemsJSONTransformer {
  return [NSValueTransformer
          mtl_JSONArrayTransformerWithModelClass:BZRConsumableItemDescriptor.class];
}

@end

#pragma mark -
#pragma mark BZRConsumableTypesPriceInfo
#pragma mark -

@implementation BZRConsumableTypesPriceInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRConsumableTypesPriceInfo, requestId): @"requestId",
    @instanceKeypath(BZRConsumableTypesPriceInfo, creditType): @"creditType",
    @instanceKeypath(BZRConsumableTypesPriceInfo, consumableTypesPrices): @"consumableTypesPrices"
  };
}

@end

#pragma mark -
#pragma mark BZRConsumedItemDescriptor
#pragma mark -

@implementation BZRConsumedItemDescriptor

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
    @instanceKeypath(BZRConsumedItemDescriptor, redeemedCredit): @"redeemedCredit"
  }];
}

@end

#pragma mark -
#pragma mark BZRRedeemConsumablesStatus
#pragma mark -

@implementation BZRRedeemConsumablesStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
    @instanceKeypath(BZRRedeemConsumablesStatus, creditType): @"creditType",
    @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @"currentCredit",
    @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @"consumedItems"
  };
}

+ (NSValueTransformer *)consumedItemsJSONTransformer {
  return [MTLValueTransformer
          mtl_JSONArrayTransformerWithModelClass:BZRConsumedItemDescriptor.class];
}

@end

NS_ASSUME_NONNULL_END
