// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsManager.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>

#import "LABFakeAssignmentsSource.h"
#import "LABFakeStorage.h"
#import "LABStorage.h"
#import "NSError+Laboratory.h"

static LABVariant *LABCreateVariant(NSString *name, NSDictionary<NSString *, id> *assignments,
                                    NSString *experiment) {
  return [[LABVariant alloc] initWithName:name assignments:assignments experiment:experiment];
}

static NSDictionary *LABFakeAssignment(id value, NSString *key, NSString *variant,
                                       NSString *experiment, NSString *sourceName) {
  return @{
    @"value": value,
    @"key": key,
    @"variant": variant,
    @"experiment": experiment,
    @"sourceName": sourceName
  };
}

static NSDictionary<NSString *, NSDictionary *> *
    LABFakeAssignments(NSDictionary<NSString *, id<LABAssignment>> *assignments) {
  auto result = [NSMutableDictionary dictionary];

  [assignments enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<LABAssignment> assignment,
                                                   BOOL *) {
    result[key] = LABFakeAssignment(assignment.value, assignment.key, assignment.variant,
                                            assignment.experiment, assignment.sourceName);
  }];

  return [result copy];;
}

static NSDictionary<NSString *, NSDictionary *> *LABFakeAssignments(LABVariant *variant,
                                                                    NSString *sourceName) {
  auto result = [NSMutableDictionary dictionary];

  [variant.assignments enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *) {
    result[key] = LABFakeAssignment(value, key, variant.name, variant.experiment,
                                            sourceName);
  }];

  return [result copy];
}

/// Fake implementation of \c LABAssignmentsManagerDelegate for the tests.
@interface LABFakeAssignmentsManagerDelegate : NSObject <LABAssignmentsManagerDelegate>

/// Active assignments that were reported using
/// \c assignmentsManager:loadedNewActiveAssignments:revisionID. The tuples are pairs of
/// \c activeAssignments and \c activeAssignmentsRevisionID.
@property (readonly, nonatomic) NSMutableArray<RACTuple *> *reportedActiveAssignments;

/// Assignments that were reported to the receiver as affecting user experience.
@property (readonly, nonatomic) NSMutableArray<id<LABAssignment>> *reportedAffectingAssignments;

@end

@implementation LABFakeAssignmentsManagerDelegate

- (instancetype)init {
  if (self = [super init]) {
    _reportedActiveAssignments = [NSMutableArray array];
    _reportedAffectingAssignments = [NSMutableArray array];
  }
  return self;
}

- (void)assignmentsManager:(LABAssignmentsManager * __unused)assignmentsManager
   activeAssignmentsDidChange:( id<LABRevisionedAssignments>)activeAssignments {
  [self.reportedActiveAssignments addObject:RACTuplePack(activeAssignments.assignments,
                                                         activeAssignments.revisionID)];
}

- (void)assignmentsManager:(LABAssignmentsManager * __unused)assignmentsManager
   assignmentDidAffectUser:(id<LABAssignment>)assignment {
  [self.reportedAffectingAssignments addObject:assignment];
}

@end

SpecBegin(LABAssignmentsManager)

__block LABFakeAssignmentsSource *fakeSource1, *fakeSource2;
__block LABFakeStorage *storage;
__block LABFakeAssignmentsManagerDelegate *delegate;
__block LABAssignmentsManager *manager;

__block LABVariant *source1exp1Variant1;
__block LABVariant *source1exp1Variant2;
__block LABVariant *source1exp2Variant1;
__block LABVariant *source1exp2Variant2;
__block LABVariant *source2exp1Variant1;
__block LABVariant *source2exp1Variant2;
__block LABVariant *source2exp2Variant1;
__block LABVariant *source2exp2Variant2;

