// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

SpecBegin(PTNImageFetchOptions)

it(@"should create new fetch options", ^{
  PTNImageFetchOptions *options = [PTNImageFetchOptions
                                   optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                   resizeMode:PTNImageResizeModeFast];

  expect(options.deliveryMode).to.equal(PTNImageDeliveryModeFast);
  expect(options.resizeMode).to.equal(PTNImageResizeModeFast);
});

SpecEnd
