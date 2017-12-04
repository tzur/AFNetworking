// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+TinCan.h"

SpecBegin(NSURL_TinCan)

it(@"should return a valid message directory url", ^{
  auto _Nullable url = [NSURL tin_messageDirectoryURLWithAppGroup:kTINTestHostAppGroupID
                                                           scheme:@"foo" identifier:[NSUUID UUID]];
  expect(url.path).notTo.beNil();
});

it(@"should return nil for invalid app group id", ^{
  auto _Nullable url = [NSURL tin_messageDirectoryURLWithAppGroup:@"foo" scheme:@"bar"
                                                       identifier:[NSUUID UUID]];
  expect(url).to.beNil();
});

it(@"should return a valid app group directory", ^{
  auto _Nullable url = [NSURL tin_appGroupDirectoryURL:kTINTestHostAppGroupID];
  expect(url.path).notTo.beNil();
});

it(@"should return nil for invalid app group", ^{
  auto _Nullable url = [NSURL tin_appGroupDirectoryURL:@"foo"];
  expect(url).to.beNil();
});

SpecEnd
