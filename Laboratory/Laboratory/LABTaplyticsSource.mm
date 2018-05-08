// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABTaplyticsSource.h"

#import <LTKit/LTKeyValuePersistentStorage.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSSet+Functional.h>
#import <Taplytics/Taplytics.h>

#import "LABExperimentsTokenProvider.h"
#import "LABTaplytics.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

/// Returns an activated \c taplytics object with an \c apiKey, \c customData, a timeout of 60
/// seconds and disabling the splash screen stall, shake menu, Taplytics borders UI for debug mode.
static id<LABTaplytics> kLABStartTaplytics(id<LABTaplytics> taplytics, NSString *apiKey,
                                           NSDictionary<NSString *, id> *customData) {
  [taplytics setUserAttributes:@{
    // As documented in the Taplytics SDK, setting the "customData" key, will send these keys to
    // Taplytics for advanced experiments filtering.
    @"customData": customData
  }];
  [taplytics startTaplyticsWithAPIKey:apiKey options:@{
    // Do not show splash screen.
    TaplyticsOptionShowLaunchImage: @NO,
    // Disable shake menu.
    TaplyticsOptionShowShakeMenu: @NO,
    // Disables intrusive error indicators in debug mode.
    TaplyticsOptionDisableBorders: @YES,
    // Specifies the number of seconds to display the splash screen. Also specify the timeout value
    // for network requests.
    TaplyticsOptionDelayLoad: @60
  }];
  return taplytics;
}

/// Prefix for every meta key.
static auto const kMetaKeyPrefix = @"__";

/// Prefix for meta key containing a list of keys for experiments.
static auto const kExperimentKeysMetaKeyPrefix = @"__Keys_";

/// Prefix for meta key contains a list of keys to override to stored data.
static auto const kOverrideMetaKeyPrefix = @"__Override_";

/// Key for storing the assignments locked state.
static auto const kStoredAssignmentsLockedKey = @"LABTaplyticsSourceAssignmentsLocked";

/// Key for storing the latest variants.
static auto const kStoredVariantsKey = @"LABTaplyticsSourceVariants";

/// Prefix for a Taplytics defined experiment or variable that is used as a remote configuration.
static auto const kRemoteConfigurationExperimentPrefix = @"__Remote_";

/// Prefix for a Taplytics defined experiment that should be exposed for existing users, overriding
/// the lock once.
static auto const kExperimentForExistingUsersPrefix = @"ExistingUsers";

/// Custom data key for experiments token.
NSString * const kLABCustomDataExperimentsTokenKey = @"ExperimentsToken";

@interface LABTaplyticsSource ()

/// Used to store the latest assignments.
@property (readonly, nonatomic) id<LTKeyValuePersistentStorage> storage;

/// \c YES if the assignments are locked and should not be changed, except when an experiment no
/// longer exists, or keys are overriden using meta keys.
@property (readonly, nonatomic) BOOL assignmentsLocked;

/// Meta assignments are assignments that are for internal use and not for the public
/// interface to expose, for example, overriding locked assignments and mapping assignments to
/// experiments. \c nil if \c taplytics didn't fetch the data.
@property (readwrite, nonatomic, nullable) NSDictionary<NSString *, id> *activeMetaAssignments;

@end

@implementation LABTaplyticsSource

@synthesize activeVariants = _activeVariants;

