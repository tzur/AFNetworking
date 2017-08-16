// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanEnums.h"

SpecBegin(PTNOceanEnums)

it(@"should return valid identifiers for all sources", ^{
  [PTNOceanAssetSource enumerateEnumUsingBlock:^(PTNOceanAssetSource *source) {
    expect(source.identifier).toNot.beNil();
  }];
});

SpecEnd
