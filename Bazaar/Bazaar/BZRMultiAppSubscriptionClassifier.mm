// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppSubscriptionClassifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMultiAppSubscriptionClassifier ()

/// The service level marker that is used to identify multi-app subscriptions.
@property (readonly, nonatomic) NSString *multiAppServiceLevelMarker;

@end

@implementation BZRMultiAppSubscriptionClassifier

- (instancetype)initWithMultiAppServiceLevelMarker:(NSString *)multiAppServiceLevelMarker {
  if (self = [super init]) {
    _multiAppServiceLevelMarker = [multiAppServiceLevelMarker copy];
  }
  return self;
}

- (BOOL)isMultiAppSubscription:(NSString *)productIdentifier {
  // Product identifiers are assumed to have the following format:
  // "<Application Bundle ID>_<Subscription Group Name>_<Product Name>[_<Introudctory Discount>]",
  // otherwise \c NO is returned.
  auto productIdentifierComponents = [productIdentifier componentsSeparatedByString:@"_"];
  if (productIdentifierComponents.count < 3) {
    return NO;
  }

  auto productName = productIdentifierComponents[2];
  auto productNameAttributes = [productName componentsSeparatedByString:@"."];
  return [productNameAttributes containsObject:self.multiAppServiceLevelMarker];
}

@end

NS_ASSUME_NONNULL_END
