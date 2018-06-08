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
  NSString *urlString =
      @"com.lightricks.DaVinci://texture?id=1_x_1_white_single_channel_byte_texture";
  expect([NSURL dvn_urlOfOneByOneWhiteSingleChannelByteTexture])
      .to.equal([NSURL URLWithString:urlString]);
  urlString = @"com.lightricks.DaVinci://texture?id=1_x_1_white_non_premultiplied_rgba_texture";
  expect([NSURL dvn_urlOfOneByOneWhiteNonPremultipliedRGBAByteTexture])
      .to.equal([NSURL URLWithString:urlString]);
});

SpecEnd
