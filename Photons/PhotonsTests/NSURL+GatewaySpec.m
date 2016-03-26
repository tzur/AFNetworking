// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Gateway.h"

SpecBegin(NSURL_Gateway)

it(@"should create valid gateway album url", ^{
  NSURL *url = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  expect(url.scheme).to.equal([NSURL ptn_gatewayScheme]);
  expect([url ptn_gatewayKey]).to.equal(@"foo");
});

it(@"should return unique asset URL for each key", ^{
  NSURL *fooURL = [NSURL ptn_gatewayAlbumURLWithKey:@"foo"];
  NSURL *barURL = [NSURL ptn_gatewayAlbumURLWithKey:@"bar"];

  expect(fooURL.absoluteString).toNot.equal(barURL.absoluteString);
});

it(@"should return nil key for invalid URLs", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  expect(url.scheme).toNot.equal([NSURL ptn_gatewayScheme]);
  expect([url ptn_gatewayKey]).to.beNil();
});

SpecEnd
