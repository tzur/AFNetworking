// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFAssetCatalogImageProvider.h"

#import <LTKit/LTCGExtensions.h>

SpecBegin(WFAssetCatalogImageProvider)

__block WFAssetCatalogImageProvider *provider;
__block NSBundle *testsBundle;

beforeEach(^{
  provider = [[WFAssetCatalogImageProvider alloc] init];
  testsBundle = NSBundle.lt_testBundle;
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

  beforeEach(^{
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

  beforeEach(^{
    expectedImage = [UIImage imageNamed:@"SmallImageInBundle.jpg" inBundle:testsBundle
          compatibleWithTraitCollection:nil];
    LTAssert(expectedImage, "Required image is not present in tests bundle");
  });

  it(@"should load image from bundle via fragment reference", ^{
    NSURLComponents *components = [NSURLComponents componentsWithURL:testsBundle.bundleURL
                                             resolvingAgainstBaseURL:NO];
    components.fragment = @"SmallImageInBundle.jpg";
    NSURL *imageURL = components.URL;

    RACSignal *image = [provider imageWithURL:imageURL];
    expect(image).will.sendValues(@[expectedImage]);
  });

  it(@"should load image from bundle via file URL", ^{
    NSURL *imageURL = [NSURL URLWithString:@"SmallImageInBundle.jpg"
                             relativeToURL:testsBundle.bundleURL];

    // Compare images only by size since images that are retrieved from the bundle are not -isEqual:
    // to images that are loaded indirectly from the bundle via full file path URL.
    LLSignalTestRecorder *recorder = [[provider imageWithURL:imageURL] testRecorder];
    expect(recorder).will.complete();
    expect(recorder).to.sendValuesWithCount(1);
    expect(recorder).to.matchValue(0, ^BOOL(UIImage *image) {
      return image.size == expectedImage.size;
    });
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
