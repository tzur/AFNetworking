// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFAssetCatalogImageProvider.h"

SpecBegin(WFAssetCatalogImageProvider)

__block WFAssetCatalogImageProvider *provider;
__block NSBundle *testsBundle;

beforeEach(^{
  provider = [[WFAssetCatalogImageProvider alloc] init];
  testsBundle = [NSBundle bundleForClass:self.class];
});

context(@"errors", ^{
  it(@"should send error when given non-existing image", ^{
    LTAssert(![UIImage imageNamed:@"no-such-image"
                         inBundle:testsBundle compatibleWithTraitCollection:nil],
             @"Tests bundle contains an image with a name that must not be used");

    RACSignal *image = [provider imageWithURL:[NSURL URLWithString:@"no-such-image"]];
    expect(image).will.error();
  });
});

context(@"asset catalog", ^{
  __block UIImage *expectedImage;

  beforeAll(^{
    expectedImage = [UIImage imageNamed:@"SmallImageInAssetCatalog" inBundle:testsBundle
          compatibleWithTraitCollection:nil];
    LTAssert(expectedImage, "Required image is not present in tests bundle");
  });

  it(@"should load image from asset catalog via bundle and fragment reference", ^{
    NSURL *imageURL = [NSURL URLWithString:@"#SmallImageInAssetCatalog"
                             relativeToURL:testsBundle.bundleURL];
    RACSignal *image = [provider imageWithURL:imageURL];
    expect(image).will.sendValues(@[expectedImage]);
  });
});

context(@"bundle", ^{
  __block UIImage *expectedImage;

  beforeAll(^{
    expectedImage = [UIImage imageNamed:@"SmallImageInBundle.jpg" inBundle:testsBundle
          compatibleWithTraitCollection:nil];
    LTAssert(expectedImage, "Required image is not present in tests bundle");
  });

  it(@"should load image from bundle via file URL", ^{
    NSURL *imageURL = [NSURL URLWithString:@"SmallImageInBundle.jpg"
                             relativeToURL:testsBundle.bundleURL];
    RACSignal *image = [provider imageWithURL:imageURL];
    expect(image).will.sendValues(@[expectedImage]);
  });
});

it(@"should deallocate after signal completes", ^{
  __weak id<WFImageProvider> weakProvider = nil;
  @autoreleasepool {
    id<WFImageProvider> provider = [[WFAssetCatalogImageProvider alloc] init];
    weakProvider = provider;
    NSURL *url = [NSURL URLWithString:@"SmallImageInBundle.jpg"
                             relativeToURL:testsBundle.bundleURL];
    RACSignal *image = [provider imageWithURL:url];
    expect(image).will.complete();
  }
  expect(weakProvider).to.beNil();
});

SpecEnd
