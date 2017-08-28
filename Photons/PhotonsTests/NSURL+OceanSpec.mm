// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSURL+Ocean.h"

#import "PTNOceanEnums.h"

SpecBegin(NSURL_Ocean)

it(@"should return the correct scheme", ^{
  expect([NSURL ptn_oceanScheme]).to.equal(@"com.lightricks.Photons.Ocean");
});

it(@"should initialize a correct album URL", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                           phrase:@"foo bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.query).to.equal(@"source=pixabay&phrase=foo%20bar");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
});

it(@"should initialize a correct album URL with no phrase", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                           phrase:nil];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.query).to.equal(@"source=pixabay");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
});

it(@"should initialize a correct asset URL", ^{
  NSURL *url = [NSURL ptn_oceanAssetURLWithSource:$(PTNOceanAssetSourcePixabay)
                                       identifier:@"bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"asset");
  expect(url.query).to.equal(@"id=bar&source=pixabay");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAsset));
});

it(@"should have an invalid Ocean URL type", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_oceanURLType).to.beNil();
});

SpecEnd
