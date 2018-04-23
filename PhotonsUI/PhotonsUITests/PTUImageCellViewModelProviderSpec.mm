// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModelProvider.h"

#import <Photons/PTNAssetManager.h>
#import <Photons/PTNImageFetchOptions.h>

#import "PTNTestUtils.h"
#import "PTUImageCellViewModel.h"

SpecBegin(PTUImageCellViewModelProvider)

__block id<PTNAssetManager> assetManager;
__block PTNImageFetchOptions *options;
__block id<PTNDescriptor> descriptor;

beforeEach(^{
  assetManager = OCMProtocolMock(@protocol(PTNAssetManager));
  options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeHighQuality
                                               resizeMode:PTNImageResizeModeExact
                                          includeMetadata:NO];
  descriptor = PTNCreateDescriptor([NSURL URLWithString:@"http://www.foo.com"], @"foo", 0, nil);
});

it(@"should return correct view model when created with options", ^{
  PTUImageCellViewModelProvider *provider =
      [[PTUImageCellViewModelProvider alloc] initWithAssetManager:assetManager
                                                imageFetchOptions:options];

  PTUImageCellViewModel *viewModel =
      (PTUImageCellViewModel *)[provider viewModelForDescriptor:descriptor];
  expect(viewModel.assetManager).to.equal(assetManager);
  expect(viewModel.descriptor).to.equal(descriptor);
  expect(viewModel.imageFetchOptions).to.equal(options);
});

it(@"should return correct view model when created with default options", ^{
  PTUImageCellViewModelProvider *provider =
      [[PTUImageCellViewModelProvider alloc] initWithAssetManager:assetManager];

  PTNImageFetchOptions *defaultOptions =
      [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeOpportunistic
                                         resizeMode:PTNImageResizeModeFast
                                    includeMetadata:NO];

  PTUImageCellViewModel *viewModel =
      (PTUImageCellViewModel *)[provider viewModelForDescriptor:descriptor];
  expect(viewModel.assetManager).to.equal(assetManager);
  expect(viewModel.descriptor).to.equal(descriptor);
  expect(viewModel.imageFetchOptions).to.equal(defaultOptions);
});

SpecEnd
