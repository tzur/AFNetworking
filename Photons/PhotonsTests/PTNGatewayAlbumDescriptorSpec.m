// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import "NSURL+Gateway.h"
#import "PTNStaticImageAsset.h"

SpecBegin(PTNGatewayAlbumDescriptor)

it(@"should initialize a gateway album descriptor with a signal", ^{
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  RACSignal *imageSignal = [[RACSignal alloc] init];
  RACSignal *albumSignal = [[RACSignal alloc] init];

  PTNGatewayAlbumDescriptor *descriptor =
      [[PTNGatewayAlbumDescriptor alloc] initWithIdentifier:identifier localizedTitle:@"foo"
                                                imageSignal:imageSignal albumSignal:albumSignal];
  expect(descriptor.ptn_identifier).to.equal(identifier);
  expect(descriptor.localizedTitle).to.equal(@"foo");
  expect(descriptor.imageSignal).to.equal(imageSignal);
  expect(descriptor.albumSignal).to.equal(albumSignal);
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.descriptorCapabilites).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilites).to.equal(PTNAlbumDescriptorCapabilityNone);
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
  expect(descriptor.imageSignal).to.sendValues(@[[[PTNStaticImageAsset alloc] initWithImage:image]]);
  expect(descriptor.albumSignal).to.equal(albumSignal);
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.descriptorCapabilites).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.albumDescriptorCapabilites).to.equal(PTNAlbumDescriptorCapabilityNone);
});

SpecEnd
