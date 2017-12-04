// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSourceTweakCollectionsProvider.h"

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

SpecBegin(LABDebugSourceTweakCollectionsProvider)

__block LABFakeAssignmentsSource *fakeSource1, *fakeSource2;
__block LTFakeKeyValuePersistentStorage *storage;
__block LABDebugSource *source;
__block std::unordered_map<std::tuple<NSUInteger, NSUInteger, NSUInteger>, LABVariant *> variants;
__block LABDebugSourceTweakCollectionsProvider *provider;

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
  provider = [[LABDebugSourceTweakCollectionsProvider alloc] initWithDebugSource:source];
});

it(@"should not expose collections if debug source does not expose any sources", ^{
  expect(provider.collections).to.haveCount(0);
});

it(@"should update debug source", ^{
  LABDebugSource *debugSource = OCMClassMock(LABDebugSource.class);
  OCMStub([debugSource update]).andReturn([RACSignal empty]);
  auto collectionsProvider =
      [[LABDebugSourceTweakCollectionsProvider alloc] initWithDebugSource:debugSource];

  expect([collectionsProvider updateCollections]).to.complete();
  OCMVerify([debugSource update]);
});

it(@"should deliver update collections results on the main thread", ^{
  LABDebugSource *debugSource = OCMClassMock(LABDebugSource.class);
  OCMStub([debugSource update]).andReturn([[RACSignal empty] deliverOn:[RACScheduler scheduler]]);
  auto collectionsProvider =
      [[LABDebugSourceTweakCollectionsProvider alloc] initWithDebugSource:debugSource];

  auto recorder = [[[collectionsProvider updateCollections] materialize] testRecorder];

  expect(recorder).will.deliverValuesOnMainThread();
  expect(recorder).to.sendValues(@[[RACEvent completedEvent]]);
});

it(@"should err if debug source fails to update", ^{
  LABDebugSource *debugSource = OCMClassMock(LABDebugSource.class);
  auto sourceError = [NSError lt_errorWithCode:1337];
  OCMStub([debugSource update]).andReturn([RACSignal error:sourceError]);
  auto collectionsProvider =
      [[LABDebugSourceTweakCollectionsProvider alloc] initWithDebugSource:debugSource];

  auto expectedError = [NSError lt_errorWithCode:LABErrorCodeTweaksCollectionsUpdateFailed
                                 underlyingError:sourceError];
  expect([collectionsProvider updateCollections]).to.sendError(expectedError);
  OCMVerify([debugSource update]);
});

it(@"should not expose tweaks if there are no experiments", ^{
  fakeSource1.allExperiments = fakeSource2.allExperiments = @{};
  expect([source update]).will.complete();
  expect(provider.collections).to.haveCount(2);
  expect(provider.collections[0].tweaks).to.haveCount(0);
  expect(provider.collections[0].name).to.equal(@"fake1");
  expect(provider.collections[1].tweaks).to.haveCount(0);
  expect(provider.collections[1].name).to.equal(@"fake2");
});

it(@"should expose tweaks for experiments", ^{
  expect([source update]).will.complete();

  NSArray<FBTweak *> *fakeSource1Tweaks = provider.collections[0].tweaks;
  expect(fakeSource1Tweaks).to.haveCount(2);
  expect(fakeSource1Tweaks[0].name).to.equal(@"bar");
  expect(fakeSource1Tweaks[0].possibleValues).to.equal(@[@"barVar", @"fooVar", @"Inactive"]);
  expect(fakeSource1Tweaks[1].name).to.equal(@"foo");
  expect(fakeSource1Tweaks[1].possibleValues).to.equal(@[@"blobVar", @"bobVar", @"Inactive"]);

  NSArray<FBTweak *> *fakeSource2Tweaks = provider.collections[1].tweaks;
  expect(fakeSource2Tweaks).to.haveCount(2);
  expect(fakeSource2Tweaks[0].name).to.equal(@"baz");
  expect(fakeSource2Tweaks[0].possibleValues).to.equal(@[@"blobVar", @"bobVar", @"Inactive"]);
  expect(fakeSource2Tweaks[1].name).to.equal(@"thud");
  expect(fakeSource2Tweaks[1].possibleValues).to.equal(@[@"barVar", @"fooVar", @"Inactive"]);
});

it(@"should activate variants", ^{
  expect([provider updateCollections]).will.complete();
  FBTweak *tweak = [provider.collections[0].tweaks lt_find:^(FBTweak *tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak.currentValue = variants[{0, 0, 1}].name;
  auto expectedActivationRequests = @{
    fakeSource1.name: @{variants[{0, 0, 1}].experiment: variants[{0, 0, 1}].name},
  };
  expect(source.activeVariants).to.equal([@[variants[{0, 0, 1}]] lt_set]);
  expect(source.variantActivationRequests).to.equal(expectedActivationRequests);

  tweak = [provider.collections[1].tweaks lt_find:^(FBTweak *tweak) {
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
  expect([provider updateCollections]).will.complete();
  FBTweak *tweak = [provider.collections[0].tweaks lt_find:^(FBTweak *tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak.currentValue = variants[{0, 0, 1}].name;

  tweak.currentValue = @"Inactive";
  expect(source.activeVariants).to.equal([@[] lt_set]);
  expect(source.variantActivationRequests).to.equal(@{});
});

it(@"should expose active tweak after initialization", ^{
  expect([provider updateCollections]).will.complete();
  FBTweak *tweak1 = [provider.collections[0].tweaks lt_find:^(FBTweak *tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  tweak1.currentValue = variants[{0, 0, 1}].name;

  auto collectionsProvider =
      [[LABDebugSourceTweakCollectionsProvider alloc] initWithDebugSource:source];
  FBTweak *tweak2 = [collectionsProvider.collections[0].tweaks lt_find:^(FBTweak *tweak) {
    return [tweak.name isEqual:variants[{0, 0, 1}].experiment];
  }];

  expect(tweak2.currentValue).to.equal(variants[{0, 0, 1}].name);
});

SpecEnd
