// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksCategory.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRTweakCollectionsProvider.h"

/// Fake collection provider to provide a readwrite access to the \c collections property.
@interface BZRFakeCollectionsProvider : NSObject <BZRTweakCollectionsProvider>

/// Redeclaring the collections as readwrite.
@property (readwrite, nonatomic) NSArray<FBTweakCollection *> *collections;

@end

@implementation BZRFakeCollectionsProvider

- (instancetype)init {
  if (self = [super init]) {
    _collections = @[];
  }
  return self;
}

@end

SpecBegin(BZRTweaksCategory)

__block FBTweak *tweak;
__block FBTweakCollection *firstCollection;
__block FBTweakCollection *secondCollection;
__block BZRFakeCollectionsProvider *firstCollectionsProvider;
__block BZRFakeCollectionsProvider *secondCollectionsProvider;

beforeEach(^{
  tweak = [[FBTweak alloc] initWithIdentifier:@"BZR.foo1" name:@"BZR.foo1" currentValue:@1];
  firstCollection = [[FBTweakCollection alloc] initWithName:@"bar1" tweaks:@[tweak]];
  secondCollection = [[FBTweakCollection alloc] initWithName:@"bar2" tweaks:@[tweak]];

  firstCollectionsProvider = [[BZRFakeCollectionsProvider alloc] init];
  secondCollectionsProvider = [[BZRFakeCollectionsProvider alloc] init];
});

it(@"should merge all providers collections", ^{
  firstCollectionsProvider.collections = @[firstCollection];
  secondCollectionsProvider.collections = @[secondCollection, firstCollection];

  auto category = [[BZRTweaksCategory alloc]
      initWithCollectionsProviders:@[firstCollectionsProvider, secondCollectionsProvider]];

  expect(category.tweakCollections).to.equal(@[firstCollection, secondCollection, firstCollection]);
});

it(@"should update the collection when the provider's collection changes",^{
  auto category = [[BZRTweaksCategory alloc]
      initWithCollectionsProviders:@[firstCollectionsProvider]];

  auto recorder = [RACObserve(category, tweakCollections) testRecorder];
  firstCollectionsProvider.collections = @[firstCollection];
  firstCollectionsProvider.collections = @[secondCollection, firstCollection];

  expect(recorder).will.sendValues(@[
      @[],
      @[firstCollection],
      @[secondCollection, firstCollection]
  ]);
});

SpecEnd
