// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABDebugSourceTweakCollectionsProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSDictionary+Functional.h>

#import "LABDebugSource.h"
#import "NSError+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LABDebugSourceTweakCollectionsProvider () <FBTweakObserver>

/// Used to expose experiment tweaks and update active variants.
@property (readonly, nonatomic) LABDebugSource *source;

@end

@implementation LABDebugSourceTweakCollectionsProvider

/// Variant name defining an inactive state of an experiment.
static NSString * const kInactiveVariantName = @"Inactive";

@synthesize collections = _collections;

- (instancetype)initWithDebugSource:(LABDebugSource *)debugSource {
  if (self = [super init]) {
    _source = debugSource;
    [self bindCollections];
  }
  return self;
}

- (void)bindCollections {
  @weakify(self)
  RAC(self, collections) = [[RACObserve(self.source, allExperiments)
      map:^NSArray<FBTweakCollection *> *(NSDictionary<NSString *, NSSet<id<LABDebugExperiment>> *>
                                          *allExperiments) {
        @strongify(self)
        if (!self) {
          return @[];
        }

        auto collections = [NSMutableArray array];
        [allExperiments
         enumerateKeysAndObjectsUsingBlock:^(NSString *source,
                                             NSSet<id<LABDebugExperiment>> *experiments, BOOL *) {
          auto collection = [[FBTweakCollection alloc] initWithName:source];
          auto sortedExperiments =
              [[experiments allObjects] sortedArrayUsingComparator:^(id<LABDebugExperiment> obj1,
                                                                     id<LABDebugExperiment> obj2) {
                return [obj1.name compare:obj2.name];
              }];
          for (id<LABDebugExperiment> experiment in sortedExperiments) {
            auto tweak = [self tweakForExperiment:experiment ofSource:source];
            [collection addTweak:tweak];
          }
          [collections addObject:collection];
        }];

        return collections;
      }]
      doNext:^(NSArray<FBTweakCollection *> *collections) {
        @strongify(self)
        if (!self) {
          return;
        }

        for (FBTweakCollection *collection in collections) {
          for (FBTweak *tweak in collection.tweaks) {
            [tweak addObserver:self];
          }
        }
      }];
}

- (FBTweak *)tweakForExperiment:(id<LABDebugExperiment>)experiment ofSource:(NSString *)source {
  auto identifier = [@[source, experiment.name] componentsJoinedByString:@"."];
  auto tweak = [[FBTweak alloc] initWithIdentifier:identifier];
  tweak.name = experiment.name;
  tweak.currentValue = experiment.activeVariant.name ?: kInactiveVariantName;

  auto sortedVariants =
    [[experiment.variants allObjects] sortedArrayUsingSelector:@selector(compare:)];
  tweak.possibleValues = [sortedVariants arrayByAddingObject:kInactiveVariantName];

  return tweak;
}

- (void)tweakDidChange:(FBTweak *)tweak {
  auto collections = self.collections;
  auto _Nullable collection = [collections lt_find:^BOOL(FBTweakCollection *collection) {
    return [collection tweakWithIdentifier:tweak.identifier] != nil;
  }];

  if (!collection) {
    LogError(@"Tweak with identifier %@ does not exist in any collection of collections %@",
             tweak.identifier, collections);
    return;
  }

  NSString * _Nullable variant = [tweak.currentValue isEqual:kInactiveVariantName] ? nil :
      tweak.currentValue;

  if (!variant) {
    [self.source deactivateExperiment:tweak.name ofSource:collection.name];
  } else {
    [self.source activateVariant:variant ofExperiment:tweak.name ofSource:collection.name];
  }
}

- (RACSignal *)updateCollections {
  return [[[[self.source update]
      catch:^RACSignal *(NSError *error) {
        auto wrappedError = [NSError lt_errorWithCode:LABErrorCodeTweaksCollectionsUpdateFailed
                                      underlyingError:error];
        return [RACSignal error:wrappedError];
      }]
      switchToLatest]
      deliverOnMainThread];
}

- (void)resetTweaks {
  [self.source resetVariantActivations];
}

@end

NS_ASSUME_NONNULL_END
