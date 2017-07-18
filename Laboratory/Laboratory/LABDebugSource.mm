// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSource.h"

#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSDictionary+Functional.h>
#import <LTKit/NSObject+AddToContainer.h>
#import <LTKit/NSSet+Functional.h>

#import "LABStorage.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

/// Debug experiment model, used by the LABDebugSource for holding experiment data.
@interface LABDebugExperimentModel : LTValueObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c name, \c allVariants.
- (instancetype)initWithName:(NSString *)name
                 allVariants:(NSDictionary<NSString *, LABVariant *> *)allVariants
    NS_DESIGNATED_INITIALIZER;

/// Experiment name.
@property (readonly, nonatomic) NSString *name;

/// All variants available for the experiment named \c name.
@property (readonly, nonatomic) NSDictionary<NSString *, LABVariant *> *allVariants;

@end

@implementation LABDebugExperimentModel

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSString * _Nullable name =
      [aDecoder decodeObjectOfClass:[NSString class]
                             forKey:@instanceKeypath(LABDebugExperimentModel, name)];

  NSDictionary * _Nullable allVariants =
      [aDecoder decodeObjectOfClass:[NSDictionary class]
                             forKey:@instanceKeypath(LABDebugExperimentModel, allVariants)];

  if (![name isKindOfClass:NSString.class] ||
      ![allVariants isKindOfClass:NSDictionary.class]) {
    return nil;
  }

  for (NSString *key in allVariants) {
    if (![key isKindOfClass:NSString.class]) {
      return nil;
    }
    if (![allVariants[key] isKindOfClass:LABVariant.class]) {
      return nil;
    }
  }

  return [self initWithName:name allVariants:allVariants];
}

- (instancetype)initWithName:(NSString *)name
                 allVariants:(NSDictionary<NSString *, LABVariant *> *)allVariants {
  if (self = [super init]) {
    _name = name;
    _allVariants = allVariants;
  }

  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:@instanceKeypath(LABDebugExperimentModel, name)];
  [aCoder encodeObject:self.allVariants
                forKey:@instanceKeypath(LABDebugExperimentModel, allVariants)];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

/// Default implementation of \c LABDebugExperiment protocol.
@interface LABDebugExperiment : LTValueObject <LABDebugExperiment>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c model.
- (instancetype)initWithExperimentModel:(LABDebugExperimentModel *)model;

/// Initializes with the given \c model and \c activeVariant.
- (instancetype)initWithExperimentModel:(LABDebugExperimentModel *)model
                          activeVariant:(nullable NSString *)activeVariant
    NS_DESIGNATED_INITIALIZER;

/// Model of the underlying experiment.
@property (readonly, nonatomic) LABDebugExperimentModel *experimentModel;

@end

@implementation LABDebugExperiment

@synthesize activeVariant = _activeVariant;

- (instancetype)initWithExperimentModel:(LABDebugExperimentModel *)model {
  return [self initWithExperimentModel:model activeVariant:nil];
}

- (instancetype)initWithExperimentModel:(LABDebugExperimentModel *)model
                          activeVariant:(nullable NSString *)activeVariant {
  if (self = [super init]) {
    _experimentModel = model;
    _activeVariant = model.allVariants[activeVariant];
  }

  return self;
}

- (NSString *)name {
  return self.experimentModel.name;
}

- (NSSet<NSString *> *)variants {
  return [self.experimentModel.allVariants.allKeys lt_set];
}

- (BOOL)isActive {
  return self.activeVariant != nil;
}

@end

/// Defines a mapping between experiment names to debug experiment models.
typedef NSDictionary<NSString *, LABDebugExperimentModel *> LABExperimentMapping;

/// Defines a mapping between assignments sorce names and their active experiments as tuples of
/// experiment name and variant name.
typedef NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> LABSourceActiveExperiments;

@interface LABDebugSource ()

/// Multiplexed sources. Maps between a source name to a \c LABExperimentsSource with the same
/// \c name.
@property (readonly, nonatomic) NSDictionary<NSString *, id<LABExperimentsSource>> *sources;

/// All available experiments.
@property (readonly, nonatomic) NSDictionary<NSString *, LABExperimentMapping *> *
    allExperimentModels;

