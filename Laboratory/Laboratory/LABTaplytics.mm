// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABTaplytics.h"

#import <Taplytics/Taplytics.h>

#import "NSError+Laboratory.h"
#import "TLManager.h"
#import "TLProperties+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

/// Default implementation for the \c LABTaplyticsProperties protocol.
@interface LABTaplyticsProperties : NSObject <LABTaplyticsProperties>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c taplyticsProperites.
- (instancetype)initWithInnerTaplyticsProperites:(TLProperties *)taplyticsProperites
    NS_DESIGNATED_INITIALIZER;

@end

@implementation LABTaplyticsProperties

@synthesize activeExperimentsToVariations = _activeExperimentsToVariations;
@synthesize activeDynamicVariables = _activeDynamicVariables;
@synthesize allExperimentsToVariations = _allExperimentsToVariations;

- (instancetype)initWithInnerTaplyticsProperites:(TLProperties *)taplyticsProperites {
  if (self = [super init]) {
    _activeExperimentsToVariations = taplyticsProperites.lab_runningExperimentsAndVariations;
    _activeDynamicVariables = taplyticsProperites.lab_dynamicVariables;
    _allExperimentsToVariations = taplyticsProperites.lab_allExperimentsAndVariations;
  }
  return self;
}

@end

@interface LABTaplytics ()

/// Internal Taplytics object used to access internal data structures.
@property (readonly, nonatomic) TLManager *tlManager;

@end

@implementation LABTaplytics

@synthesize properties = _properties;

- (instancetype)init {
  return [self initWithTLManager:[TLManager sharedManager]];
}

- (instancetype)initWithTLManager:(TLManager *)tlManager {
  if (self = [super init]) {
    _tlManager = tlManager;
    [self bindProperties];
  }
  return self;
}

- (void)bindProperties {
  RAC(self, properties) = [RACObserve(self.tlManager, tlProperties)
    map:^id<LABTaplyticsProperties> _Nullable(TLProperties * _Nullable properties) {
      return properties ?
            [[LABTaplyticsProperties alloc] initWithInnerTaplyticsProperites:properties] : nil;
    }];
}

- (void)startTaplyticsWithAPIKey:(NSString *)apiKey options:(nullable NSDictionary *)options {
  [Taplytics startTaplyticsAPIKey:apiKey options:options];
}

- (void)logEventWithName:(NSString *)name value:(nullable NSNumber *)value
              properties:(nullable NSDictionary *)properties {
  [Taplytics logEvent:name value:value metaData:properties];
}

- (void)setUserAttributes:(nullable NSDictionary *)userAttributes {
  [Taplytics setUserAttributes:userAttributes];
}

- (void)propertiesLoadedWithCompletion:(LABTaplyticsPropertiesLoadedBlock)completionBlock {
  [Taplytics propertiesLoadedCallback:completionBlock];
}

- (void)refreshPropertiesInBackground:(LABTaplyticsBackgroundFetchBlock)completionBlock {
  [Taplytics performBackgroundFetch:completionBlock];
}

- (void)performLoadPropertiesFromServer:(LABTaplyticsLoadPropertiesFromServerBlock)completionBlock {
  [self.tlManager performLoadPropertiesFromServer:nil returnBlock:completionBlock];
}

- (void)fetchPropertiesForExperiment:(NSString *)experiment
                       withVariation:(NSString *)variation
                          completion:(LABTaplyticsFetchPropertiesBlock)completionBlock {
  if (!self.tlManager.tlProperties.sessionID) {
    auto error = [NSError lab_errorWithCode:LABErrorCodeFetchFailed associatedExperiment:experiment
                          associatedVariant:variation];
    completionBlock(nil, error);
    return;
  }

  auto _Nullable requestDict = [self createVariationConfigForExperiment:experiment
                                                           andVariation:variation];
  if (!requestDict) {
    auto error = [NSError lab_errorWithCode:LABErrorCodeVariantForExperimentNotFound
                       associatedExperiment:experiment
                          associatedVariant:variation];
    completionBlock(nil, error);
    return;
  }

  [self.tlManager getPropertiesFromServer:requestDict returnBlock:
      ^(TLProperties * _Nullable properties, BOOL, NSError * _Nullable error) {
    if (error || !properties) {
      auto wrappedError = [NSError lab_errorWithCode:LABErrorCodeFetchFailed
                                associatedExperiment:experiment associatedVariant:variation
                                     underlyingError:error];
      completionBlock(nil, wrappedError);
      return;
    }

    completionBlock([[LABTaplyticsProperties alloc] initWithInnerTaplyticsProperites:properties],
                    nil);
  }];
}

- (nullable NSDictionary<NSString *, NSString *> *)createVariationConfigForExperiment:
    (NSString *)experiment andVariation:(NSString *)variation {
  auto _Nullable properties = self.tlManager.tlProperties;
  auto _Nullable experimentID = [properties lab_experimentIDForExperiment:experiment];
  auto _Nullable variationID = [properties lab_variationsIDForVariation:variation
                                                           inExperiment:experiment];

  if (!experimentID || !variationID || !properties.sessionID) {
    return nil;
  }

  // The keys in the dictionary are undocumented. The value for "exp" is the experiments ID, the
  // value of the "var" key is the variation ID and the value of "sid" is the session ID. All these
  // values can be found in the TLProperties object.
  return @{
    @"exp": experimentID,
    @"sid": properties.sessionID,
    @"var": variationID
  };
}

- (void)fetchPropertiesWithCompletion:(LABTaplyticsFetchPropertiesBlock)completionBlock {
  [self.tlManager getPropertiesFromServer:nil returnBlock:
      ^(TLProperties * _Nullable properties, BOOL, NSError * _Nullable error) {
     if (error || !properties) {
       auto wrappedError = [NSError lt_errorWithCode:LABErrorCodeFetchFailed underlyingError:error];
       completionBlock(nil, wrappedError);
       return;
     }

     completionBlock([[LABTaplyticsProperties alloc] initWithInnerTaplyticsProperites:properties],
                     nil);
   }];
}

@end

NS_ASSUME_NONNULL_END
