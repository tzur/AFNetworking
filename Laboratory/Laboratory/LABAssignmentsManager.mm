// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsManager.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/LTKeyValuePersistentStorage.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSSet+Operations.h>

#import "LABAssignmentsSource.h"

NSString * const kLABAssignmentAffectedUserReasonActivatedForDevice = @"activated_for_device";
NSString * const kLABAssignmentAffectedUserReasonDeactivatedForDevice = @"deactivated_for_device";
NSString * const kLABAssignmentAffectedUserReasonInitiated = @"initiated";
NSString * const kLABAssignmentAffectedUserReasonDisplayed = @"displayed";

@implementation LABAssignment

@synthesize value = _value;
@synthesize key = _key;
@synthesize variant = _variant;
@synthesize experiment = _experiment;
@synthesize sourceName = _sourceName;

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSDictionary * _Nullable value =
      [aDecoder decodePropertyListForKey:@instanceKeypath(LABAssignment, value)];
  NSString * _Nullable key = [aDecoder decodeObjectOfClass:[NSString class]
                                                    forKey:@instanceKeypath(LABAssignment, key)];
  NSString * _Nullable variant =
      [aDecoder decodeObjectOfClass:[NSString class]
                             forKey:@instanceKeypath(LABAssignment, variant)];
  NSString * _Nullable experiment =
      [aDecoder decodeObjectOfClass:[NSString class]
                             forKey:@instanceKeypath(LABAssignment, experiment)];
  NSString * _Nullable sourceName =
      [aDecoder decodeObjectOfClass:[NSString class]
                             forKey:@instanceKeypath(LABAssignment, sourceName)];

  if (!value || ![key isKindOfClass:NSString.class] || ![variant isKindOfClass:NSString.class] ||
      ![experiment isKindOfClass:NSString.class] || ![sourceName isKindOfClass:NSString.class]) {
    return nil;
  }

  return [self initWithValue:value key:key variant:variant experiment:experiment
                  sourceName:sourceName];
}