beforeEach(^{
  fakeSource1 = [[LABFakeAssignmentsSource alloc] init];
  source1exp1Variant1 = LABCreateVariant(@"bobVar",  @{@"foo": @"bar", @"baz": @"thud"}, @"exp1");
  source1exp1Variant2 = LABCreateVariant(@"blobVar",  @{@"foo": @"thud", @"baz": @"bar"}, @"exp1");
  source1exp2Variant1 = LABCreateVariant(@"fooVar",  @{@"bob": @2, @"bab": @"thud"}, @"exp2");
  source1exp2Variant2 = LABCreateVariant(@"barVar",  @{@"bob": @3, @"bab": @"bar"}, @"exp2");

  fakeSource1.allExperiments = @{
    @"exp1": @[source1exp1Variant1, source1exp1Variant2],
    @"exp2": @[source1exp2Variant1, source1exp2Variant2]
  };
  fakeSource1.name = @"fake1";

  source2exp1Variant1 =
      LABCreateVariant(@"bobVar",  @{@"ping": @"pong", @"flip": @"flop"}, @"exp1");
  source2exp1Variant2 =
      LABCreateVariant(@"blobVar",  @{@"ping": @"pang", @"flip": @"flap"}, @"exp1");
  source2exp2Variant1 = LABCreateVariant(@"fooVar",  @{@"que": @4, @"quee": @"bar"}, @"exp2");
  source2exp2Variant2 = LABCreateVariant(@"barVar",  @{@"que": @9, @"quee": @"baz"}, @"exp2");

  fakeSource2 = [[LABFakeAssignmentsSource alloc] init];
  fakeSource2.allExperiments = @{
    @"exp1": @[source2exp1Variant1, source2exp1Variant2],
    @"exp2": @[source2exp2Variant1, source2exp2Variant2]
  };
  fakeSource2.name = @"fake2";

  storage = [[LABFakeStorage alloc] init];
  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc] initWithAssignmentSources:@[fakeSource1, fakeSource2]
                                                            delegate:delegate storage:storage];
});

it(@"should have no active assignments if sources do not have active assignments", ^{
  expect(manager.activeAssignments.assignments).to.haveCount(0);
});

it(@"should have assignments from one source", ^{
  [fakeSource1 updateActiveVariants:@{
    @"exp1": source1exp1Variant1.name,
    @"exp2": source1exp2Variant1.name
  }];

  auto exp1Assignments = LABFakeAssignments(source1exp1Variant1, fakeSource1.name);
  auto exp2Assignments = LABFakeAssignments(source1exp2Variant1, fakeSource1.name);
  auto expectedAssignments =
      [exp1Assignments mtl_dictionaryByAddingEntriesFromDictionary:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments.assignments)).to.equal(expectedAssignments);
});

it(@"should merge assignments from all sources", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  auto expectedAssignments = LABFakeAssignments(source1exp1Variant2, fakeSource1.name);

  expect(LABFakeAssignments(manager.activeAssignments.assignments)).to.equal(expectedAssignments);

  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant1.name}];
  expectedAssignments = [expectedAssignments mtl_dictionaryByAddingEntriesFromDictionary:
                         LABFakeAssignments(source2exp1Variant1, fakeSource2.name)];

  expect(LABFakeAssignments(manager.activeAssignments.assignments)).to.equal(expectedAssignments);
});

it(@"should update assignments when source assignments update", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  [fakeSource1 updateActiveVariants:@{@"exp1": [NSNull null], @"exp2": source1exp2Variant2.name}];

  auto exp1Assignments = LABFakeAssignments(source1exp2Variant2, fakeSource1.name);
  auto exp2Assignments = LABFakeAssignments(source2exp1Variant2, fakeSource2.name);
  auto expectedAssignments =
      [exp1Assignments mtl_dictionaryByAddingEntriesFromDictionary:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments.assignments)).to.equal(expectedAssignments);
});

it(@"should update revision id when active assignments change", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  auto revisionID = manager.activeAssignments.revisionID;

  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  expect(manager.activeAssignments.revisionID).to.equal(revisionID);
});

it(@"should persist revision id source variants do not change", ^{
  auto revisionIDs = [NSMutableSet set];
  [revisionIDs addObject:manager.activeAssignments.revisionID];
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [revisionIDs addObject:manager.activeAssignments.revisionID];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  [revisionIDs addObject:manager.activeAssignments.revisionID];

  expect(revisionIDs).to.haveCount(3);
});

it(@"should persist with the same active assignments if source variants do not change", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];

  auto activeAssignments = manager.activeAssignments;

  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  expect(manager.activeAssignments).to.equal(activeAssignments);
});