/// Used to persist the experiments model.
@property (readonly, nonatomic) id<LABStorage> storage;

/// Used for internally passing updated debug experiments models.
@property (readonly, nonatomic) RACSubject *updatesSubject;

/// Used for internally passing a variant to activate. Sends a \c RACTuple of three strings -
/// variant, experiment and source. If sends \c nil then all activations should be reset.
@property (readonly, nonatomic) RACSubject *variantActivationSubject;

/// Used for internally reseting \c variantActivationRequests. Sends \c RACUnit when a reset is
/// requested.
@property (readonly, nonatomic) RACSubject *variantResetSubject;

/// Used for the update operation to avoid a race that may be caused by a \c switchToLatest and the
/// async data fetch of the signal.
@property (readonly, nonatomic) RACScheduler *updateScheduler;

@end

@implementation LABDebugSource

/// Key for a stored \c NSDictionary of all sources and their experiments.
static NSString * const kLABStorageAllDebugExperimentsKey = @"LABAllDebugExperiments";

/// Key for a stored \c NSDictionary of all sources and their active experiments.
static NSString * const kLABStorageAllDebugActiveExperimentsKey = @"LABAllDebugActiveExperiments";

@synthesize activeVariants = _activeVariants;
@synthesize allExperiments = _allExperiments;

- (instancetype)initWithSources:(NSArray<id<LABExperimentsSource>> *)sources {
  return [self initWithSources:sources storage:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithSources:(NSArray<id<LABExperimentsSource>> *)sources
                        storage:(id<LABStorage>)storage {
  if (self = [super init]) {
    _storage = storage;
    _updatesSubject = [RACSubject subject];
    _variantActivationSubject = [RACSubject subject];
    _updateScheduler = [RACScheduler scheduler];
    [self setupSources:sources];
    [self bindActiveVariants];
  }
  return self;
}

- (void)setupSources:(NSArray<id<LABExperimentsSource>> *)sources {
  NSArray<NSString *> *names = [sources valueForKey:@instanceKeypath(LABDebugSource, name)];
  _sources = [NSDictionary dictionaryWithObjects:sources forKeys:names];
}

- (void)bindActiveVariants {
  @weakify(self)
  RAC(self, allExperimentModels) = [[self.updatesSubject
      doNext:^(NSDictionary<NSString *, LABExperimentMapping *> *allExperimentModels) {
        @strongify(self)
        [self.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:allExperimentModels]
                         forKey:kLABStorageAllDebugExperimentsKey];
      }]
      startWith:[[self loadStoredExperiments] lt_filter:^BOOL(NSString *key,
                                                              LABExperimentMapping *) {
        return self.sources[key] != nil;
      }]];

  RAC(self, variantActivationRequests) = [[[self.variantActivationSubject
       scanWithStart:[self loadActiveExperiments]
       reduce:^NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *
              (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *running,
               RACTuple * _Nullable request) {
         if (!request) {
           return @{};
         }
         NSMutableDictionary *result = [running mutableCopy];
         NSMutableDictionary *sourceActiveExperiments = [running[request.third] ?: @{} mutableCopy];
         sourceActiveExperiments[request.second] = request.first;
         result[request.third] =
             sourceActiveExperiments.count ? [sourceActiveExperiments copy] : nil;
         return [result copy];
       }]
       doNext:^(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *active) {
         @strongify(self)
         [self.storage setObject:active forKey:kLABStorageAllDebugActiveExperimentsKey];
       }]
       startWith:[self loadActiveExperiments]];

  RAC(self, allExperiments) = [[RACSignal
      combineLatest:@[
        RACObserve(self, allExperimentModels),
        RACObserve(self, variantActivationRequests)
      ]]
      map:^NSDictionary<NSString *, NSSet<LABDebugExperiment *> *> *(RACTuple *values) {
        return [values.first lt_mapValues:^(NSString *source, LABExperimentMapping *experiments) {
          return [[[experiments lt_mapValues:^(NSString *experiment,
                                               LABDebugExperimentModel *model) {
            NSString * _Nullable activeVariant = values.second[source][experiment];
            return [[LABDebugExperiment alloc] initWithExperimentModel:model
                                                         activeVariant:activeVariant];
          }] allValues] lt_set];
        }];
      }];

  RAC(self, activeVariants) = [RACObserve(self, allExperiments)
      map:^NSSet<LABVariant *> *(NSDictionary<NSString *, NSSet<LABDebugExperiment *> *> *
                                 allExperiments) {
        auto activeVariants = [NSMutableSet set];
        for (NSSet<LABDebugExperiment *> *experiments in allExperiments.allValues) {
          for (LABDebugExperiment *experiment in experiments) {
            [experiment.activeVariant addToSet:activeVariants];
          }
        }
        return [activeVariants copy];
      }];
}

- (NSDictionary<NSString *, LABExperimentMapping *> *)loadStoredExperiments {
  NSData * _Nullable storedData = [self.storage objectForKey:kLABStorageAllDebugExperimentsKey];
  if (![storedData isKindOfClass:NSData.class]) {
    return @{};
  }

  NSError *error;
  NSDictionary * _Nullable storedExperiments =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:storedData error:&error];

  if (!storedExperiments) {
    LogError(@"Failed to load model from key %@, error: %@", kLABStorageAllDebugExperimentsKey,
             error);
    return @{};
  }

  if (![storedExperiments isKindOfClass:NSDictionary.class]) {
    LogError(@"Expected stored model to be of type: %@, got: %@", NSDictionary.class,
             [storedExperiments class]);
    return @{};
  }

  if (![self areExperimentsValid:storedExperiments]) {
    return @{};
  }

  return storedExperiments;
}

