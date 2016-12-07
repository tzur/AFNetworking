// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNVideoFetchOptions.h"

SpecBegin(PTNVideoFetchOptions)

it(@"should create new fetch options", ^{
  PTNVideoFetchOptions *options =
      [PTNVideoFetchOptions optionsWithDeliveryMode:PTNVideoDeliveryModeFastFormat];

  expect(options.deliveryMode).to.equal(PTNVideoDeliveryModeFastFormat);
});

SpecEnd
