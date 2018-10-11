// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABLocalSource.h"

#import <LTKit/LTKeyValuePersistentStorage.h>
#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSSet+Operations.h>

#import "LABExperimentsTokenProvider.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LABLocalVariant ()

/// Subscript access to the \c assignments dictionary.
- (nullable id)objectForKeyedSubscript:(NSString *)key;

@end

@implementation LABLocalVariant

- (instancetype)initWithName:(NSString *)name probabilityWeight:(NSUInteger)probabilityWeight
                 assignments:(NSDictionary<NSString *, id> *)assignments {
  if (self = [super init]) {
    _name = name;
    _probabilityWeight = probabilityWeight;
    _assignments = assignments;
  }
  return self;
}

- (nullable id)objectForKeyedSubscript:(NSString *)key {
  return self.assignments[key];
}

@end

@interface LABLocalExperiment ()

/// Subscript access to the \c variants dictionary.
- (nullable LABLocalVariant *)objectForKeyedSubscript:(NSString *)key;

@end

@implementation LABLocalExperiment

- (instancetype)initWithName:(NSString *)name keys:(NSArray<NSString *> *)keys
                    variants:(NSArray<LABLocalVariant *> *)variants
            activeTokenRange:(LABExperimentsTokenRange)activeTokenRange {
  if (self = [super init]) {
    LTParameterAssert(variants.count > 0, @"Zero variants");
    LTParameterAssert([self verifyVariants:variants haveKeys:keys], @"Variants %@ do not assign "
                      "values for all the given experiment keys %@", variants, keys);
    LTParameterAssert([self verifyNoDuplicateVariantNames:variants], @"Duplicate variant names in "
                      "variants %@", variants);
    LTParameterAssert(activeTokenRange.first <= activeTokenRange.second, @"Range %g:%g is invalid",
                      activeTokenRange.first, activeTokenRange.second);
    LTParameterAssert(activeTokenRange.first <= 1 && activeTokenRange.first >= 0, @"Lower range "
                      "bound %g must be between 0 and 1", activeTokenRange.first);
    LTParameterAssert(activeTokenRange.second <= 1 && activeTokenRange.second >= 0, @"Upper range "
                      "bound %g must be between 0 and 1", activeTokenRange.second);
    LTParameterAssert([self verifyAtLeastOnePositiveWeight:variants], @"Variants %@ does not "
                      "contain at least one variable with positive probability weight", variants);
    _name = name;
    _keys = keys;
    _activeTokenRange = activeTokenRange;
    [self setupVariantsDictionary:variants];
  }
  return self;
}

+ (instancetype)experimentFromEnum:(Class)enumClass withName:(NSString *)name
                  activeTokenRange:(LABExperimentsTokenRange)activeTokenRange {
  LTParameterAssert([enumClass conformsToProtocol:@protocol(LTEnum)], @"Given class %@ doesn't "
                    "conform to the LTEnum protocol", enumClass);

  return [[LABLocalExperiment alloc] initWithName:name keys:@[name]
                                         variants:[self variantsFromEnum:enumClass key:name]
                                 activeTokenRange:activeTokenRange];
}

+ (NSArray<LABLocalVariant *> *)variantsFromEnum:(Class)enumClass key:(NSString *)key {
  return [[enumClass fields] lt_map:^LABLocalVariant *(id<LTEnum> enumObject) {
    return [[LABLocalVariant alloc] initWithName:enumObject.name probabilityWeight:1
                                     assignments:@{key: enumObject.name}];
  }];
}

