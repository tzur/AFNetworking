// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRStoreConfiguration

- (instancetype)initWithProductsListJSONFilePath:(LTPath *)productsListJSONFilePath {
  return [self initWithProductsListJSONFilePath:productsListJSONFilePath keychainAccessGroup:nil
                 expiredSubscriptionGracePeriod:7];
}

- (instancetype)initWithProductsListJSONFilePath:(LTPath __unused *)productsListJSONFilePath
    keychainAccessGroup:(nullable NSString __unused *)keychainAccessGroup
    expiredSubscriptionGracePeriod:(NSUInteger __unused)expiredSubscriptionGracePeriod {
  return [super init];
}

@end

NS_ASSUME_NONNULL_END
