// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNVideoFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(PTNVideoFetchOptions_PhotoKit)

it(@"should create PhotoKit options from photons options", ^{
  PTNVideoFetchOptions *options =
      [PTNVideoFetchOptions optionsWithDeliveryMode:PTNVideoDeliveryModeFastFormat];
  PHVideoRequestOptions *photoKitOptions = [options photoKitOptions];

  expect(photoKitOptions.version).to.equal(PHVideoRequestOptionsVersionCurrent);
  expect(photoKitOptions.deliveryMode).to.equal(PHVideoRequestOptionsDeliveryModeFastFormat);
  expect(photoKitOptions.networkAccessAllowed).to.beTruthy();
  expect(photoKitOptions.progressHandler).to.beNil();
});

SpecEnd
