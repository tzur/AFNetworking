// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "NSURL+DaVinci.h"

SpecBegin(NSURL_DaVinci)

it(@"should return the correct URL scheme", ^{
  expect([NSURL dvn_scheme]).to.equal(@"com.lightricks.DaVinci");
});

it(@"should return the correct texture URLs", ^{
  expect([NSURL dvn_urlOfSourceTexture])
      .to.equal([NSURL URLWithString:@"com.lightricks.DaVinci://texture?id=source"]);
  expect([NSURL dvn_urlOfEdgeAvoidanceTexture])
      .to.equal([NSURL URLWithString:@"com.lightricks.DaVinci://texture?id=edgeAvoidance"]);
  NSString *urlString = @"com.lightricks.DaVinci://texture?width=1&height=1&pixel_components=R&"
                         "pixel_data_type=8Unorm&color=%23FF&premultiplied=1";
  expect([NSURL dvn_urlOfOneByOneWhiteSingleChannelByteTexture])
      .to.equal([NSURL URLWithString:urlString]);
  urlString = @"com.lightricks.DaVinci://texture?width=1&height=1&pixel_components=RGBA&"
               "pixel_data_type=8Unorm&color=%23FF&premultiplied=0";
  expect([NSURL dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture])
      .to.equal([NSURL URLWithString:urlString]);
});

SpecEnd
