// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBTweakStore+Milkshake.h"

#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakStore.h>

#import "SHKFakeTweakCategory.h"
#import "SHKTweakCategory.h"

SpecBegin(FBTweakStore_Milkshake)

__block FBTweakStore *store;

beforeEach(^{
  store = [[FBTweakStore alloc] init];
});

it(@"should add a tweak category to the store", ^{
  id<SHKTweakCategory> category = [[SHKFakeTweakCategory alloc] initWithName:@"foo"
                                                            tweakCollections:@[]];
  [store shk_addTweakCategory:category];
  expect(store.tweakCategories).to.haveCountOf(1);
  expect(((FBTweakCategory *)store.tweakCategories[0]).name).to.equal(@"foo");
});

SpecEnd
