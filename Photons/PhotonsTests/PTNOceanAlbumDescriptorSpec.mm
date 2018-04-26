// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAlbumDescriptor.h"

#import "NSURL+Ocean.h"
#import "PTNOceanEnums.h"

SpecBegin(PTNOceanAlbumDescriptor)

__block NSURL *albumURL;
__block PTNOceanAlbumDescriptor *descriptor;

beforeEach(^{
  albumURL = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                      assetType:$(PTNOceanAssetTypeVideo) phrase:@"foo" page:0];
  descriptor = [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:albumURL];
});

it(@"should raise when initializing with invalid search URL", ^{
  expect(^{
    PTNOceanAlbumDescriptor __unused *descriptor =
        [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:[NSURL URLWithString:@"http://foo"]];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should have correct attributes", ^{
  expect(descriptor.assetCount).to.equal(PTNNotFound);
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
  expect(descriptor.ptn_identifier).to.equal(albumURL);
  expect(descriptor.localizedTitle).to.beNil();
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);
});

context(@"NSObject", ^{
  __block PTNOceanAlbumDescriptor *equalDescriptor;

  beforeEach(^{
    equalDescriptor = [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:albumURL];
  });

  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([descriptor isEqual:descriptor]).to.beTruthy();
    });

    it(@"should return YES when comparing to equal but not identical object", ^{
      expect(descriptor).toNot.beIdenticalTo(equalDescriptor);
      expect([descriptor isEqual:equalDescriptor]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([descriptor isEqual:nil]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([descriptor isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to different objects", ^{
      NSURL *url =
          [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                   assetType:$(PTNOceanAssetTypeVideo) phrase:@"bar" page:0];
      PTNOceanAlbumDescriptor *differentDescriptor =
          [[PTNOceanAlbumDescriptor alloc] initWithAlbumURL:url];

      expect([differentDescriptor isKindOfClass:[descriptor class]]);
      expect([descriptor isEqual:differentDescriptor]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal but not identical objects", ^{
      expect(descriptor).toNot.beIdenticalTo(equalDescriptor);
      expect(descriptor.hash).to.equal(equalDescriptor.hash);
    });
  });
});

SpecEnd
