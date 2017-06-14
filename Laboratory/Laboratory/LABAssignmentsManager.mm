// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABAssignmentsManager.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>

#import "LABAssignmentsSource.h"
#import "LABStorage.h"

/// Default implementation of \c LABAssignment protocol.
@interface LABAssignment : MTLModel <LABAssignment>

- (instancetype)init NS_UNAVAILABLE;

/// Initiliazes with the given parameters.
- (instancetype)initWithValue:(id)value key:(NSString *)key variant:(NSString *)variant
                   experiment:(NSString *)experiment sourceName:(NSString *)sourceName
    NS_DESIGNATED_INITIALIZER;

@end

@implementation LABAssignment

@synthesize value = _value;
@synthesize key = _key;
@synthesize variant = _variant;
@synthesize experiment = _experiment;
@synthesize sourceName = _sourceName;

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

@end

/// Default implementation of \c LABRevisionedAssignments protocol.
@interface LABRevisionedAssignments : MTLModel <LABRevisionedAssignments>

/// Returns an instance with empty \c assignments and a randomly generated \c revisonID.
+ (instancetype)empty;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given parameters.
- (instancetype)initWithAssignments:(NSDictionary<NSString *, LABAssignment *> *)assignments
                         revisionID:(NSUUID *)revisionID NS_DESIGNATED_INITIALIZER;

/// Revisioned assignments.
///
/// @note This property is KVO-compliant.
@property (readonly, nonatomic) NSDictionary<NSString *, LABAssignment *> *assignments;

@end

@implementation LABRevisionedAssignments

@synthesize revisionID = _revisionID;

+ (instancetype)empty {
  return [[self alloc] initWithAssignments:@{} revisionID:[NSUUID UUID]];
}

- (instancetype)initWithAssignments:(NSDictionary<NSString *, LABAssignment *> *)assignments
                         revisionID:(NSUUID *)revisionID {
  if (self = [super init]) {
    _assignments = assignments;
    _revisionID = revisionID;
  }
  return self;
}

@end

@interface LABAssignmentsManager ()

/// Used to provide and update active assignments.
@property (readonly, nonatomic) NSArray<id<LABAssignmentsSource>> *sources;

/// All currently active assignments and their revision.
@property (readwrite, nonatomic, nullable) LABRevisionedAssignments *activeAssignments;

/// Used to persist active assignments and their revision ID.
@property (readonly, nonatomic) id<LABStorage> storage;

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
                                  storage:(id<LABStorage>)storage {
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

- (LABRevisionedAssignments *)loadStoredActiveAssignments {
  NSData * _Nullable storedAssignmentsData =
      [self.storage objectForKey:kStoredActiveAssignmentsKey];
  if (![storedAssignmentsData isKindOfClass:NSData.class]) {
    return [LABRevisionedAssignments empty];
  }

  NSError *error;
  LABRevisionedAssignments * _Nullable storedAssignments =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:storedAssignmentsData error:&error];

  if (!storedAssignments) {
    LogError(@"Failed to load model from key %@, error: %@", kStoredActiveAssignmentsKey, error);
    return [LABRevisionedAssignments empty];
  }

  if (![storedAssignments isKindOfClass:LABRevisionedAssignments.class]) {
    LogError(@"Expected stored model to be of type: %@, got: %@", NSDictionary.class,
             [storedAssignments class]);
    return [LABRevisionedAssignments empty];
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
  if (![self shouldApply:assignments]) {
    return;
  }

  self.activeAssignments =
      [[LABRevisionedAssignments alloc] initWithAssignments:assignments revisionID:[NSUUID UUID]];
  [self.delegate assignmentsManager:self activeAssignmentsDidChange:self.activeAssignments];

  auto data = [NSKeyedArchiver archivedDataWithRootObject:self.activeAssignments];
  [self.storage setObject:data forKey:kStoredActiveAssignmentsKey];
}

- (BOOL)shouldApply:(NSDictionary<NSString *, LABAssignment *> *)assignments {
  return ![self.activeAssignments.assignments isEqual:assignments];
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

- (void)reportAssignmentAffectedUser:(id<LABAssignment>)assignment {
  [self.delegate assignmentsManager:self assignmentDidAffectUser:assignment];
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
