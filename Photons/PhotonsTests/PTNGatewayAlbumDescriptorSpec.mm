// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import "NSURL+Gateway.h"
#import "PTNImageFetchOptions.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNStaticImageAsset.h"

SpecBegin(PTNGatewayAlbumDescriptor)

__block id<PTNResizingStrategy> resizingStrategy;
__block PTNImageFetchOptions *fetchOptions;

beforeEach(^{
  resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
  fetchOptions = OCMClassMock(PTNImageFetchOptions.class);
});

it(@"should initialize a gateway album descriptor with a signal block", ^{
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  RACSignal *imageSignal = [[RACSignal alloc] init];
  RACSignal *albumSignal = [[RACSignal alloc] init];
  __block id<PTNResizingStrategy> givenResizingStrategy;
  __block PTNImageFetchOptions *givenFetchOptions;

  PTNGatewayAlbumDescriptor *descriptor =
      [[PTNGatewayAlbumDescriptor alloc] initWithIdentifier:identifier localizedTitle:@"foo"
      imageSignalBlock:^RACSignal *(id<PTNResizingStrategy> resizingStrategy,
                                    PTNImageFetchOptions *options) {
        givenResizingStrategy = resizingStrategy;
        givenFetchOptions = options;
        return imageSignal;
      } albumSignal:albumSignal];

  expect(descriptor.ptn_identifier).to.equal(identifier);
  expect(descriptor.localizedTitle).to.equal(@"foo");
  expect(descriptor.imageSignalBlock(resizingStrategy, fetchOptions)).to.equal(imageSignal);
  expect(descriptor.albumSignal).to.equal(albumSignal);
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);

  expect(givenResizingStrategy).to.equal(resizingStrategy);
  expect(givenFetchOptions).to.equal(fetchOptions);
});

it(@"should initialize a gateway album descriptor with a signal", ^{
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  RACSignal *imageSignal = [[RACSignal alloc] init];
  RACSignal *albumSignal = [[RACSignal alloc] init];

  PTNGatewayAlbumDescriptor *descriptor =
      [[PTNGatewayAlbumDescriptor alloc] initWithIdentifier:identifier localizedTitle:@"foo"
                                                imageSignal:imageSignal albumSignal:albumSignal];
  expect(descriptor.ptn_identifier).to.equal(identifier);
  expect(descriptor.localizedTitle).to.equal(@"foo");
  expect(descriptor.imageSignalBlock(resizingStrategy, fetchOptions)).to.equal(imageSignal);
  expect(descriptor.albumSignal).to.equal(albumSignal);
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);
});

it(@"should initialize a gateway album descriptor with a static image", ^{
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  UIImage *image = [[UIImage alloc] init];
  RACSignal *albumSignal = [[RACSignal alloc] init];

  PTNGatewayAlbumDescriptor *descriptor =
      [[PTNGatewayAlbumDescriptor alloc] initWithIdentifier:identifier localizedTitle:@"foo"
                                                      image:image albumSignal:albumSignal];
  expect(descriptor.ptn_identifier).to.equal(identifier);
  expect(descriptor.localizedTitle).to.equal(@"foo");
  id<PTNImageAsset> asset = [[PTNStaticImageAsset alloc] initWithImage:image];
  PTNProgress *progress = [[PTNProgress alloc] initWithResult:asset];
  expect(descriptor.imageSignalBlock(resizingStrategy, fetchOptions)).to.sendValues(@[progress]);
  expect(descriptor.albumSignal).to.equal(albumSignal);
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);
});

SpecEnd
