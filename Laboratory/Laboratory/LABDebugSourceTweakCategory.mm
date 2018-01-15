// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSourceTweakCategory.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSDictionary+Functional.h>

#import "LABDebugSource.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

/// An editable tweak for an \c experiment in \c source. The tweak name is the experiment name and
/// its possible values are the variants in \c experiment including "Inactive" which states that the
/// experiment is inactive.
@interface LABDebugSourceExperimentTweak : NSObject <FBEditableTweak>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the underlying \c experiment to expose as tweak, the \c source of the
/// experiment and \c debugSource are used to activate and deactivate variants.
- (instancetype)initWithExperiment:(id<LABDebugExperiment>)experiment source:(NSString *)source
                       debugSource:(LABDebugSource *)debugSource;

/// Source of \c experient.
@property (readonly, nonatomic) NSString *source;

/// Undrlying experiment for this tweak.
@property (readonly, nonatomic) id<LABDebugExperiment> experiment;

/// Used to activate and deactivate variants.
@property (weak, readonly, nonatomic) LABDebugSource *debugSource;

@end

@implementation LABDebugSourceExperimentTweak

@synthesize identifier = _identifier;
@synthesize name = _name;
@synthesize currentValue = _currentValue;
@synthesize defaultValue = _defaultValue;
@synthesize minimumValue = _minimumValue;
@synthesize stepValue = _stepValue;
@synthesize precisionValue = _precisionValue;
@synthesize possibleValues = _possibleValues;
@synthesize maximumValue = _maximumValue;

/// Variant name defining an inactive state of an experiment.
static NSString * const kInactiveVariantName = @"Inactive";

- (instancetype)initWithExperiment:(id<LABDebugExperiment>)experiment source:(NSString *)source
                       debugSource:(LABDebugSource *)debugSource {
  if (self = [super init]) {
    _experiment = experiment;
    _source = source;
    _debugSource = debugSource;

    _identifier = [@[source, experiment.name] componentsJoinedByString:@"."];
    _name = experiment.name;
    _currentValue = experiment.activeVariant.name ?: kInactiveVariantName;

    auto sortedVariants =
        [[experiment.variants allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _possibleValues = [sortedVariants arrayByAddingObject:kInactiveVariantName];
    _defaultValue = kInactiveVariantName;
  }
  return self;
}

- (void)reset {
  self.currentValue = nil;
}

- (void)setCurrentValue:(NSString * _Nullable)currentValue {
  _currentValue = currentValue;

  NSString * _Nullable variant = [currentValue isEqual:kInactiveVariantName] ? nil : currentValue;

  if (!variant) {
    [self.debugSource deactivateExperiment:self.experiment.name ofSource:self.source];
  } else {
    [self.debugSource activateVariant:variant ofExperiment:self.experiment.name
                             ofSource:self.source];
  }
}

@end

@interface LABDebugSourceTweakCategory ()

/// Used to expose experiment tweaks and update active variants.
@property (readonly, nonatomic) LABDebugSource *source;

@end

@implementation LABDebugSourceTweakCategory

@synthesize name = _name;
@synthesize tweakCollections = _tweakCollections;

- (instancetype)initWithDebugSource:(LABDebugSource *)debugSource {
  if (self = [super init]) {
    _name = @"Laboratory Experiments";
    _source = debugSource;
    [self bindCollections];
  }
  return self;
}

- (void)bindCollections {
  @weakify(self)
  RAC(self, tweakCollections) = [RACObserve(self.source, allExperiments)
      map:^NSArray<FBTweakCollection *> *(NSDictionary<NSString *, NSSet<id<LABDebugExperiment>> *>
                                          *allExperiments) {
        @strongify(self)
        if (!self) {
          return @[];
        }

        return [allExperiments lt_mapValues:
                ^FBTweakCollection *(NSString *source, NSSet<id<LABDebugExperiment>> *experiments) {
          auto sortedExperiments = [[experiments allObjects]
                                     sortedArrayUsingComparator:^(id<LABDebugExperiment> obj1,
                                                                  id<LABDebugExperiment> obj2) {
            return [obj1.name compare:obj2.name];
          }];
          auto tweaks = [sortedExperiments lt_map:^id<FBTweak> (id<LABDebugExperiment> experiment) {
            return [[LABDebugSourceExperimentTweak alloc] initWithExperiment:experiment
                                                                      source:source
                                                                 debugSource:self.source];
          }];

          return [[FBTweakCollection alloc] initWithName:source tweaks:tweaks];
        }].allValues;
      }];
}

- (RACSignal *)update {
  return [[[self.source update]
      catch:^RACSignal *(NSError *error) {
        auto wrappedError = [NSError lt_errorWithCode:LABErrorCodeTweaksCollectionsUpdateFailed
                                      underlyingError:error];
        return [RACSignal error:wrappedError];
      }]
      switchToLatest];
}

- (void)reset {
  [self.source resetVariantActivations];
}

@end

NS_ASSUME_NONNULL_END