- (instancetype)initWithValue:(id)value key:(NSString *)key variant:(NSString *)variant
                   experiment:(NSString *)experiment sourceName:(NSString *)sourceName {
  if (self = [super init]) {
    _value = value;
    _key = key;
    _variant = variant;
    _experiment = experiment;
    _sourceName = sourceName;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.value forKey:@instanceKeypath(LABAssignment, value)];
  [aCoder encodeObject:self.key forKey:@instanceKeypath(LABAssignment, key)];
  [aCoder encodeObject:self.variant forKey:@instanceKeypath(LABAssignment, variant)];
  [aCoder encodeObject:self.experiment forKey:@instanceKeypath(LABAssignment, experiment)];
  [aCoder encodeObject:self.sourceName forKey:@instanceKeypath(LABAssignment, sourceName)];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

@interface LABAssignmentsManager ()

/// Used to provide and update active assignments.
@property (readonly, nonatomic) NSArray<id<LABAssignmentsSource>> *sources;

/// All currently active assignments.
@property (readwrite, nonatomic) NSDictionary<NSString *, LABAssignment *> *activeAssignments;

/// Used to persist active assignments and their revision ID.
@property (readonly, nonatomic) id<LTKeyValuePersistentStorage> storage;

/// Used to report assignments changes and user affecting assignments.
@property (weak, readonly, nonatomic) id<LABAssignmentsManagerDelegate> delegate;

@end

@implementation LABAssignmentsManager

- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
                                 delegate:(id<LABAssignmentsManagerDelegate>)delegate {
  return [self initWithAssignmentSources:sources delegate:delegate
                                 storage:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithAssignmentSources:(NSArray<id<LABAssignmentsSource>> *)sources
                                 delegate:(id<LABAssignmentsManagerDelegate>)delegate
                                  storage:(id<LTKeyValuePersistentStorage>)storage {
  if (self = [super init]) {
    _sources = sources;
    _storage = storage;
    _delegate = delegate;
    self.activeAssignments = [self loadStoredActiveAssignments];
    [self bindActiveAssignments];
  }
  return self;
}

static NSString * const kStoredActiveAssignmentsKey = @"ActiveAssignments";

- (NSDictionary<NSString *, LABAssignment *> *)loadStoredActiveAssignments {
  NSData * _Nullable storedAssignmentsData =
      [self.storage objectForKey:kStoredActiveAssignmentsKey];
  if (![storedAssignmentsData isKindOfClass:NSData.class]) {
    return @{};
  }

  NSError *error;
  NSDictionary<NSString *, LABAssignment *> * _Nullable storedAssignments =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:storedAssignmentsData error:&error];

  if (!storedAssignments) {
    LogError(@"Failed to load model from key %@, error: %@", kStoredActiveAssignmentsKey, error);
    return @{};
  }

  if (![storedAssignments isKindOfClass:NSDictionary.class]) {
    LogError(@"Expected stored model to be of type: %@, got: %@", NSDictionary.class,
             [storedAssignments class]);
    return @{};
  }

  for (NSString *key in storedAssignments) {
    if (![key isKindOfClass:NSString.class]) {
      LogError(@"Expected stored assignments key to be of type: %@, got: %@", NSString.class,
               [key class]);
      return @{};
    }

    if (![storedAssignments[key] isKindOfClass:LABAssignment.class]) {
      LogError(@"Expected stored assignments value to be of type: %@, got: %@", LABAssignment.class,
               [storedAssignments[key] class]);
      return @{};
    }
  }

  return storedAssignments;
}

- (void)bindActiveAssignments {
  NSArray<RACSignal *> *allActiveVariants =
      [self.sources lt_map:^(id<LABAssignmentsSource> source) {
        return [RACObserve(source, activeVariants)
                map:^RACTuple *(NSSet<LABVariant *> * _Nullable variants) {
                  return RACTuplePack(source.name, variants);
                }];
      }];

  @weakify(self)
  [[[[RACSignal combineLatest:allActiveVariants]
      map:^NSDictionary<NSString *, LABAssignment *> *(RACTuple *values) {
        auto assignments = [NSMutableDictionary dictionary];
        auto allAssignmentsKeys = [NSMutableSet set];
        for (RACTuple *sourceAndVariants in values) {
          RACTupleUnpack(NSString *sourceName, NSSet<LABVariant *> *variants) = sourceAndVariants;
          for (LABVariant *variant in variants) {
            // If a key in \c variant exists in \c assignments, the whole variant is discarded.
            auto allVariantKeys = variant.assignments.allKeys;
            auto unionSet = [allAssignmentsKeys setByAddingObjectsFromArray:allVariantKeys];
            if (unionSet.count != allAssignmentsKeys.count + allVariantKeys.count) {
              continue;
            }

            [variant.assignments enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value,
                                                                     BOOL *) {
              assignments[key] =
                  [[LABAssignment alloc] initWithValue:value key:key variant:variant.name
                                            experiment:variant.experiment sourceName:sourceName];
              [allAssignmentsKeys addObject:key];
            }];
          }
        }

        return assignments;
      }]
      deliverOnMainThread]
      subscribeNext:^(NSDictionary<NSString *, LABAssignment *> *assignments) {
        @strongify(self)
        [self applyAssignmentsIfNeeded:assignments];
      }];
}

- (void)applyAssignmentsIfNeeded:(NSDictionary<NSString *, LABAssignment *> *)assignments {
  if ([self.activeAssignments isEqual:assignments]) {
    return;
  }

  auto currentAssignments = [self.activeAssignments.allValues lt_set];
  auto newAssignments = [assignments.allValues lt_set];

  auto activatedAssignments = [newAssignments lt_minus:currentAssignments];

  for (LABAssignment *assignment in activatedAssignments) {
    [self.delegate assignmentsManager:self assignmentDidAffectUser:assignment
                               reason:kLABAssignmentAffectedUserReasonActivatedForDevice];
  }

  auto deactivatedAssignments = [currentAssignments lt_minus:newAssignments];

  for (LABAssignment *assignment in deactivatedAssignments) {
    [self.delegate assignmentsManager:self assignmentDidAffectUser:assignment
                               reason:kLABAssignmentAffectedUserReasonDeactivatedForDevice];
  }

  self.activeAssignments = assignments;

  auto data = [NSKeyedArchiver archivedDataWithRootObject:self.activeAssignments];
  [self.storage setObject:data forKey:kStoredActiveAssignmentsKey];
}

#pragma mark -
#pragma mark LABAssignmentsManager
#pragma mark -

- (void)stabilizeUserExperienceAssignments {
  for (id<LABAssignmentsSource> source in self.sources) {
    if ([source respondsToSelector:@selector(stabilizeUserExperienceAssignments)]) {
      [source stabilizeUserExperienceAssignments];
    }
  }
}

- (void)reportAssignmentAffectedUser:(LABAssignment *)assignment reason:(NSString *)reason {
  [self.delegate assignmentsManager:self assignmentDidAffectUser:assignment reason:reason];
}

- (RACSignal *)updateActiveAssignments {
  auto updateSignals = [self.sources lt_map:^(id<LABAssignmentsSource> source) {
    if ([source respondsToSelector:@selector(update)]) {
      return [source update];
    }
    return [RACSignal empty];
  }];

  return [[[RACSignal combineLatest:updateSignals]
      deliverOnMainThread]
      replay];
}

- (RACSignal *)updateActiveAssignmentsInBackground {
  auto updateSignals = [self.sources lt_map:^(id<LABAssignmentsSource> source) {
    if ([source respondsToSelector:@selector(updateInBackground)]) {
      return [source updateInBackground];
    }
    return [RACSignal return:@(UIBackgroundFetchResultNoData)];
  }];

  return [[[[[RACSignal
     combineLatest:updateSignals]
     map:^NSNumber *(RACTuple *results) {
       auto resultState = @(UIBackgroundFetchResultNoData);
       for (NSNumber *result in results) {
         switch ((UIBackgroundFetchResult)result.unsignedIntegerValue) {
           case UIBackgroundFetchResultNoData:
             break;
           case UIBackgroundFetchResultNewData:
             resultState = @(UIBackgroundFetchResultNewData);
             break;
           case UIBackgroundFetchResultFailed:
             return @(UIBackgroundFetchResultFailed);
         }
       }
       return resultState;
     }]
     take:1]
     deliverOnMainThread]
     replay];
}

@end
