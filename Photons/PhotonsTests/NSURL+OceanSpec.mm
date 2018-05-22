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
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypeVideo));
  expect(url.ptn_oceanAssetSource).to.equal($(PTNOceanAssetSourcePixabay));
  expect(url.ptn_oceanSearchPhrase).to.equal(@"foo bar");
  expect(url.ptn_oceanPageNumber).to.equal(@1);
  expect(url.ptn_oceanAssetIdentifier).to.beNil();
  expect(url.ptn_bazaarIdentifier).to.beNil();
});

it(@"should initialize a correct album URL", ^{
  NSURL *url = [NSURL ptn_oceanAlbumURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypePhoto)
                                           phrase:@"foo bar" page:1337];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"album");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAlbum));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypePhoto));
  expect(url.ptn_oceanAssetSource).to.equal($(PTNOceanAssetSourcePixabay));
  expect(url.ptn_oceanSearchPhrase).to.equal(@"foo bar");
  expect(url.ptn_oceanPageNumber).to.equal(@1337);
  expect(url.ptn_oceanAssetIdentifier).to.beNil();
  expect(url.ptn_bazaarIdentifier).to.beNil();
});

it(@"should initialize a correct asset URL", ^{
  NSURL *url = [NSURL ptn_oceanAssetURLWithSource:$(PTNOceanAssetSourcePixabay)
                                        assetType:$(PTNOceanAssetTypePhoto)
                                       identifier:@"bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"asset");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAsset));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypePhoto));
  expect(url.ptn_oceanAssetSource).to.equal($(PTNOceanAssetSourcePixabay));
  expect(url.ptn_oceanSearchPhrase).to.beNil();
  expect(url.ptn_oceanPageNumber).to.beNil();
  expect(url.ptn_oceanAssetIdentifier).to.equal(@"bar");
  expect(url.ptn_bazaarIdentifier).to.equal(@"com.lightricks.Photons.Ocean.pixabay.image.bar");
});

it(@"should initialize asset URL from bazaar identifier", ^{
  NSURL *url = [NSURL ptn_oceanAssetURLWithBazaarIdentifier:
                @"com.lightricks.Photons.Ocean.pixabay.video.bar"];

  expect(url.scheme).to.equal([NSURL ptn_oceanScheme]);
  expect(url.host).to.equal(@"asset");
  expect(url.ptn_oceanURLType).to.equal($(PTNOceanURLTypeAsset));
  expect(url.ptn_oceanAssetType).to.equal($(PTNOceanAssetTypeVideo));
  expect(url.ptn_oceanAssetSource).to.equal($(PTNOceanAssetSourcePixabay));
  expect(url.ptn_oceanSearchPhrase).to.beNil();
  expect(url.ptn_oceanPageNumber).to.beNil();
  expect(url.ptn_oceanAssetIdentifier).to.equal(@"bar");
  expect(url.ptn_bazaarIdentifier).to.equal(@"com.lightricks.Photons.Ocean.pixabay.video.bar");
});

it(@"should have an invalid Ocean URL type when URL has non-Ocean scheme", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_oceanURLType).to.beNil();
});

it(@"should have an invalid Ocean asset type when URL has non-Ocean scheme", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_oceanAssetType).to.beNil();
});

it(@"should have an invalid bazaar identifier when URL has non-Ocean scheme", ^{
  expect([NSURL URLWithString:@"http://foo"].ptn_bazaarIdentifier).to.beNil();
});

SpecEnd
