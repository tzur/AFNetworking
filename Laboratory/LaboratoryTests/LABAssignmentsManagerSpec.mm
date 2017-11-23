// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsManager.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSDictionary+Operations.h>
#import <LTKit/NSSet+Functional.h>
#import <LTKitTestUtils/LTFakeStorage.h>

#import "LABFakeAssignmentsSource.h"
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

static NSDictionary *LABFakeAssignment(LABAssignment *assignment) {
  return LABFakeAssignment(assignment.value, assignment.key, assignment.variant,
                           assignment.experiment, assignment.sourceName);
}

static NSDictionary<NSString *, NSDictionary *> *
    LABFakeAssignments(NSDictionary<NSString *, LABAssignment *> *assignments) {
  auto result = [NSMutableDictionary dictionary];

  [assignments enumerateKeysAndObjectsUsingBlock:^(NSString *key, LABAssignment *assignment,
                                                   BOOL *) {
    result[key] = LABFakeAssignment(assignment);
  }];

  return [result copy];
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

/// Assignments that were reported to the receiver as affecting user experience. The tuples are
/// pairs of \c LABAssignment objects and \c action.
@property (readonly, nonatomic) NSMutableArray<RACTuple *> *reportedAffectingAssignments;

@end

@implementation LABFakeAssignmentsManagerDelegate

- (instancetype)init {
  if (self = [super init]) {
    _reportedAffectingAssignments = [NSMutableArray array];
  }
  return self;
}

- (void)assignmentsManager:(LABAssignmentsManager * __unused)assignmentsManager
   assignmentDidAffectUser:(LABAssignment *)assignment reason:(NSString *)reason {
  [self.reportedAffectingAssignments addObject:RACTuplePack((id)assignment, reason)];
}

@end

SpecBegin(LABAssignmentsManager)

__block LABFakeAssignmentsSource *fakeSource1, *fakeSource2;
__block LTFakeStorage *storage;
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

  storage = [[LTFakeStorage alloc] init];
  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc] initWithAssignmentSources:@[fakeSource1, fakeSource2]
                                                            delegate:delegate storage:storage];
});

it(@"should have no active assignments if sources do not have active assignments", ^{
  expect(manager.activeAssignments).to.haveCount(0);
});

it(@"should have assignments from one source", ^{
  [fakeSource1 updateActiveVariants:@{
    @"exp1": source1exp1Variant1.name,
    @"exp2": source1exp2Variant1.name
  }];

  auto exp1Assignments = LABFakeAssignments(source1exp1Variant1, fakeSource1.name);
  auto exp2Assignments = LABFakeAssignments(source1exp2Variant1, fakeSource1.name);
  auto expectedAssignments = [exp1Assignments lt_merge:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments)).to.equal(expectedAssignments);
});

it(@"should merge assignments from all sources", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  auto expectedAssignments = LABFakeAssignments(source1exp1Variant2, fakeSource1.name);

  expect(LABFakeAssignments(manager.activeAssignments)).to.equal(expectedAssignments);

  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant1.name}];
  expectedAssignments = [expectedAssignments
                         lt_merge:LABFakeAssignments(source2exp1Variant1, fakeSource2.name)];

  expect(LABFakeAssignments(manager.activeAssignments)).to.equal(expectedAssignments);
});

it(@"should update assignments when source assignments update", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  [fakeSource1 updateActiveVariants:@{@"exp1": [NSNull null], @"exp2": source1exp2Variant2.name}];

  auto exp1Assignments = LABFakeAssignments(source1exp2Variant2, fakeSource1.name);
  auto exp2Assignments = LABFakeAssignments(source2exp1Variant2, fakeSource2.name);
  auto expectedAssignments = [exp1Assignments lt_merge:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments)).to.equal(expectedAssignments);
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
  storage = [[LTFakeStorage alloc] init];
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
  auto expectedAssignments = [exp1Assignments lt_merge:exp2Assignments];

  expect(LABFakeAssignments(manager.activeAssignments)).to.equal(expectedAssignments);
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

it(@"should update delegate when assignments are activated", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];

  auto expectedAssignments = [LABFakeAssignments(source1exp1Variant2, fakeSource1.name).allValues
                              arrayByAddingObjectsFromArray:
                              LABFakeAssignments(source2exp1Variant2, fakeSource2.name).allValues];

  expect([[delegate.reportedAffectingAssignments lt_map:^(RACTuple *assignments) {
      return RACTuplePack(LABFakeAssignment(assignments.first), assignments.second);
  }] lt_set]).to.equal([[expectedAssignments lt_map:^(NSDictionary * assignment) {
    return RACTuplePack(assignment, kLABAssignmentAffectedUserReasonActivatedForDevice);
  }] lt_set]);
});

it(@"should update delegate when assignment are deactivated", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];

  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc]
           initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
           storage:storage];

  [fakeSource1 updateActiveVariants:@{@"exp1": [NSNull null]}];

  auto expectedAssignments = [[LABFakeAssignments(source1exp1Variant2, fakeSource1.name).allValues
      lt_map:^id _Nonnull(NSDictionary *assignment) {
        return RACTuplePack(assignment, kLABAssignmentAffectedUserReasonDeactivatedForDevice);
      }] lt_set];

  expect([[delegate.reportedAffectingAssignments lt_map:^(RACTuple *assignments) {
      return RACTuplePack(LABFakeAssignment(assignments.first), assignments.second);
  }] lt_set]).to.equal(expectedAssignments);
});