it(@"should not persist assignments if source variants change between instance initializations", ^{
  storage = [[LABFakeStorage alloc] init];
  @autoreleasepool {
    manager = [[LABAssignmentsManager alloc]
               initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
               storage:storage];

    [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
    [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
    manager = nil;
  }

  auto activeAssignments = manager.activeAssignments;

  [fakeSource1 updateActiveVariants:@{@"exp1": [NSNull null], @"exp2": source1exp2Variant2.name}];

  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  expect(manager.activeAssignments).notTo.equal(activeAssignments);

  auto exp1Assignments = LABFakeAssignments(source1exp2Variant2, fakeSource1.name);
  auto exp2Assignments = LABFakeAssignments(source2exp1Variant2, fakeSource2.name);
  auto expectedAssignments =
      [exp1Assignments mtl_dictionaryByAddingEntriesFromDictionary:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments.assignments)).to.equal(expectedAssignments);
});

it(@"should stabilize user experience in all sources", ^{
  [manager stabilizeUserExperienceAssignments];

  expect(fakeSource1.stabilizeUserExperienceAssignmentsRequestedCount).to.equal(1);
  expect(fakeSource1.stabilizeUserExperienceAssignmentsRequestedCount).to.equal(1);

  [manager stabilizeUserExperienceAssignments];

  expect(fakeSource1.stabilizeUserExperienceAssignmentsRequestedCount).to.equal(2);
  expect(fakeSource1.stabilizeUserExperienceAssignmentsRequestedCount).to.equal(2);
});

it(@"should update all sources", ^{
  [manager updateActiveAssignments];

  expect(fakeSource1.updateRequestedCount).to.equal(1);
  expect(fakeSource2.updateRequestedCount).to.equal(1);

  [manager updateActiveAssignments];

  expect(fakeSource1.updateRequestedCount).to.equal(2);
  expect(fakeSource2.updateRequestedCount).to.equal(2);
});

it(@"should complete update if all sources complete", ^{
  expect([manager updateActiveAssignments]).to.complete();
});

it(@"should complete update on main thread", ^{
  fakeSource1.updateSignal = [[RACSignal empty] deliverOn:[RACScheduler scheduler]];
  fakeSource2.updateSignal = [[RACSignal empty] deliverOn:[RACScheduler scheduler]];

  auto recorder = [[[manager updateActiveAssignments] materialize] testRecorder];

  expect(recorder).will.deliverValuesOnMainThread();
  expect(recorder).to.sendValues(@[[RACEvent completedEvent]]);
});

it(@"should not complete update if some sources do not complete", ^{
  auto updateSubject1 = [RACSubject subject];
  auto updateSubject2 = [RACSubject subject];

  fakeSource1.updateSignal = updateSubject1;
  fakeSource2.updateSignal = updateSubject2;

  auto updateSignal = [manager updateActiveAssignments];

  expect(updateSignal).notTo.complete();

  [updateSubject1 sendCompleted];
  expect(updateSignal).notTo.complete();

  [updateSubject2 sendCompleted];
  expect(updateSignal).to.complete();
});

it(@"should err on update if one of the sources errs during an update", ^{
  auto updateSubject2 = [RACSubject subject];
  fakeSource2.updateSignal = updateSubject2;

  auto updateSignal = [manager updateActiveAssignments];

  auto error = [NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed];
  [updateSubject2 sendError:[NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed]];
  expect(updateSignal).to.sendError(error);
});

it(@"should update all sources in background", ^{
  [manager updateActiveAssignmentsInBackground];

  expect(fakeSource1.updateInBackgroundRequestedCount).to.equal(1);
  expect(fakeSource2.updateInBackgroundRequestedCount).to.equal(1);

  [manager updateActiveAssignmentsInBackground];

  expect(fakeSource1.updateInBackgroundRequestedCount).to.equal(2);
  expect(fakeSource2.updateInBackgroundRequestedCount).to.equal(2);
});

it(@"should return background update results on main thread", ^{
  fakeSource1.backgroundUpdateSignal =
      [[RACSignal return:@(UIBackgroundFetchResultNoData)] deliverOn:[RACScheduler scheduler]];
  fakeSource2.backgroundUpdateSignal =
      [[RACSignal return:@(UIBackgroundFetchResultNoData)] deliverOn:[RACScheduler scheduler]];

  auto recorder = [[[manager updateActiveAssignmentsInBackground] materialize] testRecorder];

  expect(recorder).will.deliverValuesOnMainThread();
  expect(recorder).to.sendValues(@[
    [RACEvent eventWithValue:@(UIBackgroundFetchResultNoData)],
    [RACEvent completedEvent]
  ]);
});

it(@"should return no new data if all background updates finish with no new data", ^{
  expect([manager updateActiveAssignmentsInBackground]).to
      .sendValues(@[@(UIBackgroundFetchResultNoData)]);
});

it(@"should return fetch failed if one of the background updates fails", ^{
  auto updateSubject1 = [RACSubject subject];
  auto updateSubject2 = [RACSubject subject];
  fakeSource1.backgroundUpdateSignal = updateSubject1;
  fakeSource2.backgroundUpdateSignal = updateSubject2;

  auto updateSignal = [manager updateActiveAssignmentsInBackground];

  [updateSubject1 sendNext:@(UIBackgroundFetchResultNoData)];
  [updateSubject2 sendNext:@(UIBackgroundFetchResultFailed)];
  expect(updateSignal).to.sendValues(@[@(UIBackgroundFetchResultFailed)]);

  updateSignal = [[manager updateActiveAssignmentsInBackground] testRecorder];

  [updateSubject1 sendNext:@(UIBackgroundFetchResultNewData)];
  [updateSubject2 sendNext:@(UIBackgroundFetchResultFailed)];
  expect(updateSignal).to.sendValues(@[@(UIBackgroundFetchResultFailed)]);

  updateSignal = [[manager updateActiveAssignmentsInBackground] testRecorder];

  [updateSubject2 sendNext:@(UIBackgroundFetchResultNewData)];
  [updateSubject1 sendNext:@(UIBackgroundFetchResultFailed)];
  expect(updateSignal).to.sendValues(@[@(UIBackgroundFetchResultFailed)]);
});

it(@"should return new data fetched if one of the background updates has new data", ^{
  auto updateSubject2 = [RACSubject subject];
  fakeSource2.backgroundUpdateSignal = updateSubject2;

  auto updateSignal = [manager updateActiveAssignmentsInBackground];

  [updateSubject2 sendNext:@(UIBackgroundFetchResultNewData)];
  expect(updateSignal).to.sendValues(@[@(UIBackgroundFetchResultNewData)]);
});

it(@"should update observer when an assignment is loaded", ^{
  auto expectedAssignments = [NSMutableArray array];

  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [expectedAssignments addObject:RACTuplePack(manager.activeAssignments.assignments,
                                              manager.activeAssignments.revisionID)];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  [expectedAssignments addObject:RACTuplePack(manager.activeAssignments.assignments,
                                              manager.activeAssignments.revisionID)];
  [fakeSource1 updateActiveVariants:@{@"exp1": [NSNull null], @"exp2": source1exp2Variant2.name}];
  [expectedAssignments addObject:RACTuplePack(manager.activeAssignments.assignments,
                                              manager.activeAssignments.revisionID)];

  expect(delegate.reportedActiveAssignments).to.equal(expectedAssignments);
});

it(@"should not update delegate when the current assignment is as the stored assignment", ^{
  auto expectedAssignments = [NSMutableArray array];

  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [expectedAssignments addObject:RACTuplePack(manager.activeAssignments.assignments,
                                              manager.activeAssignments.revisionID)];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  [expectedAssignments addObject:RACTuplePack(manager.activeAssignments.assignments,
                                              manager.activeAssignments.revisionID)];

  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  expect(delegate.reportedActiveAssignments).to.equal(expectedAssignments);
});

it(@"should update delegate when the current assignment is different then the stored assignemnt", ^{
  storage = [[LABFakeStorage alloc] init];
  @autoreleasepool {
    manager = [[LABAssignmentsManager alloc]
               initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
               storage:storage];

    [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
    [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
    manager = nil;
  }

  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant1.name}];
  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  auto expectedValue = RACTuplePack(manager.activeAssignments.assignments,
                                    manager.activeAssignments.revisionID);
  expect(delegate.reportedActiveAssignments.lastObject).to.equal(expectedValue);
});

it(@"should update delegate with affecting assignments", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": @"blobVar"}];

  auto fooAssignment = manager.activeAssignments.assignments[@"foo"];
  auto bazAssignment = manager.activeAssignments.assignments[@"baz"];

  [manager reportAssignmentAffectedUser:bazAssignment];
  [manager reportAssignmentAffectedUser:fooAssignment];

  expect(delegate.reportedAffectingAssignments).to.equal(@[bazAssignment, fooAssignment]);
});

it(@"should update delegate with affecting assignments after assignments change", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];

  auto fooAssignment = manager.activeAssignments.assignments[@"foo"];
  auto bazAssignment = manager.activeAssignments.assignments[@"baz"];

  [fakeSource1 updateActiveVariants:@{@"exp2": source1exp2Variant2.name}];

  [manager reportAssignmentAffectedUser:bazAssignment];
  [manager reportAssignmentAffectedUser:fooAssignment];

  expect(delegate.reportedAffectingAssignments).to.equal(@[bazAssignment, fooAssignment]);
});

SpecEnd
