// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSourceTweakCategory.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>
#import <LTKit/LTHashExtensions.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKitTestUtils/LTFakeKeyValuePersistentStorage.h>

#import "LABDebugSource.h"
#import "LABFakeAssignmentsSource.h"
#import "LABVariantUtils.h"
#import "NSError+Laboratory.h"

SpecBegin(LABDebugSourceTweakCategory)

__block LABFakeAssignmentsSource *fakeSource1, *fakeSource2;
__block LTFakeKeyValuePersistentStorage *storage;
__block LABDebugSource *source;
__block std::unordered_map<std::tuple<NSUInteger, NSUInteger, NSUInteger>, LABVariant *> variants;
__block LABDebugSourceTweakCategory *category;

beforeEach(^{
  variants = {
    {{0, 0, 0}, LABCreateVariant(@"bobVar", @{@"foo": @"bar", @"baz": @"thud"}, @"foo")},
    {{0, 0, 1}, LABCreateVariant(@"blobVar", @{@"foo": @"thud", @"baz": @"bar"}, @"foo")},
    {{0, 1, 0}, LABCreateVariant(@"fooVar", @{@"bob": @2, @"bab": @"thud"}, @"bar")},
    {{0, 1, 1}, LABCreateVariant(@"barVar", @{@"bob": @3, @"bab": @"bar"}, @"bar")},
    {{1, 0, 0}, LABCreateVariant(@"bobVar", @{@"ping": @"pong", @"flip": @"flop"}, @"baz")},
    {{1, 0, 1}, LABCreateVariant(@"blobVar", @{@"ping": @"pang", @"flip": @"flap"}, @"baz")},
    {{1, 1, 0}, LABCreateVariant(@"fooVar", @{@"que": @4, @"quee": @"bar"}, @"thud")},
    {{1, 1, 1}, LABCreateVariant(@"barVar", @{@"que": @9, @"quee": @"baz"}, @"thud")}
  };
  fakeSource1 = [[LABFakeAssignmentsSource alloc] init];
  fakeSource1.allExperiments = @{
    @"foo": @[variants[{0, 0, 0}], variants[{0, 0, 1}]],
    @"bar": @[variants[{0, 1, 0}], variants[{0, 1, 1}]]
  };
  fakeSource1.name = @"fake1";
  fakeSource2 = [[LABFakeAssignmentsSource alloc] init];
  fakeSource2.allExperiments = @{
    @"baz": @[variants[{1, 0, 0}], variants[{1, 0, 1}]],
    @"thud": @[variants[{1, 1, 0}], variants[{1, 1, 1}]]
  };
  fakeSource2.name = @"fake2";
  storage = [[LTFakeKeyValuePersistentStorage alloc] init];
  source = [[LABDebugSource alloc] initWithSources:@[fakeSource1, fakeSource2] storage:storage];
  category = [[LABDebugSourceTweakCategory alloc] initWithDebugSource:source];
});

it(@"should not expose collections if debug source does not expose any sources", ^{
  expect(category.tweakCollections).to.haveCount(0);
});

it(@"should update debug source", ^{
  LABDebugSource *debugSource = OCMClassMock(LABDebugSource.class);
  OCMStub([debugSource update]).andReturn([RACSignal empty]);
  auto newCategory = [[LABDebugSourceTweakCategory alloc] initWithDebugSource:debugSource];

  expect([newCategory update]).to.complete();
  OCMVerify([debugSource update]);
});

it(@"should err if debug source fails to update", ^{
  LABDebugSource *debugSource = OCMClassMock(LABDebugSource.class);
  auto sourceError = [NSError lt_errorWithCode:1337];
  OCMStub([debugSource update]).andReturn([RACSignal error:sourceError]);
  auto newCategory = [[LABDebugSourceTweakCategory alloc] initWithDebugSource:debugSource];

  expect([newCategory update]).to.sendError(sourceError);
  OCMVerify([debugSource update]);
});

