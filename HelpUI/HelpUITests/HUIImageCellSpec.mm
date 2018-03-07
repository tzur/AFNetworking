// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIImageCell.h"

#import <LTKit/LTImageLoader.h>

#import "HUIBoxView.h"
#import "HUIItem.h"

SpecBegin(HUIImageCell)

__block HUIImageCell *cell;
__block LTImageLoader *imageLoader;

beforeEach(^{
  imageLoader = OCMClassMock(LTImageLoader.class);
  [HUISettings instance].imageLoader = imageLoader;
  cell = [[HUIImageCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
});

afterEach(^{
  imageLoader = nil;
  [HUISettings instance].imageLoader = nil;
  cell = nil;
});

it(@"should initialize properly", ^{
  expect([cell wf_viewForAccessibilityIdentifier:@"Image"]).to.beKindOf(UIImageView.class);
  expect(cell.item).to.beNil();
});

context(@"properties", ^{
  __block UIImageView *view;
  __block HUIImageItem *item;

  beforeEach(^{
    view = (UIImageView *)[cell wf_viewForAccessibilityIdentifier:@"Image"];

    auto dict = @{
      @"type": @"image",
      @"title": @"title",
      @"body": @"body",
      @"icon_url": @"icon",
      @"image": @"image",
    };
    item = [MTLJSONAdapter modelOfClass:HUIImageItem.class fromJSONDictionary:dict error:nil];
  });

  it(@"should set box title correctly", ^{
    cell.item = item;
    expect(cell.boxView.title).to.equal(@"title");
  });

  it(@"should set box body correctly", ^{
    cell.item = item;
    expect(cell.boxView.body).to.equal(@"body");
  });

  it(@"should set box icon URL correctly", ^{
    cell.item = item;
    expect(cell.boxView.iconURL).to.equal([NSURL URLWithString:@"icon"]);
  });

  it(@"should request correct image", ^{
    cell.item = item;
    OCMVerify([imageLoader imageNamed:@"image"]);
  });

  it(@"should show content image", ^{
    auto image = WFCreateBlankImage(1, 1);
    OCMStub([imageLoader imageNamed:@"image"]).andReturn(image);

    cell.item = item;
    expect(view.image).to.equal(image);
  });
});

SpecEnd
