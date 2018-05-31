// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksCategory.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>

#import "BZRFakeTweakCollectionsProvider.h"

SpecBegin(BZRTweaksCategory)

__block FBTweak *tweak;
__block FBTweakCollection *firstCollection;
__block FBTweakCollection *secondCollection;
__block BZRFakeTweakCollectionsProvider *firstCollectionsProvider;
__block BZRFakeTweakCollectionsProvider *secondCollectionsProvider;

beforeEach(^{
  tweak = [[FBTweak alloc] initWithIdentifier:@"BZR.foo1" name:@"BZR.foo1" currentValue:@1];
  firstCollection = [[FBTweakCollection alloc] initWithName:@"bar1" tweaks:@[tweak]];
  secondCollection = [[FBTweakCollection alloc] initWithName:@"bar2" tweaks:@[tweak]];

  firstCollectionsProvider = [[BZRFakeTweakCollectionsProvider alloc] init];
  secondCollectionsProvider = [[BZRFakeTweakCollectionsProvider alloc] init];
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