- (instancetype)initWithAPIKey:(NSString *)apiKey
      experimentsTokenProvider:(LABExperimentsTokenProvider *)experimentsTokenProvider
                    customData:(NSDictionary<NSString *, id> *)customData {
  return [self initWithAPIKey:apiKey experimentsTokenProvider:experimentsTokenProvider
                   customData:customData taplytics:[[LABTaplytics alloc] init]
                      storage:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
      experimentsTokenProvider:(LABExperimentsTokenProvider *)experimentsTokenProvider
                    customData:(NSDictionary<NSString *, id> *)customData
                     taplytics:(id<LABTaplytics>)taplytics
                       storage:(id<LTKeyValuePersistentStorage>)storage {
  if (self = [super init]) {
    _storage = storage;

    NSMutableDictionary<NSString *, id> *augmentedCustomData = [customData mutableCopy];
    augmentedCustomData[kLABCustomDataExperimentsTokenKey] =
        @(experimentsTokenProvider.experimentsToken);
    _taplytics = kLABStartTaplytics(taplytics, apiKey, [augmentedCustomData copy]);
    [self bindProperties];
  }
  return self;
}

- (void)bindProperties {
  @weakify(self);
  RAC(self, activeVariants) = [[[RACObserve(self.taplytics, properties)
    ignore:nil]
    map:^NSSet<LABVariant *> *(id<LABTaplyticsProperties> properties) {
      @strongify(self);
      auto latestVariants = [self variantsFromTaplyticsProperties:properties];

      if (!self.assignmentsLocked) {
        return latestVariants;
      }

      auto activeVariants = [[self loadVariants] lt_filter:^BOOL(LABVariant *variant) {
        return (properties.allExperimentsToVariations[variant.experiment] != nil);
      }];

      auto overridenKeys = [self overridenKeysFromTaplyticsProperties:properties];
      auto variants = [self overrideVariantsKeys:overridenKeys inVariants:activeVariants
                               fromLatestVariant:latestVariants];
      auto allActiveExperiments = [variants lt_map:^NSString *(LABVariant *variant) {
        return variant.experiment;
      }];
      auto newVariantForExistingUsers = [latestVariants lt_filter:^BOOL(LABVariant *variant) {
        return [variant.experiment hasPrefix:kExperimentForExistingUsersPrefix] &&
            ![allActiveExperiments containsObject:variant.experiment];
      }];

      return [variants setByAddingObjectsFromSet:newVariantForExistingUsers];
    }]
    doNext:^(NSSet<LABVariant *> *variants) {
      @strongify(self);
      [self storeVariants:variants];
    }];
}

- (NSSet<LABVariant *> *)variantsFromTaplyticsProperties:(id<LABTaplyticsProperties>)properties {
  auto metaAssignments = [self metaAssignmentsFromVariables:properties.activeDynamicVariables];

  // Maps each experiment to the values of the meta assignment with the given prefix.
  auto experimentsToKeys = [self extractExperimentsInformationFrom:metaAssignments
                                                         keyPrefix:kExperimentKeysMetaKeyPrefix];
  auto variants = [NSMutableSet set];
  auto nonRemoteConfigurationExperimentsToVariations =
      [properties.activeExperimentsToVariations lt_filter:^BOOL(NSString *experiment, NSString *) {
        return ![experiment hasPrefix:kRemoteConfigurationExperimentPrefix];
      }];

  [nonRemoteConfigurationExperimentsToVariations
      enumerateKeysAndObjectsUsingBlock:^(NSString *experimentName, NSString *variantName, BOOL *) {
    auto _Nullable experimentKeys = experimentsToKeys[experimentName];
    if (!experimentKeys) {
      LogError(@"Experiment %@ does not have meta assignment for its keys", experimentName);
      return;
    }

    auto _Nullable assignments = [self extractAssignmentsKeys:experimentKeys
                                         fromDynamicVariables:properties.activeDynamicVariables];
    if (!assignments) {
      LogError(@"Experiment %@ has misconfigured keys %@", experimentName, experimentKeys);
      return;
    }

    auto variant = [[LABVariant alloc] initWithName:variantName assignments:assignments
                                         experiment:experimentName];
    [variants addObject:variant];
  }];
  return variants;
}

- (NSDictionary<NSString *, id> *)metaAssignmentsFromVariables:
    (NSDictionary<NSString *, id> *)dynamicVariables {
  return [dynamicVariables lt_filter:^BOOL(NSString *key, id) {
    return [self isKeyMetaAssignment:key];
  }];
}

- (BOOL)isKeyMetaAssignment:(NSString *)assignmentKey {
  return [assignmentKey hasPrefix:kMetaKeyPrefix];
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)extractExperimentsInformationFrom:
    (NSDictionary<NSString *, id> *)metaAssignments keyPrefix:(NSString *)prefix {
  auto experimentsToKeys = [NSMutableDictionary dictionary];
  for (NSString *metaKey in metaAssignments.allKeys) {
    auto _Nullable experiment = [self experimentFromMetaAssignmentKey:metaKey prefix:prefix];
    if (!experiment) {
      continue;
    }
    id metaValue = metaAssignments[metaKey];
    auto _Nullable experimentKeys = [self assignmentKeysFromMetaAssignmentValue:metaValue];
    if (!experimentKeys) {
      LogError(@"Value for meta assignment %@ contain invalid data %@", metaKey, metaValue);
    }
    experimentsToKeys[experiment] = experimentKeys;
  }
  return experimentsToKeys;
}

- (nullable NSString *)experimentFromMetaAssignmentKey:(NSString *)metaAssignmentKey
                                                prefix:(NSString *)prefix {
  if (![metaAssignmentKey hasPrefix:prefix]) {
    return nil;
  }
  return [metaAssignmentKey substringFromIndex:prefix.length];
}

- (nullable NSArray<NSString *> *)assignmentKeysFromMetaAssignmentValue:(id)value {
  if (![value isKindOfClass:NSString.class]) {
    LogError(@"Meta assignments value %@ is not a string", value);
    return nil;
  }

  auto data = [value dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error;
  NSArray<NSString *> * _Nullable keys = [NSJSONSerialization JSONObjectWithData:data options:0
                                                                           error:&error];
  if (error) {
    LogError(@"Meta assignments value %@ conversion from JSON failed with error %@", value, error);
    return nil;
  }
  if (![keys isKindOfClass:NSArray.class]) {
    LogError(@"Meta assignments value %@ is not a JSON array", value);
    return nil;
  }
  for (id key in keys) {
    if (![key isKindOfClass:NSString.class]) {
      LogError(@"Meta assignments value %@ contains non-string values", value);
      return nil;
    }
  }

  return keys;
}

- (nullable NSDictionary<NSString *, id> *)
    extractAssignmentsKeys:(NSArray<NSString *> *)assignmentsKeys
    fromDynamicVariables:(NSDictionary<NSString *, id> *)dynamicVariables {
  auto assignmentsForVariant = [NSMutableDictionary dictionary];
  for (NSString *key in assignmentsKeys) {
    id _Nullable assignment = dynamicVariables[key];
    if (!assignment) {
      LogError(@"Key %@ given in meta assignment doesn't exist", key);
      return nil;
    }
    assignmentsForVariant[key] = assignment;
  }

  return assignmentsForVariant;
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)
    overridenKeysFromTaplyticsProperties:(id<LABTaplyticsProperties>)properties {
  auto metaAssignments = [self metaAssignmentsFromVariables:properties.activeDynamicVariables];

  return [self extractExperimentsInformationFrom:metaAssignments keyPrefix:kOverrideMetaKeyPrefix];
}

- (NSSet<LABVariant *> *)overrideVariantsKeys:
    (NSDictionary<NSString *, NSArray<NSString *> *> *)overrideKeys
                                   inVariants:(NSSet<LABVariant *> *)variants
                            fromLatestVariant:(NSSet<LABVariant *> *)latestVariants {
  auto experimentToLatestVariant = [NSMutableDictionary dictionary];
  [latestVariants enumerateObjectsUsingBlock:^(LABVariant *variant, BOOL *) {
    experimentToLatestVariant[variant.experiment] = variant;
  }];
  return [variants lt_map:^LABVariant *(LABVariant *variant) {
    return [self overrideVariantKeys:overrideKeys[variant.experiment]
                           inVariant:variant
                   fromLatestVariant:experimentToLatestVariant[variant.experiment]];
  }];
}

- (LABVariant *)overrideVariantKeys:(nullable NSArray<NSString *> *)keys
                          inVariant:(LABVariant *)variant
                  fromLatestVariant:(LABVariant *)latestVariant {
  if (!keys.count) {
    return variant;
  }

  NSMutableDictionary *updatedAssignemnts = [variant.assignments mutableCopy];
  for (NSString *overridenKey in keys) {
    if (latestVariant.assignments[overridenKey]) {
      updatedAssignemnts[overridenKey] = latestVariant.assignments[overridenKey];
    }
  }
  return [[LABVariant alloc] initWithName:variant.name assignments:updatedAssignemnts
                               experiment:variant.experiment];
}

- (NSSet<LABVariant *> *)loadVariants {
  NSData * _Nullable storedVariantsData = [self.storage objectForKey:kStoredVariantsKey];
  if (![storedVariantsData isKindOfClass:NSData.class]) {
    return [NSSet set];
  }

  NSError *error;
  NSSet<LABVariant *> * _Nullable storedVariants =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:storedVariantsData error:&error];

  if (!storedVariants) {
    LogError(@"Failed to load model from key %@, error: %@", storedVariantsData, error);
    return [NSSet set];
  }

  if (![storedVariants isKindOfClass:NSSet.class]) {
    LogError(@"Expected stored model to be of type: %@, got: %@", NSSet.class,
             [storedVariants class]);
    return [NSSet set];
  }

  for (LABVariant *variant in storedVariants) {
    if (![variant isKindOfClass:LABVariant.class]) {
      LogError(@"Expected array value to be of type %@, got: %@", LABVariant.class,
               [variant class]);
    }
  }

  return storedVariants;
}

- (void)storeVariants:(NSSet<LABVariant *> *)variants {
  [self.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:variants]
                   forKey:kStoredVariantsKey];
}

- (void)storeAssignmentsLocked {
  [self.storage setObject:@YES forKey:kStoredAssignmentsLockedKey];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (BOOL)assignmentsLocked {
  return [[self loadAssignmentsLocked] boolValue];
}

- (nullable NSNumber *)loadAssignmentsLocked {
  NSNumber * _Nullable object = [self.storage objectForKey:kStoredAssignmentsLockedKey];
  if ([object isKindOfClass:NSNumber.class]) {
    return object;
  }
  return nil;
}

#pragma mark -
#pragma mark LABAssignmentsSource
#pragma mark -

- (void)stabilizeUserExperienceAssignments {
  [self storeAssignmentsLocked];
}

- (RACSignal *)update {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.taplytics performLoadPropertiesFromServer:^(BOOL success) {
      if (success) {
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:[NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed]];
      }
    }];
    return nil;
  }] replayLast];
}