it(@"should not update delegate when the current assignment is as the stored assignment", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
  [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
  auto expectedAssignments = delegate.reportedAffectingAssignments;

  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  expect(delegate.reportedAffectingAssignments).to.equal(expectedAssignments);
});

it(@"should update delegate when the current assignment is different then the stored assignemnt", ^{
  storage = [[LTFakeStorage alloc] init];
  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  @autoreleasepool {
    manager = [[LABAssignmentsManager alloc]
               initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
               storage:storage];

    [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];
    [fakeSource2 updateActiveVariants:@{@"exp1": source2exp1Variant2.name}];
    manager = nil;
  }

  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant1.name}];
  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

   auto expectedActivatedAssignments =
      [[LABFakeAssignments(source1exp1Variant1, fakeSource1.name).allValues
       lt_map:^id _Nonnull(NSDictionary *assignment) {
         return RACTuplePack(assignment, kLABAssignmentAffectedUserReasonActivatedForDevice);
       }] lt_set];

  auto expectedDeactivatedAssignments =
      [[LABFakeAssignments(source1exp1Variant2, fakeSource1.name).allValues
       lt_map:^id _Nonnull(NSDictionary *assignment) {
         return RACTuplePack(assignment, kLABAssignmentAffectedUserReasonDeactivatedForDevice);
       }] lt_set];

  expect([[delegate.reportedAffectingAssignments lt_map:^(RACTuple *assignments) {
    return RACTuplePack(LABFakeAssignment(assignments.first), assignments.second);
  }] lt_set]).to.equal([expectedActivatedAssignments
                        setByAddingObjectsFromSet:expectedDeactivatedAssignments]);
});

it(@"should update delegate with affecting assignments", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": @"blobVar"}];

  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  auto fooAssignment = manager.activeAssignments[@"foo"];
  auto bazAssignment = manager.activeAssignments[@"baz"];

  [manager reportAssignmentAffectedUser:bazAssignment reason:@"bar"];
  [manager reportAssignmentAffectedUser:fooAssignment reason:@"thud"];

  expect(delegate.reportedAffectingAssignments).to.equal(@[
    RACTuplePack((id)bazAssignment, @"bar"),
    RACTuplePack((id)fooAssignment, @"thud")
  ]);
});

it(@"should update delegate with affecting assignments after assignments change", ^{
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];

  auto fooAssignment = manager.activeAssignments[@"foo"];
  auto bazAssignment = manager.activeAssignments[@"baz"];

  [fakeSource1 updateActiveVariants:@{@"exp2": source1exp2Variant2.name}];

  delegate = [[LABFakeAssignmentsManagerDelegate alloc] init];
  manager = [[LABAssignmentsManager alloc]
             initWithAssignmentSources:@[fakeSource1, fakeSource2] delegate:delegate
             storage:storage];

  [manager reportAssignmentAffectedUser:bazAssignment reason:@"bar"];
  [manager reportAssignmentAffectedUser:fooAssignment reason:@"thud"];

  expect(delegate.reportedAffectingAssignments).to.equal(@[
    RACTuplePack((id)bazAssignment, @"bar"),
    RACTuplePack((id)fooAssignment, @"thud")
  ]);
});

it(@"should update delegate when assignments are activated before exposing the assignment", ^{
  [RACObserve(manager, activeAssignments)
   subscribeNext:^(NSDictionary<NSString *, LABAssignment *> *activeAssignments) {
     for (LABAssignment *assignment in activeAssignments.allValues) {
       [manager reportAssignmentAffectedUser:assignment reason:@"foo"];
     }
   }];
  [fakeSource1 updateActiveVariants:@{@"exp1": source1exp1Variant2.name}];

  auto expectedAssignments = LABFakeAssignments(source1exp1Variant2, fakeSource1.name).allValues;
  auto expectedActivateReports = [[expectedAssignments lt_map:^(NSDictionary * assignment) {
    return RACTuplePack(assignment, kLABAssignmentAffectedUserReasonActivatedForDevice);
  }] lt_set];
  auto expectedFooReports = [[expectedAssignments lt_map:^(NSDictionary * assignment) {
    return RACTuplePack(assignment, @"foo");
  }] lt_set];

  auto reportedActivatedAssignments =
      [delegate.reportedAffectingAssignments
       subarrayWithRange:NSMakeRange(0, expectedAssignments.count)];
  auto reportedFooAssignments =
      [delegate.reportedAffectingAssignments
       subarrayWithRange:NSMakeRange(expectedAssignments.count, expectedAssignments.count)];

  expect([[reportedActivatedAssignments lt_map:^(RACTuple *assignments) {
    return RACTuplePack(LABFakeAssignment(assignments.first), assignments.second);
  }] lt_set]).to.equal(expectedActivateReports);

  expect([[reportedFooAssignments lt_map:^(RACTuple *assignments) {
    return RACTuplePack(LABFakeAssignment(assignments.first), assignments.second);
  }] lt_set]).to.equal(expectedFooReports);
});

SpecEnd
