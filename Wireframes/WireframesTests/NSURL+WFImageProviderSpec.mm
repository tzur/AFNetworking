// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+WFImageProvider.h"

#import <LTKit/UIColor+Utilities.h>

SpecBegin(NSURL_WFImageProvider)

it(@"should append image size", ^{
  NSURL *url = [NSURL URLWithString:@"foo"];
  NSURL *urlWithSize = [url wf_URLWithImageSize:CGSizeMake(2, 1)];
  expect(urlWithSize.absoluteString).to.equal(@"foo?width=2&height=1");
});

it(@"should append image color", ^{
  NSURL *url = [NSURL URLWithString:@"foo"];
  NSURL *urlWithSize = [url wf_URLWithImageColor:[UIColor lt_colorWithHex:@"12345678"]];
  expect(urlWithSize.absoluteString).to.equal(@"foo?color=%2312345678");
});

it(@"should append line width", ^{
  NSURL *url = [NSURL URLWithString:@"foo"];
  NSURL *urlWithLineWidth = [url wf_URLWithImageLineWidth:1.5];
  expect(urlWithLineWidth.absoluteString).to.equal(@"foo?lineWidth=1.5");
});

SpecEnd