- (RACSignal *)updateInBackground {
  @weakify(self)
  return [[RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.taplytics refreshPropertiesInBackground:^(UIBackgroundFetchResult result) {
      [subscriber sendNext:[NSNumber numberWithUnsignedInteger:result]];
      [subscriber sendCompleted];
    }];
    return nil;
  }] replayLast];
}

- (NSString *)name {
  return @"Taplytics";
}

#pragma mark -
#pragma mark LABExperimentsSource
#pragma mark -

- (RACSignal *)fetchAllExperimentsAndVariants {
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.taplytics fetchPropertiesWithCompletion:^(id<LABTaplyticsProperties> _Nullable properties,
                                                    NSError * _Nullable error) {
      if (error || !properties) {
        [subscriber sendError:error];
        return;
      }

     auto nonRemoteConfigurationExperimentsToVariations =
          [properties.allExperimentsToVariations lt_filter:^BOOL(NSString *experiment, NSString *) {
            return ![experiment hasPrefix:kRemoteConfigurationExperimentPrefix];
          }];
      [subscriber sendNext:nonRemoteConfigurationExperimentsToVariations];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant {
  @weakify(self)
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    @strongify(self);
    [self.taplytics fetchPropertiesForExperiment:experiment withVariation:variant
                                      completion:^(id<LABTaplyticsProperties> _Nullable properties,
                                                   NSError * _Nullable error) {
      if (error) {
       [subscriber sendError:error];
       return;
      }
      auto variants = [[self variantsFromTaplyticsProperties:properties]
          lt_filter:^BOOL(LABVariant *var) {
            return ([var.experiment isEqual:experiment] && [var.name isEqual:variant]);
          }];
      if (!variants.count) {
        auto error = [NSError lab_errorWithCode:LABErrorCodeMisconfiguredExperiment
                          associatedExperiment:experiment];
        [subscriber sendError:error];
        return;
      }

      // \c variants contains only one value, so it's OK to use \c anyObject to access that value.
      [subscriber sendNext:[variants anyObject].assignments];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}
@end

NS_ASSUME_NONNULL_END
