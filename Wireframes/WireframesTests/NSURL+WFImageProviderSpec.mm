// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+WFImageProvider.h"

#import "UIColor+Utilities.h"

SpecBegin(NSURL_WFImageProvider)

it(@"should append image size", ^{
  NSURL *url = [NSURL URLWithString:@"foo"];
  NSURL *urlWithSize = [url wf_URLWithImageSize:CGSizeMake(2, 1)];
  expect(urlWithSize.absoluteString).to.equal(@"foo?width=2&height=1");
});

it(@"should append image color", ^{
  NSURL *url = [NSURL URLWithString:@"foo"];
  NSURL *urlWithSize = [url wf_URLWithImageColor:[UIColor wf_colorWithHex:@"12345678"]];
  expect(urlWithSize.absoluteString).to.equal(@"foo?color=%2312345678");
});

SpecEnd
