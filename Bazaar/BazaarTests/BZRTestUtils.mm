// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTestUtils.h"

#import "BZRContentProviderParameters.h"
#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier) {
  NSDictionary *JSONProduct = @{
    @"identifier": identifier,
    @"productType": @"renewableSubscription",
    @"purchaseStatus": @"purchased",
    @"contentProviderParameters": @{}
  };

  return [MTLJSONAdapter modelOfClass:[BZRProduct class] fromJSONDictionary:JSONProduct error:NULL];
}

BZRProduct *BZRProductWithIdentifier(NSString *identifier) {
  NSDictionary *JSONProduct = @{
    @"identifier": identifier,
    @"productType": @"renewableSubscription",
    @"purchaseStatus": @"purchased",
  };

  return [MTLJSONAdapter modelOfClass:[BZRProduct class] fromJSONDictionary:JSONProduct error:NULL];
}

BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentProviderParameters *parameters) {
  BZRProduct *product = BZRProductWithIdentifier(identifier);
  return [product productWithContentProviderParameters:parameters error:NULL];
}

NS_ASSUME_NONNULL_END
