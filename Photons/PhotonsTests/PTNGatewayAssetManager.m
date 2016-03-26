// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAssetManager.h"

#import "NSError+Photons.h"
#import "NSURL+Gateway.h"
#import "PTNGatewayAlbumDescriptor.h"
#import "PTNGatewayTestUtils.h"
#import "PTNImageFetchOptions.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNGatewayAssetManager)

__block PTNGatewayAlbumDescriptor *fooDescriptor;
__block PTNGatewayAlbumDescriptor *barDescriptor;
__block PTNGatewayAssetManager *manager;

beforeEach(^{
  fooDescriptor = PTNGatewayCreateAlbumDescriptor(@"foo", [[RACSignal alloc] init],
                                                  [[RACSignal alloc] init]);
  barDescriptor = PTNGatewayCreateAlbumDescriptor(@"bar", [[RACSignal alloc] init],
                                                  [[RACSignal alloc] init]);

  NSSet *descriptors = [NSSet setWithArray:@[fooDescriptor, barDescriptor]];
  manager = [[PTNGatewayAssetManager alloc] initWithDescriptors:descriptors];
});

context(@"album fetching", ^{
  it(@"should fetch album of registered for asset", ^{
    NSURL *url = fooDescriptor.ptn_identifier;

    expect([manager fetchAlbumWithURL:url]).to.equal(fooDescriptor.albumSignal);
  });

  it(@"should return error for invalid URLs", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.bar"];

    expect([manager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should return error for valid unregistered URLs", ^{
    NSURL *url = [NSURL ptn_gatewayAlbumURLWithKey:@"baz"];

    expect([manager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

context(@"asset fetching", ^{
  it(@"should fetch asset of registered for asset", ^{
    NSURL *url = fooDescriptor.ptn_identifier;

    expect([manager fetchAssetWithURL:url]).to.sendValues(@[fooDescriptor]);
  });

  it(@"should return error for invalid URLs", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.bar"];

    expect([manager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should return error for valid unregistered URLs", ^{
    NSURL *url = [NSURL ptn_gatewayAlbumURLWithKey:@"baz"];

    expect([manager fetchAssetWithURL:url]).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;

  beforeEach(^{
    resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    options = OCMClassMock([PTNImageFetchOptions class]);
  });

  it(@"should fetch image of registered for asset", ^{
    RACSignal *values = [manager fetchImageWithDescriptor:fooDescriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).to.equal(fooDescriptor.imageSignal);
  });

  it(@"should return error for invalid descriptors", ^{
    id<PTNDescriptor> descriptor = OCMProtocolMock(@protocol(PTNDescriptor));

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should return error for valid unregistered descriptors", ^{
    id<PTNDescriptor> descriptor = PTNGatewayCreateAlbumDescriptor(@"baz", nil, nil);

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

SpecEnd