- (BOOL)areExperimentsValid:(NSDictionary *)experiments {
  __block BOOL isValid = YES;

  [experiments enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, LABExperimentMapping *experiments, BOOL *stop) {
      if (![key isKindOfClass:NSString.class] || ![experiments isKindOfClass:NSDictionary.class]) {
        isValid = NO;
        *stop = YES;
        return;
      }

      [experiments enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                       LABDebugExperimentModel *experiment,
                                                       BOOL *internalStop) {
        if (![key isKindOfClass:NSString.class] ||
            ![experiment isKindOfClass:LABDebugExperimentModel.class]) {
          isValid = NO;
          *internalStop = YES;
          *stop = YES;
        }
      }];
  }];

  return isValid;
}

- (LABSourceActiveExperiments *)loadActiveExperiments {
  LABSourceActiveExperiments * _Nullable activeExperiments =
      [self.storage objectForKey:kLABStorageAllDebugActiveExperimentsKey];
  return [self areActiveExperimentsValid:activeExperiments] ? activeExperiments : @{};
}

- (BOOL)areActiveExperimentsValid:(nullable LABSourceActiveExperiments *)activeExperiments {
  if (!activeExperiments) {
    return NO;
  }

  __block BOOL isValid = YES;

  [activeExperiments enumerateKeysAndObjectsUsingBlock:
   ^(NSString *key, NSDictionary *experiments, BOOL *stop) {
     if (![key isKindOfClass:NSString.class] || ![experiments isKindOfClass:NSDictionary.class]) {
       isValid = NO;
       *stop = YES;
       return;
     }

     [experiments
      enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                          NSDictionary<NSString *, NSString *> *experiment,
                                          BOOL *internalStop) {
       if (![key isKindOfClass:NSString.class] ||
           ![experiment isKindOfClass:NSString.class]) {
         isValid = NO;
         *internalStop = YES;
         *stop = YES;
       }
     }];
   }];

  return isValid;
}

#pragma mark -
#pragma mark LABAssignmentsSource
#pragma mark -

- (RACSignal *)update {
  auto allUpdateSignals = [self.sources.allValues lt_map:^(id<LABExperimentsSource> source) {
    return [[self fetchAllExperimentsForSource:source] take:1];
  }];

  @weakify(self)
  return [[[[[[RACSignal
      combineLatest:allUpdateSignals]
      map:^NSDictionary<NSString *, LABExperimentMapping *> *(RACTuple *tuple) {
        auto allMappedExperiments = [NSMutableDictionary dictionary];
        for (RACTuple *sourceAndExperiments in tuple) {
          allMappedExperiments[sourceAndExperiments.first] = sourceAndExperiments.second;
        }
        return [allMappedExperiments copy];
      }]
      doNext:^(NSDictionary<NSString *, LABExperimentMapping *> *allMappedExperiments) {
        @strongify(self)
        [self.updatesSubject sendNext:allMappedExperiments];
      }]
      ignoreValues]
      catch:^RACSignal *(NSError *error) {
        return [RACSignal error:[NSError lt_errorWithCode:LABErrorCodeSourceUpdateFailed
                                          underlyingError:error]];
      }]
      replay];
}

