// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryAdapter.h"

#import <FBTweak/FBTweakCollection.h>

/// Fake category to help test \c SHKTweakCategoryAdapter. Implements all methods.
@interface SHKFakeTweakCategory : NSObject <SHKTweakCategory>

/// Initializes with \c name "foo", and an empty \c tweakCollections, and \c nil updateSignal.
- (instancetype)init;

/// Initializes with \c name "foo", and an empty \c tweakCollections, and \c updateSignal to return
/// in the \c update method.
- (instancetype)initWithUpdateSignal:(nullable RACSignal *)updateSignal;

/// Tweak collections in this category. KVO-compliant.
@property (readwrite, nonatomic) NSArray<FBTweakCollection *> *tweakCollections;

/// To be returned in the \c update method.
@property (readonly, nonatomic, nullable) RACSignal *updateSignal;

/// \c YES if the \c reset method was invoked.
@property (nonatomic) BOOL resetCalled;

@end

@implementation SHKFakeTweakCategory

@synthesize name = _name;

- (instancetype)init {
  return [self initWithUpdateSignal:nil];
}

- (instancetype)initWithUpdateSignal:(RACSignal *)updateSignal {
  if (self = [super init]) {
    _name = @"foo";
    _tweakCollections = @[];
    _updateSignal = updateSignal;
  }
  return self;
}

- (RACSignal *)update {
  return nn(self.updateSignal);
}

- (void)reset {
  self.resetCalled = YES;
}

@end

/// Fake immutable category to help test \c SHKTweakCategoryAdapter. Does not implement the
/// \c update and \c reset methods.
@interface SHKPartialFakeTweakCategory : NSObject <SHKTweakCategory>

/// Initializes with \c name "foo", and an empty \c tweakCollections.
- (instancetype)init;

@end

@implementation SHKPartialFakeTweakCategory

@synthesize name = _name;
@synthesize tweakCollections = _tweakCollections;

- (instancetype)init {
  if (self = [super init]) {
    _name = @"foo";
    _tweakCollections = @[];
  }
  return self;
}

@end

SpecBegin(SHKTweakCategoryAdapter)

it(@"should use name from underlying tweak category", ^{
  auto tweakCategory = [[SHKFakeTweakCategory alloc] init];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  expect(adapter.name).to.equal(@"foo");
});

it(@"should use tweak collections from underlying tweak category", ^{
  auto firstCollection = [[FBTweakCollection alloc] initWithName:@"foo"];
  auto secondCollection = [[FBTweakCollection alloc] initWithName:@"bar"];
  auto tweakCategory = [[SHKFakeTweakCategory alloc] init];
  tweakCategory.tweakCollections = @[firstCollection];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  expect(adapter.tweakCollections).to.equal(@[firstCollection]);
  tweakCategory.tweakCollections = @[firstCollection, secondCollection];
  expect(adapter.tweakCollections).to.equal(@[firstCollection, secondCollection]);
});

it(@"should call completion method with nil error if update is not implemented", ^{
  auto tweakCategory = [[SHKPartialFakeTweakCategory alloc] init];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  waitUntil(^(DoneCallback done) {
    [adapter updateWithCompletion:^(NSError * _Nullable error) {
      expect(error).to.beNil();
      done();
    }];
  });
});

it(@"should call completion method with nil error when update signal completed", ^{
  auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithUpdateSignal:[RACSignal empty]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  waitUntil(^(DoneCallback done) {
    [adapter updateWithCompletion:^(NSError * _Nullable error) {
      expect(error).to.beNil();
      done();
    }];
  });
});

it(@"should call completion method with error when update signal errs", ^{
  NSError *error = OCMClassMock([NSError class]);
  auto tweakCategory = [[SHKFakeTweakCategory alloc] initWithUpdateSignal:[RACSignal error:error]];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  waitUntil(^(DoneCallback done) {
    [adapter updateWithCompletion:^(NSError * _Nullable error) {
      expect(error).to.equal(error);
      done();
    }];
  });
});

it(@"should call reset on the underlying tweak category when reset is called", ^{
  auto tweakCategory = [[SHKFakeTweakCategory alloc] init];
  auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];

  [adapter reset];
  expect(tweakCategory.resetCalled).to.beTruthy();
});

it(@"should not crash if reset is not implemented", ^{
  expect(^{
    auto tweakCategory = [[SHKPartialFakeTweakCategory alloc] init];
    auto adapter = [[SHKTweakCategoryAdapter alloc] initWithTweakCategory:tweakCategory];
    [adapter reset];
  }).notTo.raiseAny();
});

context(@"inherited methods", ^{
  __block SHKTweakCategoryAdapter *adapter;
  __block NSArray<FBTweakCollection *> *collections;

  beforeEach(^{
    auto firstCollection = [[FBTweakCollection alloc] initWithName:@"foo"];
    auto secondCollection = [[FBTweakCollection alloc] initWithName:@"bar"];
    collections = @[firstCollection, secondCollection];;
    auto tweakCategory = [[SHKFakeTweakCategory alloc] init];
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