it(@"should not expose tweaks if there are no experiments", ^{
  fakeSource1.allExperiments = fakeSource2.allExperiments = @{};
  expect([source update]).will.complete();
  expect(category.tweakCollections).to.haveCount(2);
  expect(category.tweakCollections[0].tweaks).to.haveCount(0);
  expect(category.tweakCollections[0].name).to.equal(@"fake1");
  expect(category.tweakCollections[1].tweaks).to.haveCount(0);
  expect(category.tweakCollections[1].name).to.equal(@"fake2");
});

it(@"should expose tweaks for experiments", ^{
  expect([source update]).will.complete();

  NSArray<id<FBEditableTweak>> *fakeSource1Tweaks =
      (NSArray<id<FBEditableTweak>> *)category.tweakCollections[0].tweaks;
  expect(fakeSource1Tweaks).to.haveCount(2);
  expect(fakeSource1Tweaks[0]).to.conformTo(@protocol(FBEditableTweak));
  expect(fakeSource1Tweaks[0].name).to.equal(@"bar");
  expect(fakeSource1Tweaks[0].possibleValues).to.equal(@[@"barVar", @"fooVar", @"Inactive"]);
  expect(fakeSource1Tweaks[1]).to.conformTo(@protocol(FBEditableTweak));
  expect(fakeSource1Tweaks[1].name).to.equal(@"foo");
  expect(fakeSource1Tweaks[1].possibleValues).to.equal(@[@"blobVar", @"bobVar", @"Inactive"]);

  NSArray<id<FBEditableTweak>> *fakeSource2Tweaks =
      (NSArray<id<FBEditableTweak>> *)category.tweakCollections[1].tweaks;
  expect(fakeSource2Tweaks).to.haveCount(2);
  expect(fakeSource2Tweaks[0]).to.conformTo(@protocol(FBEditableTweak));
  expect(fakeSource2Tweaks[0].name).to.equal(@"baz");
  expect(fakeSource2Tweaks[0].possibleValues).to.equal(@[@"blobVar", @"bobVar", @"Inactive"]);
  expect(fakeSource2Tweaks[0]).to.conformTo(@protocol(FBEditableTweak));
  expect(fakeSource2Tweaks[1].name).to.equal(@"thud");
  expect(fakeSource2Tweaks[1].possibleValues).to.equal(@[@"barVar", @"fooVar", @"Inactive"]);
});

it(@"should activate variants", ^{
  expect([category update]).will.complete();
  id<FBEditableTweak> tweak = (id<FBEditableTweak>)[category.tweakCollections[0].tweaks
                               lt_find:^(id<FBEditableTweak> tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak.currentValue = variants[{0, 0, 1}].name;
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name},
  };
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}]] lt_set]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);

  tweak = (id<FBEditableTweak>)[category.tweakCollections[1].tweaks
                                lt_find:^(id<FBEditableTweak> tweak) {
    return [tweak.name isEqual:variants[{1, 1, 0}].experiment];
  }];

  tweak.currentValue = variants[{1, 1, 0}].name;
  expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name},
    fakeSource2.name: @{variants[{1, 1, 0}].experiment: variants[{1, 1, 0}].name}
  };
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}], variants[{1, 1, 0}]] lt_set]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);
});

it(@"should deactivate experiments", ^{
  expect([category update]).will.complete();
  id<FBEditableTweak> tweak = (id<FBEditableTweak>)[category.tweakCollections[0].tweaks
                               lt_find:^(id<FBEditableTweak> tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak.currentValue = variants[{0, 0, 1}].name;

  tweak.currentValue = @"Inactive";
  expect(source.activeVariants).to.equal([@[] lt_set]);
  expect(source.variantActivationRequests).to.equal(@{});
});

it(@"should expose active tweak after initialization", ^{
  expect([category update]).will.complete();
  id<FBEditableTweak> tweak1 = (id<FBEditableTweak>)[category.tweakCollections[0].tweaks
                                lt_find:^(id<FBEditableTweak> tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak1.currentValue = variants[{0, 0, 1}].name;

  auto newCategory = [[LABDebugSourceTweakCategory alloc] initWithDebugSource:source];
  id<FBEditableTweak> tweak2 = (id<FBEditableTweak>)[newCategory.tweakCollections[0].tweaks
                                lt_find:^(id<FBEditableTweak> tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  expect(tweak2.currentValue).to.equal(variants[{0, 0, 1}].name);
});

SpecEnd
