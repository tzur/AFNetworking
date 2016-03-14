// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Gateway.h"

SpecBegin(NSURL_Gateway)

it(@"should create valid gateway album url", ^{
  NSURL *url = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  expect(url.scheme).to.equal([NSURL ptn_gatewayScheme]);
});

it(@"should return unique asset URL for each key", ^{
  NSURL *fooURL = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  NSURL *barURL = [NSURL ptn_gatewayAlbumURLWithKey:@"bar"];

  expect(fooURL.absoluteString).toNot.equal(barURL.absoluteString);
});

SpecEnd
