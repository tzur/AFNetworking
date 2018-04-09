// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageLoader.h"

SpecBegin(WFImageLoader)

context(@"default configuration", ^{
  __block WFImageLoader *imageLoader;

  beforeEach(^{
    imageLoader = [[WFImageLoader alloc] init];
  });

  it(@"should load image from asset catalog", ^{
    NSBundle *testsBundle = NSBundle.lt_testBundle;
    NSURL *url = [NSURL URLWithString:@"SmallImageInBundle.jpg"
                        relativeToURL:testsBundle.bundleURL];
    RACSignal *image = [imageLoader imageWithURL:url];
    expect(image).will.sendValuesWithCount(1);
  });

  it(@"should load image from paint code module", ^{
    NSURL *url = [NSURL URLWithString:@"paintcode://WFFakePaintCodeModule/ImageA?width=1&height=1"];
    RACSignal *image = [imageLoader imageWithURL:url];
    expect(image).will.sendValuesWithCount(1);
  });

  it(@"should send error when loading nonexistent image", ^{
    NSURL *url = [NSURL URLWithString:@"no-such-image-whatsoever"];
    RACSignal *image = [imageLoader imageWithURL:url];
    expect(image).will.error();
  });
});

context(@"custom configuration", ^{
  __block id providerA;
  __block id providerB;
  __block id providerC;
  __block WFImageLoader *imageLoader;

  beforeEach(^{
    providerA = OCMProtocolMock(@protocol(WFImageProvider));
    OCMStub([providerA imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);
    providerB = OCMProtocolMock(@protocol(WFImageProvider));
    OCMStub([providerB imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);
    providerC = OCMProtocolMock(@protocol(WFImageProvider));
    OCMStub([providerC imageWithURL:OCMOCK_ANY]).andReturn([RACSignal never]);

    imageLoader = [[WFImageLoader alloc] initWithProviders:@{
      @"a": providerA,
      @"b": providerB,
      @"": providerC
    }];
  });

  it(@"should route URL with scheme to correct provider", ^{
    NSURL *urlA = [NSURL URLWithString:@"a:foo"];
    NSURL *urlB = [NSURL URLWithString:@"b:foo"];

    [imageLoader imageWithURL:urlA];
    [imageLoader imageWithURL:urlB];

    OCMVerify([providerA imageWithURL:urlA]);
    OCMVerify([providerB imageWithURL:urlB]);
  });

  it(@"should route URL without scheme to correct provider", ^{
    NSURL *url = [NSURL URLWithString:@"foo"];
    [imageLoader imageWithURL:url];
    OCMVerify([providerC imageWithURL:url]);
  });

  it(@"should send error when no provider is available", ^{
    NSURL *url = [NSURL URLWithString:@"no-such-scheme:foo"];
    RACSignal *image = [imageLoader imageWithURL:url];
    expect(image).to.error();
  });
});

SpecEnd
