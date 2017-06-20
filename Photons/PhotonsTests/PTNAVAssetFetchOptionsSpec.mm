// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAVAssetFetchOptions.h"

SpecBegin(PTNAVAssetFetchOptions)

it(@"should create new fetch options", ^{
  PTNAVAssetFetchOptions *options =
      [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeFastFormat];

  expect(options.deliveryMode).to.equal(PTNAVAssetDeliveryModeFastFormat);
});

SpecEnd
