// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIBoxTopView.h"

SpecBegin(HUIBoxTopView)

__block HUIBoxTopView *view;
__block UILabel *titleLabel;
__block UILabel *bodyLabel;
__block UIImageView *iconImage;

beforeEach(^{
  view = [[HUIBoxTopView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  titleLabel = (UILabel *)[view wf_viewForAccessibilityIdentifier:@"Title"];
  bodyLabel = (UILabel *)[view wf_viewForAccessibilityIdentifier:@"Body"];
  iconImage = (UIImageView *)[view wf_viewForAccessibilityIdentifier:@"Icon"];
});

it(@"should create title, body and icon views", ^{
  expect(titleLabel).to.beKindOf(UILabel.class);
  expect(bodyLabel).to.beKindOf(UILabel.class);
  expect(iconImage).to.beKindOf(UIImageView.class);
});

it(@"should set title correctly", ^{
  view.title = @"title";
  [view layoutIfNeeded];

  expect(titleLabel.text).to.equal(@"TITLE");
});

it(@"should set body correctly", ^{
  view.body = @"body";
  [view layoutIfNeeded];

  expect(bodyLabel.text).to.equal(@"body");
});

it(@"should load icon image", ^{
  NSURL *iconURL = [NSURL URLWithString:@"icon"];
  UIImage *iconImage = WFCreateBlankImage(2, 1);

  id<WFImageProvider> imageProvider = OCMProtocolMock(@protocol(WFImageProvider));

  OCMStub([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return [url.path isEqual:iconURL.path];
  }]]).andReturn([RACSignal return:iconImage]);

  OCMStub([imageProvider imageWithURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
    return ![url.path isEqual:iconURL.path];
  }]]).andReturn([RACSignal error:nil]);

  WFLoggingImageProvider *loggingImageProvider = [[WFLoggingImageProvider alloc]
                                                  initWithImageProvider:imageProvider];
  LTBindObjectToProtocol(loggingImageProvider, @protocol(WFImageProvider));

  view.iconURL = iconURL;
  [view layoutIfNeeded];

  [loggingImageProvider waitUntilCompletion];
  expect(loggingImageProvider.images).to.contain(iconImage);
});

SpecEnd