- (RACSignal *)fetchAllExperimentsForSource:(id<LABExperimentsSource>)source {
  // The signal returned sends values on an arbitrary scheduler to handle a race condition that may
  // occure internally because of the last \c switchToLatest call.
  // @see https://github.com/ReactiveCocoa/ReactiveCocoa/issues/2781
  @weakify(self)
  return [[[[source fetchAllExperimentsAndVariants]
      map:^RACSignal *(NSDictionary<NSString *, NSSet<NSString *> *> *experiments) {
        // Create an array of signals that return an \c LABDebugExperiment for each experiment while
        // preserving the selected variant for existing experiments.
        if (!experiments.count) {
          return [RACSignal return:RACTuplePack(source.name, @{})];
        }
        auto experimentSignals =
            [experiments lt_mapValues:^(NSString *experiment, NSSet<NSString *> *variants) {
              // Create an array of signals that return an \c LABVariant for each variants in
              // \c variants.
              auto variantSignals = [[variants allObjects] lt_map:^(NSString *variant) {
                return [[source fetchAssignmentsForExperiment:experiment withVariant:variant]
                    map:^LABVariant *(NSDictionary<NSString *, id> *assignments) {
                      return [[LABVariant alloc] initWithName:variant assignments:assignments
                                                   experiment:experiment];
                    }];
              }];

              // Combine \c variantSignal to create one \c LABDebugExperiment.
              return [[RACSignal combineLatest:variantSignals]
                  map:^LABDebugExperimentModel *(RACTuple *variants) {
                    auto allVariants = [NSMutableDictionary dictionary];
                    for (LABVariant *variant in variants) {
                      allVariants[variant.name] = variant;
                    }
                    return [[LABDebugExperimentModel alloc]
                            initWithName:experiment allVariants:allVariants];
                  }];
            }];

        @strongify(self)
        return [[[RACSignal
            combineLatest:experimentSignals.allValues]
            map:^RACTuple *(RACTuple *values) {
              auto experiments = [NSMutableDictionary dictionary];
              for (LABDebugExperiment *experiment in values) {
                experiments[experiment.name] = experiment;
              }
              return RACTuplePack(source.name, [experiments copy]);
            }]
            deliverOn:self.updateScheduler];
      }]
      deliverOn:self.updateScheduler]
      switchToLatest];
}

- (NSString *)name {
  return @"Debug";
}

#pragma mark -
#pragma mark LABDebugSource
#pragma mark -

- (RACSignal *)activateVariant:(NSString *)variant ofExperiment:(NSString *)experiment
                      ofSource:(NSString *)source {
  [self.variantActivationSubject sendNext:RACTuplePack(variant, experiment, source)];
  auto completionTrigger = [[RACObserve(self, variantActivationRequests)
      filter:^BOOL(NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *value) {
        return ![value[source][experiment] isEqual:variant];
      }]
      mapReplace:[RACUnit defaultUnit]];

  return [[[[RACObserve(self, allExperiments)
      map:^NSNumber *(NSDictionary<NSString *, NSSet<id<LABDebugExperiment>> *> *allExperiments) {
        auto models =
            [allExperiments[source] lt_filter:^BOOL(id<LABDebugExperiment> model) {
              return [model.name isEqual:experiment] && [model.activeVariant.name isEqual:variant];
            }];
        return @(models.count > 0);
      }]
      distinctUntilChanged]
      takeUntil:completionTrigger]
      replay];
}

- (void)deactivateExperiment:(NSString *)experiment ofSource:(NSString *)source {
  [self.variantActivationSubject sendNext:RACTuplePack(nil, experiment, source)];
}

- (void)resetVariantActivations {
  [self.variantActivationSubject sendNext:nil];
}

@end

NS_ASSUME_NONNULL_END
