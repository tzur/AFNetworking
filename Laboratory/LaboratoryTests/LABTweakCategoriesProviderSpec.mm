// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABTweakCategoriesProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakCollection.h>
#import <LTKit/LTHashExtensions.h>
#import <LTKit/NSArray+Functional.h>

#import "LABTweakCategoriesProvider+Internal.h"
#import "LABTweakCollectionsProvider.h"
#import "NSErrorCodes+Laboratory.h"

/// Fake implementation of \c LABTweakCollectionsProvider without the optional methods.
@interface LABFakeTweakCollectionsProvider : NSObject <LABTweakCollectionsProvider>

/// FBTweak collections available from the receiver.
@property (readwrite, nonatomic) NSArray<FBTweakCollection *> *collections;

/// Count of the times the \c resetTweaks method was called.
@property (nonatomic) NSUInteger resetTweaksRequestCount;

@end

@implementation LABFakeTweakCollectionsProvider

- (instancetype)init {
  if (self = [super init]) {
    self.collections = @[];
  }
  return self;
}

- (void)resetTweaks {
  ++self.resetTweaksRequestCount;
}

@end

/// Fake implementation of \c LABTweakCollectionsProvider with the oprtional \c updateCollections
/// method.
@interface LABFakeUpdatableTweakCollectionsProvider : LABFakeTweakCollectionsProvider

/// Signal returned when calling <tt>-[LABAssignmentsSource update]</tt>. Defaults to
/// <tt>[RACSignal empty]</tt>.
@property (strong, nonatomic) RACSignal *updateSignal;

/// Count of the times the \c updateCollections method was called.
@property (nonatomic) NSUInteger updateCollectionsRequestCount;

@end

@implementation LABFakeUpdatableTweakCollectionsProvider

- (instancetype)init {
  if (self = [super init]) {
    self.updateSignal = [RACSignal empty];
  }
  return self;
}

- (RACSignal *)updateCollections {
  ++self.updateCollectionsRequestCount;
  return self.updateSignal;
}

@end

SpecBegin(LABTweakCategoriesProvider)

__block std::unordered_map<std::tuple<NSUInteger, NSUInteger>, FBTweakCollection *> collections;
__block LABFakeTweakCollectionsProvider *collectionProvider;
__block LABFakeUpdatableTweakCollectionsProvider *updateableCollectionProvider;
__block LABTweakCategoriesProvider *categoriesProvider;

beforeEach(^{
  collections = {
    {{0, 0}, [[FBTweakCollection alloc] initWithName:@"prov1col1"]},
    {{0, 1}, [[FBTweakCollection alloc] initWithName:@"prov1col2"]},
    {{1, 0}, [[FBTweakCollection alloc] initWithName:@"prov2col1"]}
  };
  [collections[{0, 0}] addTweak:[[FBTweak alloc] initWithIdentifier:@"foo"]];
  [collections[{0, 0}] addTweak:[[FBTweak alloc] initWithIdentifier:@"bar"]];
  [collections[{0, 1}] addTweak:[[FBTweak alloc] initWithIdentifier:@"baz"]];
  [collections[{0, 1}] addTweak:[[FBTweak alloc] initWithIdentifier:@"thud"]];
  [collections[{1, 0}] addTweak:[[FBTweak alloc] initWithIdentifier:@"baz"]];
  [collections[{1, 0}] addTweak:[[FBTweak alloc] initWithIdentifier:@"thud"]];

  collectionProvider = [[LABFakeTweakCollectionsProvider alloc] init];
  collectionProvider.collections = @[collections[{0, 0}], collections[{0, 1}]];

  updateableCollectionProvider = [[LABFakeUpdatableTweakCollectionsProvider alloc] init];
  updateableCollectionProvider.collections = @[collections[{1, 0}]];

  categoriesProvider = [[LABTweakCategoriesProvider alloc] initWithProviders:@{
    @"foo": collectionProvider,
    @"bar": updateableCollectionProvider
  }];
});

it(@"should initialize with provider categories", ^{
  auto providerCategoryNames =
      [categoriesProvider.providerCategories lt_map:^(FBTweakCategory *object) {
        return object.name;
      }];

  expect(providerCategoryNames).to.equal(@[@"bar", @"foo"]);
  expect([categoriesProvider.providerCategories[0] tweakCollectionWithName:@"prov2col1"]).to
      .equal(collections[{1, 0}]);
  expect([categoriesProvider.providerCategories[1] tweakCollectionWithName:@"prov1col1"]).to
      .equal(collections[{0, 0}]);
  expect([categoriesProvider.providerCategories[1] tweakCollectionWithName:@"prov1col2"]).to
      .equal(collections[{0, 1}]);
});

