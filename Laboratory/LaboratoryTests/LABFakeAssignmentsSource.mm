// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABFakeAssignmentsSource.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>

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
    self.fetchAllExperimentsAndVariantsSignal = [RACObserve(self, allExperiments)
        map:^NSDictionary *(NSDictionary<NSString *, NSArray<LABVariant *> *> *allExperiments) {
          return [allExperiments lt_mapValues:^(NSString *, NSArray<LABVariant *> *variants) {
            return [[variants lt_map:^(LABVariant *variant) {
              return variant.name;
            }] lt_set];
          }];
        }];
    [self setupAssignmentsFetchSignalBlock];
  }
  return self;
}

- (void)setupAssignmentsFetchSignalBlock {
  @weakify(self)
  self.fetchAssignmentsSignalBlock = ^(NSString *experiment, NSString *variant) {
    @strongify(self)
    if (!self.allExperiments[experiment]) {
      return [RACSignal error:[NSError lab_errorWithCode:LABErrorCodeExperimentNotFound
                                    associatedExperiment:experiment]];
    }

    auto _Nullable assignments =
        [self.allExperiments[experiment] lt_find:^(LABVariant *var) {
          return [var.name isEqual:variant];
        }].assignments;

    return assignments ? [RACSignal return:assignments] :
        [RACSignal error:[NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                               associatedExperiment:experiment associatedVariant:variant]];
  };
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

- (RACSignal *)fetchAllExperimentsAndVariants {
  return [self.fetchAllExperimentsAndVariantsSignal take:1];
}

- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant {
  return self.fetchAssignmentsSignalBlock(experiment, variant);
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
