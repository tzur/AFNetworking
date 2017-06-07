// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABFakeAssignmentsSource.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>

#import "LABFakeAssignmentsSource.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LABFakeAssignmentsSource ()

/// Active experiments and their selected variants.
@property (readwrite, nonatomic, nullable)
    NSDictionary<NSString *, LABVariant *> *activeExperiments;

/// Amount of calls to the \c stabilizeUserExperienceAssignments method of this receiver.
@property (readwrite, nonatomic) NSUInteger stabilizeUserExperienceAssignmentsRequestedCount;

/// Amount of calls to the \c update method of this receiver.
@property (readwrite, nonatomic) NSUInteger updateRequestedCount;

/// Amount of calls to the \c updateInBackground method of this receiver.
@property (readwrite, nonatomic) NSUInteger updateInBackgroundRequestedCount;

@end

@implementation LABFakeAssignmentsSource

@synthesize activeVariants = _activeVariants;

- (instancetype)init {
  if (self = [super init]) {
    RAC(self, activeVariants) = [RACObserve(self, activeExperiments)
        map:^NSSet<LABVariant *> *(NSDictionary<NSString *, LABVariant *> *value) {
          return [value.allValues lt_set];
        }];
    self.updateSignal = [[RACSignal empty] replay];
    self.backgroundUpdateSignal = [[RACSignal return:@(UIBackgroundFetchResultNoData)] replay];
  }
  return self;
}

- (void)updateActiveVariants:(NSDictionary<NSString *, id> *)variants {
  NSMutableDictionary *activeVariants = [(self.activeExperiments ?: @{}) mutableCopy];

  [variants enumerateKeysAndObjectsUsingBlock:^(NSString *experiment, id variantName, BOOL *) {
    if ([variantName isKindOfClass:NSNull.class]) {
      [activeVariants removeObjectForKey:experiment];
      return;
    }

    LABVariant * _Nullable var = [self.allExperiments[experiment] lt_filter:^BOOL(LABVariant *var) {
      return [var.name isEqual:variantName];
    }].firstObject;
    LTParameterAssert(var, "Variant named %@ does not exist for experiment named %@", variantName,
                      experiment);
    
    activeVariants[experiment] = var;
  }];

  self.activeExperiments = [activeVariants copy];
}

#pragma mark -
#pragma mark LABAssignmentsSource
#pragma mark -

- (RACSignal *)fetchAllExperiments {
  return [RACSignal return:[self.allExperiments.allKeys lt_set]];
}

- (RACSignal *)fetchVariantsForExperiment:(NSString *)experiment {
  auto _Nullable variants =
      [[self.allExperiments[experiment] lt_map:^(LABVariant *variant) {
        return variant.name;
      }] lt_set];

  return variants ? [RACSignal return:variants] :
      [RACSignal error:[NSError lab_errorWithCode:LABErrorCodeExperimentNotFound
                             associatedExperiment:experiment]];
}

- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant {
  auto _Nullable assignments =
      [self.allExperiments[experiment] lt_filter:^(LABVariant *var) {
        return [var.name isEqual:variant];
      }].firstObject.assignments;

  return assignments ? [RACSignal return:assignments] :
      [RACSignal error:[NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                             associatedExperiment:experiment associatedVariant:variant]];
}

- (RACSignal *)update {
  ++self.updateRequestedCount;
  return self.updateSignal;
}

- (RACSignal *)updateInBackground {
  ++self.updateInBackgroundRequestedCount;
  return self.backgroundUpdateSignal;
}

- (void)stabilizeUserExperienceAssignments {
  ++self.stabilizeUserExperienceAssignmentsRequestedCount;
}

@end

NS_ASSUME_NONNULL_END
