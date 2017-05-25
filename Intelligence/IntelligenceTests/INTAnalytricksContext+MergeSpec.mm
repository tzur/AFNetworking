// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContext+Merge.h"

#import <LTKit/LTKeyPathCoding.h>

SpecBegin(INTAnalytricksContext_Merge)

it(@"should return identical instance for an empty dictionary input", ^{
  auto context = [[INTAnalytricksContext alloc] initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID]
                                                screenUsageID:[NSUUID UUID] screenName:@"foo"
                                                openProjectID:[NSUUID UUID]];
  auto mergedContext = [context merge:@{}];

  expect(mergedContext).to.equal(context);
});

static NSString * const kAnalytricksContextPropertySetExamples = @"propertySetExamples";
static NSString * const kAnalytricksContextPropertyKeypathToSet = @"keypathToSet";
static NSString * const kAnalytricksContextPropertyValue = @"valueToSet";

sharedExamples(kAnalytricksContextPropertySetExamples, ^(NSDictionary *data) {
  static NSArray<NSString *> *kInstanceProperties = @[
    @instanceKeypath(INTAnalytricksContext, runID),
    @instanceKeypath(INTAnalytricksContext, sessionID),
    @instanceKeypath(INTAnalytricksContext, screenUsageID),
    @instanceKeypath(INTAnalytricksContext, screenName),
    @instanceKeypath(INTAnalytricksContext, openProjectID)
  ];

  __block NSString *keypath;
  __block id valueToSet;
  __block INTAnalytricksContext *context;

  beforeEach(^{
    keypath = data[kAnalytricksContextPropertyKeypathToSet];
    valueToSet = data[kAnalytricksContextPropertyValue];

    context = [[INTAnalytricksContext alloc] initWithRunID:[NSUUID UUID] sessionID:[NSUUID UUID]
                                             screenUsageID:[NSUUID UUID] screenName:@"foo"
                                             openProjectID:[NSUUID UUID]];
  });

  it(@"should set new property value", ^{
    auto mergedContext = [context merge:@{keypath: valueToSet}];

    if ([valueToSet isKindOfClass:NSNull.class]) {
      expect([mergedContext valueForKey:keypath]).to.beNil();
    } else {
      expect([mergedContext valueForKey:keypath]).to.equal(valueToSet);
    }
  });

  it(@"should keep other property values intact", ^{
    NSMutableArray *classProperties = [kInstanceProperties mutableCopy];
    [classProperties removeObject:keypath];

    auto mergedContext = [context merge:@{keypath: valueToSet}];

    for (NSString *property in classProperties) {
      expect([mergedContext valueForKey:property])
          .to.equal([context valueForKey:property]);
    }
  });
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, runID),
  kAnalytricksContextPropertyValue: [NSUUID UUID]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, sessionID),
  kAnalytricksContextPropertyValue: [NSUUID UUID]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, screenUsageID),
  kAnalytricksContextPropertyValue: [NSUUID UUID]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, screenName),
  kAnalytricksContextPropertyValue: @"foo"
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, openProjectID),
  kAnalytricksContextPropertyValue: [NSUUID UUID]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, sessionID),
  kAnalytricksContextPropertyValue: [NSNull null]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, screenUsageID),
  kAnalytricksContextPropertyValue: [NSNull null]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, screenName),
  kAnalytricksContextPropertyValue: [NSNull null]
});

itShouldBehaveLike(kAnalytricksContextPropertySetExamples, @{
  kAnalytricksContextPropertyKeypathToSet: @instanceKeypath(INTAnalytricksContext, openProjectID),
  kAnalytricksContextPropertyValue: [NSNull null]
});

SpecEnd
