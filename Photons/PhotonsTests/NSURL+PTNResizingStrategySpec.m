// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNResizingStrategy.h"

SpecBegin(NSURL_PTNResizingStrategy)

static NSString * const kSerializingExamples = @"serialization";
static NSString * const kSerializingStrategyKey = @"resizingStrategy";
static NSString * const kSerializingSizesKey = @"sizes";

sharedExamplesFor(kSerializingExamples, ^(NSDictionary *data) {
  it(@"should correctly serialize and deserialize a resizing strategy with a clear URL", ^{
    id<PTNResizingStrategy> resizingStrategy = data[kSerializingStrategyKey];
    NSArray<NSValue *> *sizes = data[kSerializingSizesKey];
    NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];

    NSURL *strategyURL = [url ptn_URLWithResizingStrategy:resizingStrategy];
    id<PTNResizingStrategy> deserializedStrategy = [strategyURL ptn_resizingStrategy];

    expect([deserializedStrategy class]).to.equal([resizingStrategy class]);
    for (NSValue *size in sizes) {
      expect([deserializedStrategy sizeForInputSize:size.CGSizeValue])
          .to.equal([resizingStrategy sizeForInputSize:size.CGSizeValue]);
    }
  });

  it(@"should correctly serialize and deserialize a resizing strategy with a URL with a query", ^{
    id<PTNResizingStrategy> resizingStrategy = data[kSerializingStrategyKey];
    NSArray<NSValue *> *sizes = data[kSerializingSizesKey];
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:@"http://www.foo.com"];
    components.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"foo" value:@"bar"]];
    NSURL *url = components.URL;

    NSURL *strategyURL = [url ptn_URLWithResizingStrategy:resizingStrategy];

    id<PTNResizingStrategy> deserializedStrategy = [strategyURL ptn_resizingStrategy];

    expect([deserializedStrategy class]).to.equal([resizingStrategy class]);
    for (NSValue *size in sizes) {
      expect([deserializedStrategy sizeForInputSize:size.CGSizeValue])
          .to.equal([resizingStrategy sizeForInputSize:size.CGSizeValue]);
    }
  });
});

it(@"should leave URL unchanged if an invalid resizing strategy is given", ^{
  id<PTNResizingStrategy> strategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  expect([url ptn_URLWithResizingStrategy:strategy]).to.equal(url);
});

it(@"should return nil strategy for invalid URLs", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  id deserializedStrategy = [url ptn_resizingStrategy];

  expect(deserializedStrategy).to.beNil();
});

itShouldBehaveLike(kSerializingExamples, ^{
  return @{
    kSerializingStrategyKey: [PTNResizingStrategy identity],
    kSerializingSizesKey: @[[NSValue valueWithCGSize:CGSizeMake(10, 10)]]
  };
});

itShouldBehaveLike(kSerializingExamples, ^{
  return @{
    kSerializingStrategyKey: [PTNResizingStrategy maxPixels:1024 * 1024],
    kSerializingSizesKey: @[
      [NSValue valueWithCGSize:CGSizeMake(1024, 1024)],
      [NSValue valueWithCGSize:CGSizeMake(512, 2048)],
      [NSValue valueWithCGSize:CGSizeMake(2048, 2048)],
      [NSValue valueWithCGSize:CGSizeMake(1024, 4096)]
    ]
  };
});

itShouldBehaveLike(kSerializingExamples, ^{
  return @{
    kSerializingStrategyKey: [PTNResizingStrategy aspectFit:CGSizeMake(20, 10)],
    kSerializingSizesKey: @[
      [NSValue valueWithCGSize:CGSizeMake(20, 10)],
      [NSValue valueWithCGSize:CGSizeMake(5, 10)],
      [NSValue valueWithCGSize:CGSizeMake(5, 5)],
      [NSValue valueWithCGSize:CGSizeMake(40, 20)],
      [NSValue valueWithCGSize:CGSizeMake(40, 10)],
      [NSValue valueWithCGSize:CGSizeMake(10.12345, 10.12345)]
    ]
  };
});

itShouldBehaveLike(kSerializingExamples, ^{
  return @{
    kSerializingStrategyKey: [PTNResizingStrategy aspectFill:CGSizeMake(20, 10)],
    kSerializingSizesKey: @[
      [NSValue valueWithCGSize:CGSizeMake(20, 10)],
      [NSValue valueWithCGSize:CGSizeMake(5, 10)],
      [NSValue valueWithCGSize:CGSizeMake(5, 5)],
      [NSValue valueWithCGSize:CGSizeMake(40, 20)],
      [NSValue valueWithCGSize:CGSizeMake(40, 10)],
      [NSValue valueWithCGSize:CGSizeMake(10.12345, 10.12345)]
    ]
  };
});

SpecEnd
