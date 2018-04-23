// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayAssetManager.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "NSError+Photons.h"
#import "NSURL+Gateway.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNGatewayAlbumDescriptor.h"
#import "PTNGatewayTestUtils.h"
#import "PTNImageFetchOptions.h"
#import "PTNIncrementalChanges.h"
#import "PTNResizingStrategy.h"

SpecBegin(PTNGatewayAssetManager)

__block PTNGatewayAlbumDescriptor *fooDescriptor;
__block PTNGatewayAlbumDescriptor *barDescriptor;
__block PTNGatewayAssetManager *manager;

__block RACSubject *albumSignal;
__block RACSignal *imageSignal;

beforeEach(^{
  imageSignal = [RACSignal empty];
  albumSignal = [RACSubject subject];
  fooDescriptor = PTNGatewayCreateAlbumDescriptorWithSignal(@"foo", albumSignal, imageSignal);
  barDescriptor = PTNGatewayCreateAlbumDescriptorWithSignal(@"bar", albumSignal, imageSignal);

  NSSet *descriptors = [NSSet setWithArray:@[fooDescriptor, barDescriptor]];
  manager = [[PTNGatewayAssetManager alloc] initWithDescriptors:descriptors];
});

context(@"album fetching", ^{
  it(@"should fetch wrapped album of registered for asset", ^{
    NSURL *url = fooDescriptor.ptn_identifier;

    expect([manager fetchAlbumWithURL:url]).will.matchValue(0, ^BOOL(PTNAlbumChangeset *changeset) {
      id<LTRandomAccessCollection> assets = changeset.afterAlbum.assets;
      id<LTRandomAccessCollection> subalbums = changeset.afterAlbum.subalbums;
      id<PTNDescriptor> albumDescriptor = subalbums.firstObject;
      return !changeset.beforeAlbum &&
          !assets.count &&
          subalbums.count == 1 &&
          [manager fetchAlbumWithURL:albumDescriptor.ptn_identifier] == fooDescriptor.albumSignal;
    });
  });

  it(@"should send updateds to wrapped album whenever underlying album updates", ^{
    NSURL *url = fooDescriptor.ptn_identifier;
    LLSignalTestRecorder *recorder = [[manager fetchAlbumWithURL:url] testRecorder];

    expect(recorder).will.sendValuesWithCount(1);

    [albumSignal sendNext:OCMClassMock(PTNAlbumChangeset.class)];
    [albumSignal sendNext:OCMClassMock(PTNAlbumChangeset.class)];
    [albumSignal sendNext:OCMClassMock(PTNAlbumChangeset.class)];
    expect(recorder).will.sendValuesWithCount(4);

    expect(recorder).will.matchValue(3, ^BOOL(PTNAlbumChangeset *changeset) {
      id<LTRandomAccessCollection> assets = changeset.afterAlbum.assets;
      id<LTRandomAccessCollection> subalbums = changeset.afterAlbum.subalbums;
      id<PTNDescriptor> albumDescriptor = subalbums.firstObject;
      PTNIncrementalChanges *changes = [PTNIncrementalChanges changesWithRemovedIndexes:nil
          insertedIndexes:nil updatedIndexes:[NSIndexSet indexSetWithIndex:0] moves:nil];
      return changeset.beforeAlbum == changeset.afterAlbum &&
          !assets.count &&
          subalbums.count == 1 &&
          !changeset.assetChanges &&
          [changeset.subalbumChanges isEqual:changes] &&
          [manager fetchAlbumWithURL:albumDescriptor.ptn_identifier] == fooDescriptor.albumSignal;
    });
  });

  it(@"should fetch album of registered for asset when fetching with flattened URL", ^{
    NSURL *url = [NSURL ptn_flattenedGatewayAlbumURLWithKey:@"foo"];

    expect([manager fetchAlbumWithURL:url]).equal(fooDescriptor.albumSignal);
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

    expect([manager fetchDescriptorWithURL:url]).to.sendValues(@[fooDescriptor]);
  });

  it(@"should return error for invalid URLs", ^{
    NSURL *url = [NSURL URLWithString:@"http://www.foo.bar"];

    expect([manager fetchAlbumWithURL:url]).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should return error for valid unregistered URLs", ^{
    NSURL *url = [NSURL ptn_gatewayAlbumURLWithKey:@"baz"];

    expect([manager fetchDescriptorWithURL:url]).to.matchError(^BOOL(NSError *error) {
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

    expect(values).to.equal(imageSignal);
  });

  it(@"should return error for invalid descriptors", ^{
    id<PTNDescriptor> descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    OCMStub(descriptor.ptn_identifier).andReturn([NSURL URLWithString:@"foo://bar.com"]);

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });

  it(@"should return signal based on given parameters", ^{
    __block id<PTNResizingStrategy> givenResizingStrategy;
    __block PTNImageFetchOptions *givenOptions;
    PTNGatewayAlbumDescriptor *blockDescriptor = PTNGatewayCreateAlbumDescriptor(@"block",
        [RACSignal empty], ^RACSignal *(id<PTNResizingStrategy> resizingStrategy,
                                        PTNImageFetchOptions *options) {
          givenResizingStrategy = resizingStrategy;
          givenOptions = options;
          return imageSignal;
        });

    manager = [[PTNGatewayAssetManager alloc]
               initWithDescriptors:[NSSet setWithObject:blockDescriptor]];
    RACSignal *values = [manager fetchImageWithDescriptor:blockDescriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];
    expect(values).to.equal(imageSignal);
    expect(givenResizingStrategy).to.equal(resizingStrategy);
    expect(givenOptions).to.equal(options);
  });

  it(@"should return error for valid unregistered descriptors", ^{
    id<PTNDescriptor> descriptor = PTNGatewayCreateAlbumDescriptorWithSignal(@"baz",
                                                                             [RACSignal empty],
                                                                             [RACSignal empty]);

    RACSignal *values = [manager fetchImageWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];

    expect(values).to.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeInvalidURL;
    });
  });
});

context(@"AVAsset fetching", ^{
  __block PTNAVAssetFetchOptions *options;

  beforeEach(^{
    options = OCMClassMock([PTNImageFetchOptions class]);
  });

  it(@"should err", ^{
    RACSignal *values = [manager fetchAVAssetWithDescriptor:fooDescriptor options:options];

    expect(values).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeUnsupportedOperation;
    });
  });
});

it(@"should err when fetching image data", ^{
  RACSignal *values = [manager fetchImageDataWithDescriptor:fooDescriptor];

  expect(values).will.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeUnsupportedOperation;
  });
});

SpecEnd