it(@"should update state of the provider categories when collections change", ^{
  auto categories = categoriesProvider.providerCategories;

  auto prov2col2 = [[FBTweakCollection alloc] initWithName:@"prov2col2"];
  [prov2col2 addTweak:[[FBTweak alloc] initWithIdentifier:@"moo"]];
  [prov2col2 addTweak:[[FBTweak alloc] initWithIdentifier:@"boo"]];
  updateableCollectionProvider.collections = @[collections[{0, 1}], prov2col2];

  [collections[{0, 0}] addTweak:[[FBTweak alloc] initWithIdentifier:@"bob"]];

  expect(categoriesProvider.providerCategories).to.equal(categories);
  expect([categories[0] tweakCollectionWithName:@"prov2col1"]).to.equal(collections[{1, 0}]);
  expect([categories[0] tweakCollectionWithName:@"prov2col2"]).to.equal(prov2col2);
  expect([categories[1] tweakCollectionWithName:@"prov1col1"]).to.equal(collections[{0, 0}]);
  expect([categories[1] tweakCollectionWithName:@"prov1col2"]).to.equal(collections[{0, 1}]);
});

it(@"should initialize with a settings category", ^{
  expect(categoriesProvider.settingsCategory.name).to.equal(@"Settings");
});

it(@"should initialize with update tweaks only for updatable provider", ^{
  auto barSettings = [categoriesProvider.settingsCategory tweakCollectionWithName:@"bar"];
  NSArray<FBTweak *> *barSettingsTweaks = barSettings.tweaks;
  expect(barSettingsTweaks).to.haveCount(3);
  expect(barSettingsTweaks[0].name).to.equal(kLABUpdateTweakName);
  expect(barSettingsTweaks[0].defaultValue).to.equal(@NO);
  expect(barSettingsTweaks[0].currentValue).to.equal(@NO);
  expect(barSettingsTweaks[1].name).to.equal(kLABUpdateStatusTweakNameStable);
  expect([categoriesProvider.settingsCategory tweakCollectionWithName:@"foo"].tweaks).to
      .haveCount(1);
});

it(@"should initialize with reset tweak for providers", ^{
  FBTweak *barResetTweak =
      [categoriesProvider.settingsCategory tweakCollectionWithName:@"bar"].tweaks[2];
  expect(barResetTweak.name).to.equal(kLABResetTweakName);
  FBTweak *fooResetTweak =
      [categoriesProvider.settingsCategory tweakCollectionWithName:@"foo"].tweaks[0];
  expect(fooResetTweak.name).to.equal(kLABResetTweakName);

  LTVoidBlock barResetBlock = barResetTweak.defaultValue;
  LTVoidBlock fooResetBlock = fooResetTweak.defaultValue;
  barResetBlock();
  fooResetBlock();
  expect(collectionProvider.resetTweaksRequestCount).to.equal(1);
  expect(updateableCollectionProvider.resetTweaksRequestCount).to.equal(1);

  barResetBlock();
  fooResetBlock();

  expect(collectionProvider.resetTweaksRequestCount).to.equal(2);
  expect(updateableCollectionProvider.resetTweaksRequestCount).to.equal(2);
});

it(@"should initialize with categories", ^{
  expect(categoriesProvider.categories).to
      .equal([@[categoriesProvider.settingsCategory]
              arrayByAddingObjectsFromArray:categoriesProvider.providerCategories]);
});

it(@"should not reset update tweak when update doesn't err or complete", ^{
  auto fooSettings = [categoriesProvider.settingsCategory tweakCollectionWithName:@"bar"];
  NSArray<FBTweak *> *barSettingsTweaks = fooSettings.tweaks;
  updateableCollectionProvider.updateSignal = [RACSignal never];

  barSettingsTweaks[0].currentValue = @YES;

  expect(updateableCollectionProvider.updateCollectionsRequestCount).to.equal(1);
  expect(barSettingsTweaks[0].currentValue).to.equal(@YES);
  expect(barSettingsTweaks[1].name).to.equal(kLABUpdateStatusTweakNameUpdating);
});

it(@"should update collection provider when update tweak value changes to YES", ^{
  auto barSettings = [categoriesProvider.settingsCategory tweakCollectionWithName:@"bar"];
  NSArray<FBTweak *> *barUpdateTweaks = barSettings.tweaks;
  barUpdateTweaks[0].currentValue = @YES;

  expect(updateableCollectionProvider.updateCollectionsRequestCount).to.equal(1);
  expect(barUpdateTweaks[0].currentValue).to.equal(@NO);
  expect(barUpdateTweaks[1].name).to.equal(kLABUpdateStatusTweakNameStable);

  barUpdateTweaks[0].currentValue = @YES;

  expect(updateableCollectionProvider.updateCollectionsRequestCount).to.equal(2);
  expect(barUpdateTweaks[0].currentValue).to.equal(@NO);
  expect(barUpdateTweaks[1].name).to.equal(kLABUpdateStatusTweakNameStable);
});

it(@"should reset update tweak when update errs", ^{
  auto barSettings = [categoriesProvider.settingsCategory tweakCollectionWithName:@"bar"];
  NSArray<FBTweak *> *barUpdateTweaks = barSettings.tweaks;
  updateableCollectionProvider.updateSignal =
      [RACSignal error:[NSError lt_errorWithCode:LABErrorCodeTweaksCollectionsUpdateFailed]];

  barUpdateTweaks[0].currentValue = @YES;

  expect(updateableCollectionProvider.updateCollectionsRequestCount).to.equal(1);
  expect(barUpdateTweaks[0].currentValue).to.equal(@NO);
  expect(barUpdateTweaks[1].name).to.equal(kLABUpdateStatusTweakNameStableUpdateFailed);
});

SpecEnd
