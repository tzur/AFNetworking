// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTestUtils.h"

#import "BZRContentFetcherParameters.h"
#import "BZRProduct.h"

NS_ASSUME_NONNULL_BEGIN

BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier) {
  return BZRProductWithIdentifierAndParameters(identifier,
                                               OCMClassMock([BZRContentFetcherParameters class]));
}

BZRProduct *BZRProductWithIdentifier(NSString *identifier) {
  return BZRProductWithIdentifierAndParameters(identifier, nil);
}

BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters) {
  NSDictionary *contentFetcherParametersDictionary = parameters ?
      @{@instanceKeypath(BZRProduct, contentFetcherParameters): parameters} : @{};
  NSDictionary *dictionaryValue = [@{
    @instanceKeypath(BZRProduct, identifier): identifier,
    @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
    @instanceKeypath(BZRProduct, purchaseStatus): $(BZRProductPurchaseStatusPurchased),
  } mtl_dictionaryByAddingEntriesFromDictionary:contentFetcherParametersDictionary];

  return [[BZRProduct alloc] initWithDictionary:dictionaryValue error:nil];
}

NS_ASSUME_NONNULL_END
