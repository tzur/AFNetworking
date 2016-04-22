// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFPaintCodeImageProvider.h"

#import <LTKit/LTCGExtensions.h>

#import "UIColor+Utilities.h"
#import "WFFakePaintCodeModule.h"

SpecBegin(WFPaintCodeImageProvider)

__block WFPaintCodeImageProvider *provider;
__block id paintCodeModule;

beforeEach(^{
  provider = [[WFPaintCodeImageProvider alloc] init];
  paintCodeModule = OCMClassMock([WFFakePaintCodeModule class]);
});

afterEach(^{
  provider = nil;
  paintCodeModule = nil;
});

context(@"errors", ^{
  it(@"should send error for URL with nonexistent module", ^{
    NSURL *url = [NSURL URLWithString:@"paintcode://NoSuchModule/ImageA?width=1&height=1"];
    RACSignal *image = [provider imageWithURL:url];
    expect(image).will.error();
  });

  it(@"should send error for URL with wrong scheme", ^{
    NSURL *url = [NSURL URLWithString:@"gopher://WFFakePaintCodeModule/ImageA?width=1&height=1"];
    RACSignal *image = [provider imageWithURL:url];
    expect(image).will.error();
  });

  it(@"should send error for URL with nonexistent image", ^{
    NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/"
                  "NoSuchImage?width=1&height=1"];
    RACSignal *image = [provider imageWithURL:url];
    expect(image).will.error();
  });

  it(@"should send error for URL without image size", ^{
    RACSignal *imageWithoutWidthAndHeight =
        [provider imageWithURL:[NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA"]];
    expect(imageWithoutWidthAndHeight).will.error();

    RACSignal *imageWithoutHeight =
        [provider imageWithURL:[NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?"
                                "width=1"]];
    expect(imageWithoutHeight).will.error();

    RACSignal *imageWithoutWidth =
        [provider imageWithURL:[NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?"
                                "height=1"]];
    expect(imageWithoutWidth).will.error();
  });

  it(@"should send error for URL with unsupported parameter", ^{
    RACSignal *imageUnknownParameter =
        [provider imageWithURL:[NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?"
                                "width=1&height=1&no_such_parameter=ever"]];
    expect(imageUnknownParameter).will.error();

    RACSignal *imageUnsupportedParameter =
        [provider imageWithURL:[NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?"
                                "width=1&height=1&color=a0a0a0"]];
    expect(imageUnsupportedParameter).will.error();
  });
});

it(@"should send image with correct size", ^{
  NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?width=2&height=1"];
  RACSignal *image = [provider imageWithURL:url];

  expect(image).will.matchValue(0, ^BOOL(UIImage *value) {
    return value.size == CGSizeMake(2, 1);
  });
});

it(@"should pass correct query parameters", ^{
  UIColor *expectedColor = [UIColor wf_colorWithHex:@"12345678"];
  OCMExpect([paintCodeModule drawImageCWithFrame:CGRectMake(0, 0, 2, 1) color:expectedColor
                                       lineWidth:10]);
  NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageC?"
                "width=2&height=1&color=12345678&lineWidth=10"];
  RACSignal *image = [provider imageWithURL:url];

  expect(image).will.sendValuesWithCount(1);
});

it(@"should complete after sending image", ^{
  NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?width=2&height=1"];
  RACSignal *image = [provider imageWithURL:url];
  expect(image).will.sendValuesWithCount(1);
});

it(@"should deallocate after signal completes", ^{
  __weak id<WFImageProvider> weakProvider = nil;
  @autoreleasepool {
    id<WFImageProvider> provider = [[WFPaintCodeImageProvider alloc] init];
    weakProvider = provider;
    NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?width=2&height=1"];
    RACSignal *image = [provider imageWithURL:url];
    expect(image).will.complete();
  }
  expect(weakProvider).to.beNil();
});

SpecEnd
