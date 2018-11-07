// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

SpecBegin(PTNImageFetchOptions)

it(@"should create fetch options with default values", ^{
  PTNImageFetchOptions *options = [[PTNImageFetchOptions alloc] init];
  expect(options.deliveryMode).to.equal(PTNImageDeliveryModeHighQuality);
  expect(options.resizeMode).to.equal(PTNImageResizeModeExact);
  expect(options.includeMetadata).to.beFalsy();
});

it(@"should create new fetch options", ^{
  PTNImageFetchOptions *options = [PTNImageFetchOptions
                                   optionsWithDeliveryMode:PTNImageDeliveryModeFast
                                   resizeMode:PTNImageResizeModeFast includeMetadata:YES];

  expect(options.deliveryMode).to.equal(PTNImageDeliveryModeFast);
  expect(options.resizeMode).to.equal(PTNImageResizeModeFast);
  expect(options.includeMetadata).to.beTruthy();
});

SpecEnd
