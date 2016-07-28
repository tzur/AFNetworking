// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventStateFilter+DefaultFilters.h"

#import "LTContentTouchEventDistancePredicate.h"
#import "LTContentTouchEventOrPredicate.h"
#import "LTContentTouchEventTimeIntervalPredicate.h"

static NSSet<Class> *LTClassesInArray(NSArray<NSObject *> *array) {
  NSMutableSet<Class> *classes = [NSMutableSet set];
  for (NSObject *object in array) {
    [classes addObject:object.class];
  }
  return [classes copy];
}

SpecBegin(LTContentTouchEventStateFilter_DefaultFilters)

context(@"filters", ^{
  it(@"should create common filter rejecting stationary touches", ^{
    LTContentTouchEventStateFilter *filter =
        [LTContentTouchEventStateFilter touchFilterRejectingStationaryTouches];

    expect(filter.predicateForPossibleState)
        .to.beKindOf(LTContentTouchEventDistancePredicate.class);
    expect(filter.predicateForActiveState)
        .to.beKindOf(LTContentTouchEventDistancePredicate.class);

    expect([(LTContentTouchEventDistancePredicate *)filter.predicateForPossibleState
            minimumDistance]).to.equal(kMinimumViewDistanceForPossibleState);
    expect([(LTContentTouchEventDistancePredicate *)filter.predicateForActiveState
            minimumDistance]).to.equal(kMinimumViewDistanceForActiveState);
  });

  it(@"should create common filter accepting stationary touches", ^{
    LTContentTouchEventStateFilter *filter =
        [LTContentTouchEventStateFilter touchFilterAcceptingStationaryTouches];

    expect(filter.predicateForPossibleState).to.beKindOf(LTContentTouchEventOrPredicate.class);
    NSArray<id<LTContentTouchEventPredicate>> *possiblePredicates =
        [(LTContentTouchEventOrPredicate *)filter.predicateForPossibleState predicates];
    expect(possiblePredicates).to.haveCountOf(2);
    expect(LTClassesInArray(possiblePredicates))
        .to.contain(LTContentTouchEventTimeIntervalPredicate.class);
    expect(LTClassesInArray(possiblePredicates))
        .to.contain(LTContentTouchEventDistancePredicate.class);

    for (id predicate in possiblePredicates) {
      if ([predicate isKindOfClass:LTContentTouchEventDistancePredicate.class]) {
        expect([predicate minimumDistance]).to.equal(kMinimumViewDistanceForPossibleState);
      } else if ([predicate isKindOfClass:LTContentTouchEventTimeIntervalPredicate.class]) {
        expect([predicate minimumInterval]).to.equal(kMinimumTimeIntervalForPossibleState);
      }
    }

    expect(filter.predicateForActiveState).to.beKindOf(LTContentTouchEventOrPredicate.class);
    NSArray<id<LTContentTouchEventPredicate>> *activePredicates =
        [(LTContentTouchEventOrPredicate *)filter.predicateForActiveState predicates];
    expect(activePredicates).to.haveCountOf(2);
    expect(LTClassesInArray(activePredicates))
        .to.contain(LTContentTouchEventTimeIntervalPredicate.class);
    expect(LTClassesInArray(activePredicates))
        .to.contain(LTContentTouchEventDistancePredicate.class);

    for (id predicate in activePredicates) {
      if ([predicate isKindOfClass:LTContentTouchEventDistancePredicate.class]) {
        expect([predicate minimumDistance]).to.equal(kMinimumViewDistanceForActiveState);
      } else if ([predicate isKindOfClass:LTContentTouchEventTimeIntervalPredicate.class]) {
        expect([predicate minimumInterval]).to.equal(kMinimumTimeIntervalForActiveState);
      }
    }
  });
});

SpecEnd
