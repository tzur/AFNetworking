// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAlbumDescriptor.h"

#import "NSURL+Gateway.h"

SpecBegin(PTNGatewayAlbumDescriptor)

it(@"should initialize a gateway album descriptor", ^{
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  UIImage *image = [[UIImage alloc] init];
  RACSignal *albumSignal = [[RACSignal alloc] init];

  PTNGatewayAlbumDescriptor *desc =
      [[PTNGatewayAlbumDescriptor alloc] initWithIdentifier:identifier localizedTitle:@"foo"
                                                      image:image albumSignal:albumSignal];
  expect(desc.ptn_identifier).to.equal(identifier);
  expect(desc.localizedTitle).to.equal(@"foo");
  expect(desc.image).to.equal(image);
  expect(desc.albumSignal).to.equal(albumSignal);
  expect(desc.assetCount).to.equal(PTNNotFound);
});

SpecEnd
