// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAVAssetFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

SpecBegin(PTNAVAssetFetchOptions_PhotoKit)

it(@"should create PhotoKit options from photons options", ^{
  PTNAVAssetFetchOptions *options =
      [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNVideoDeliveryModeFastFormat];
  PHVideoRequestOptions *photoKitOptions = [options photoKitOptions];

  expect(photoKitOptions.version).to.equal(PHVideoRequestOptionsVersionCurrent);
  expect(photoKitOptions.deliveryMode).to.equal(PHVideoRequestOptionsDeliveryModeFastFormat);
  expect(photoKitOptions.networkAccessAllowed).to.beTruthy();
  expect(photoKitOptions.progressHandler).to.beNil();
});

SpecEnd
