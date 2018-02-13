// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryAdapter.h"

#import <FBTweak/FBTweakCollection.h>

#import "SHKFakeTweakCategory.h"
#import "SHKTweakCategory.h"

SpecBegin(SHKTweakCategoryAdapter)

it(@"should use name from underlying tweak category", ^{
  auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  expect(adapter.name).to.equal(@"foo");
});

it(@"should use tweak collections from underlying tweak category", ^{
  auto firstCollection = [[FBTweakCollection alloc] initWithName:@"foo"];
  auto secondCollection = [[FBTweakCollection alloc] initWithName:@"bar"];
  auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]];
  tweakCategory.tweakCollections = @[firstCollection];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  expect(adapter.tweakCollections).to.equal(@[firstCollection]);
  tweakCategory.tweakCollections = @[firstCollection, secondCollection];
  expect(adapter.tweakCollections).to.equal(@[firstCollection, secondCollection]);
});

it(@"should call completion method with nil error if update is not implemented", ^{
  auto tweakCategory = [[SHKPartialFakeTweakCategory alloc] initWithName:@"foo"
                                                        tweakCollections:@[]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  waitUntil(^(DoneCallback done) {
    [adapter updateWithCompletion:^(NSError * _Nullable error) {
      expect(error).to.beNil();
      done();
    }];
  });
});

it(@"should call reset on the underlying tweak category when reset is called", ^{
  auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  [adapter reset];
  expect(tweakCategory.resetCalled).to.beTruthy();
});

it(@"should not crash if reset is not implemented", ^{
  expect(^{
    auto tweakCategory = [[SHKPartialFakeTweakCategory alloc] initWithName:@"foo"
                                                          tweakCollections:@[]];
    auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];
    [adapter reset];
  }).notTo.raiseAny();
});

context(@"update", ^{
  it(@"should call completion method with nil error when update signal completed", ^{
    auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]
                                                       updateSignal:[RACSignal empty]];
    auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

    waitUntil(^(DoneCallback done) {
      [adapter updateWithCompletion:^(NSError * _Nullable error) {
        expect(error).to.beNil();
        done();
      }];
    });
  });

  it(@"should call completion method with error when update signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]
                                                       updateSignal:[RACSignal error:error]];
    auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

    waitUntil(^(DoneCallback done) {
      [adapter updateWithCompletion:^(NSError * _Nullable innerError) {
        expect(innerError).to.equal(error);
        done();
      }];
    });
  });
});

context(@"inherited methods", ^{
  __block SHKTweakCategoryAdapter *adapter;
  __block NSArray<FBTweakCollection *> *collections;

  beforeEach(^{
    auto firstCollection = [[FBTweakCollection alloc] initWithName:@"foo"];
    auto secondCollection = [[FBTweakCollection alloc] initWithName:@"bar"];
    collections = @[firstCollection, secondCollection];;
    auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithName:@"foo" tweakCollections:@[]];
    tweakCategory.tweakCollections = collections;
    adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];
  });

  it(@"should find collection by name", ^{
    expect([adapter tweakCollectionWithName:@"foo"]).to.equal(collections[0]);
  });

  it(@"should return nil when collection can not be found", ^{
    expect([adapter tweakCollectionWithName:@"blup"]).to.beNil();
  });

  it(@"should do nothing when trying to add collection", ^{
    auto collection = [[FBTweakCollection alloc] initWithName:@"flop"];
    [adapter addTweakCollection:collection];
    expect(adapter.tweakCollections).to.equal(collections);
  });

  it(@"should do nothing when trying to remove existing collection", ^{
    [adapter removeTweakCollection:collections[0]];
    expect(adapter.tweakCollections).to.equal(collections);
  });
});

SpecEnd
