// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSURL+Ocean.h"

#import <LTKit/NSURL+Query.h>

#import "PTNOceanEnums.h"

SpecBegin(NSURL_Ocean)

it(@"should return the correct scheme", ^{
  expect([NSURL ptn_oceanScheme]).to.equal(@"com.lightricks.Photons.Ocean");
});

it(@"should initialize a correct album URL with no page argument", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypeVideo)
                                           phrase:@"foo bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.lt_queryDictionary).to.equal(@{
    @"source": @"pixabay",
    @"type": @"PTNOceanAssetTypeVideo",
    @"phrase": @"foo bar",
    @"page": @"1"
  });
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypeVideo));
});

it(@"should initialize a correct album URL", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypePhoto)
                                           phrase:@"foo bar" page:1337];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.lt_queryDictionary).to.equal(@{
    @"source": @"pixabay",
    @"type": @"PTNOceanAssetTypePhoto",
    @"phrase": @"foo bar",
    @"page": @"1337"
  });
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypePhoto));
});

it(@"should initialize a correct album URL with no phrase", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypeVideo)
                                           phrase:nil page:1337];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.lt_queryDictionary).to.equal(@{
    @"source": @"pixabay",
    @"type": @"PTNOceanAssetTypeVideo",
    @"page": @"1337"
  });
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypeVideo));
});

it(@"should initialize a correct asset URL", ^{
  NSURL *url = [NSURL ptn_oceanAssetURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypePhoto)
                                       identifier:@"bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"asset");
  expect(url.lt_queryDictionary).to.equal(@{
    @"id": @"bar",
    @"source": @"pixabay",
    @"type": @"PTNOceanAssetTypePhoto"
  });
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAsset));
});

it(@"should have an invalid Ocean URL type", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_oceanURLType).to.beNil();
});

it(@"should have an invalid Ocean asset type", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_oceanAssetType).to.beNil();
});

SpecEnd