- (BOOL)verifyVariants:(NSArray<LABLocalVariant *> *)variants haveKeys:(NSArray<NSString *> *)keys {
  auto referenceKeysSet = [keys lt_set];
  for (LABLocalVariant *variant in variants) {
    auto variantKeysSet = [variant.assignments.allKeys lt_set];
    if (![variantKeysSet isEqualToSet:referenceKeysSet]) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)verifyNoDuplicateVariantNames:(NSArray<LABLocalVariant *> *)variants {
  NSArray<NSString *> *variantNames = [variants lt_map:^NSString *(LABLocalVariant *variant) {
    return variant.name;
  }];
  return [variantNames lt_set].count == variantNames.count;
}

- (BOOL)verifyAtLeastOnePositiveWeight:(NSArray<LABLocalVariant *> *)variants {
  return [variants indexOfObjectPassingTest:^BOOL(LABLocalVariant *variant, NSUInteger, BOOL *) {
    return variant.probabilityWeight > 0;
  }] != NSNotFound;
}

- (void)setupVariantsDictionary:(NSArray<LABLocalVariant *> *)variants {
  NSMutableDictionary<NSString *, LABLocalVariant *> *variantsNameToVariants =
      [NSMutableDictionary dictionaryWithCapacity:variants.count];

  for (LABLocalVariant *variant in variants) {
    variantsNameToVariants[variant.name] = variant;
  }
  _variants = variantsNameToVariants;
}

- (nullable id)objectForKeyedSubscript:(NSString *)key {
  return self.variants[key];
}

@end

/// Variant name used by the class to indicate that this experiment is not active. Stored
/// experiments that have this variant are not active.
static auto const kExperimentNotActiveVariantName = @"_inactive";

/// Key for storing the active variants.
static auto const kActiveVariantsStorageKey = @"ActiveVariantsStorageKey";

/// Key for storing the assignments locked state.
static auto const kStoredAssignmentsLockedKey = @"LABLocalSourceAssignmentsLocked";

@interface LABLocalSource ()

/// Maps experiment names to experiment.
@property (readonly, nonatomic) NSDictionary<NSString *, LABLocalExperiment *> *experiments;

/// Used to store the experiments and variants.
@property (readonly, nonatomic) id<LTKeyValuePersistentStorage> storage;

/// Used to decide which experiments are active.
@property (readonly, nonatomic) LABExperimentsToken experimentsToken;

/// Used to choose variants.
@property (readonly, nonatomic) LTRandom *random;

@end

@implementation LABLocalSource

@synthesize activeVariants = _activeVariants;

- (instancetype)initWithExperiments:(NSArray<LABLocalExperiment *> *)experiments
           experimentsTokenProvider:(id<LABExperimentsTokenProvider>)experimentsTokenProvider {
  return [self initWithExperiments:experiments experimentsTokenProvider:experimentsTokenProvider
                           storage:[NSUserDefaults standardUserDefaults]
                            random:[[LTRandom alloc] init]];
}

- (instancetype)initWithExperiments:(NSArray<LABLocalExperiment *> *)experiments
           experimentsTokenProvider:(id<LABExperimentsTokenProvider>)experimentsTokenProvider
                            storage:(id<LTKeyValuePersistentStorage>)storage
                             random:(LTRandom *)random {
  if (self = [super init]) {
    _storage = storage;
    _random = random;
    _experimentsToken = experimentsTokenProvider.experimentsToken;
    [self setupExperiments:experiments];
    [self setupActiveVariants];
  }
  return self;
}

- (void)setupExperiments:(NSArray<LABLocalExperiment *> *)experiments {
  auto experimentsMap = [NSMutableDictionary<NSString *, LABLocalExperiment *>
                         dictionaryWithCapacity:experiments.count];
  for (LABLocalExperiment *experiment in experiments) {
    experimentsMap[experiment.name] = experiment;
  }
  _experiments = experimentsMap;
}

- (void)setupActiveVariants {
  auto activeVariantsNames = [self loadActiveVariantNames];

  NSMutableArray<LABVariant *> *activeVariants =
      [NSMutableArray arrayWithCapacity:activeVariantsNames.count];
  [activeVariantsNames enumerateKeysAndObjectsUsingBlock:^(NSString *experiment, NSString *variant,
                                                           BOOL *) {
    auto variantAssignments = self.experiments[experiment][variant].assignments;
    auto activeVariant = [[LABVariant alloc] initWithName:variant assignments:variantAssignments
                                               experiment:experiment];
    [activeVariants addObject:activeVariant];
  }];
  _activeVariants = [activeVariants lt_set];
}

- (NSDictionary<NSString *, NSString *> *)loadActiveVariantNames {
  auto allExperiments = self.experiments.allKeys;
  auto storedActiveVariants = [[self storedActiveVariants] lt_filter:^BOOL(NSString *experiment,
                                                                           NSString *) {
    return [allExperiments containsObject:experiment];
  }];
  auto newExperiments = [self experimentsWithoutVariants:storedActiveVariants];

  auto activeExperimentsAndVariants =
      [NSMutableDictionary dictionaryWithDictionary:storedActiveVariants];
  for (NSString *experiment in newExperiments) {
    activeExperimentsAndVariants[experiment] = [self selectVariantForExperiment:experiment];
  }

  [self storeExperimentsAndVariants:activeExperimentsAndVariants];

  return [activeExperimentsAndVariants lt_filter:^BOOL(NSString *, NSString *variant) {
        return ![variant isEqual:kExperimentNotActiveVariantName];
      }];
}

- (NSDictionary<NSString *, NSString *> *)storedActiveVariants {
  NSDictionary<NSString *, NSString *> * _Nullable storedVariants =
      [self.storage objectForKey:kActiveVariantsStorageKey];
  if (!storedVariants) {
    return @{};
  }

  if (![storedVariants isKindOfClass:NSDictionary.class]) {
    LogError(@"Expected stored variants to be a of class: %@, got: %@", NSDictionary.class,
             storedVariants.class);
    return @{};
  }

  for (NSString *key in storedVariants) {
    NSString *value = storedVariants[key];
    if (!([key isKindOfClass:NSString.class] && [value isKindOfClass:NSString.class])) {
      return @{};
    }
  }
  return storedVariants;
}

- (NSSet<NSString *> *)experimentsWithoutVariants:
    (NSDictionary<NSString *, NSString *> *)storedExperimentsAndVariants {
  NSMutableSet<NSString *> *experimentsToChooseVariants = [NSMutableSet set];
  for (NSString *experiment in storedExperimentsAndVariants) {
    auto storedActiveVariant = storedExperimentsAndVariants[experiment];
    if ([storedActiveVariant isEqual:kExperimentNotActiveVariantName] ||
        self.experiments[experiment].variants[storedActiveVariant]) {
      continue;
    }

    [experimentsToChooseVariants addObject:experiment];
  }

  auto storedExperiments = [storedExperimentsAndVariants.allKeys lt_set];
  if (![self assignmentsLocked]) {
    auto newExperiments = [[self.experiments.allKeys lt_set] lt_minus:storedExperiments];
    [experimentsToChooseVariants unionSet:newExperiments];
  }
  return experimentsToChooseVariants;
}

- (NSString *)selectVariantForExperiment:(NSString *)experimentName {
  auto _Nullable experiment = self.experiments[experimentName];
  if (![self experimentsTokenIsInRange:experiment.activeTokenRange]) {
    return kExperimentNotActiveVariantName;
  }

  auto variants = experiment.variants.allValues;
  __block std::vector<double> weights(variants.count);

  [variants enumerateObjectsUsingBlock:^(LABLocalVariant *variant, NSUInteger i, BOOL *) {
    weights[i] = variant.probabilityWeight;
  }];

  auto selectedVariantIndex = [self.random randomUnsignedIntegerWithWeights:weights];
  return experiment.variants.allValues[selectedVariantIndex].name;
}

- (BOOL)experimentsTokenIsInRange:(LABExperimentsTokenRange)range {
  return self.experimentsToken > range.first && self.experimentsToken <= range.second;
}

- (void)storeExperimentsAndVariants:(NSDictionary<NSString *, NSString *> *)experimentsAndVariants {
  [self.storage setObject:experimentsAndVariants forKey:kActiveVariantsStorageKey];
}

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

- (void)storeAssignmentsLocked {
  [self.storage setObject:@YES forKey:kStoredAssignmentsLockedKey];
}

#pragma mark -
#pragma mark LABExperimentssSource
#pragma mark -

- (RACSignal *)fetchAllExperimentsAndVariants {
  auto allExperiments = [self.experiments lt_mapValues:^(NSString *,
                                                         LABLocalExperiment *experiment) {
    return [experiment.variants.allKeys lt_set];
  }];

  return [RACSignal return:allExperiments];
}

- (RACSignal *)fetchAssignmentsForExperiment:(NSString *)experiment
                                 withVariant:(NSString *)variant {
  auto _Nullable assignments =
      self.experiments[experiment][variant].assignments;

  if (!assignments) {
    auto error = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                       associatedExperiment:experiment
                          associatedVariant:variant];
    return [RACSignal error:error];
  }
  return [RACSignal return:assignments];
}

- (NSString *)name {
  return @"Local";
}

@end

NS_ASSUME_NONNULL_END
