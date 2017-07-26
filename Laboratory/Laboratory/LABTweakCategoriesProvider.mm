// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "LABTweakCategoriesProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakCollection.h>

#import "LABTweakCategoriesProvider+Internal.h"
#import "LABTweakCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kLABUpdateStatusTweakNameStable = @"Update Status: Stable";

NSString * const kLABUpdateStatusTweakNameUpdating = @"Update Status: Updating";

NSString * const kLABUpdateStatusTweakNameStableUpdateFailed =
    @"Update Status: Stable Update Failed";

NSString * const kLABResetTweakName = @"Reset";

NSString * const kLABUpdateTweakName = @"Update";

@interface LABTweakCategoriesProvider () <FBTweakObserver>

/// Dictionary mapping category names to collections providers.
@property (readonly, nonatomic)
    NSDictionary<NSString *, id<LABTweakCollectionsProvider>> *providers;

/// Categories associated with the \c providers. Sorted by the category names.
@property (readonly, nonatomic)
    NSDictionary<NSString *, FBTweakCategory *> *internalProviderCategories;

@end

@implementation LABTweakCategoriesProvider

- (instancetype)initWithProviders:
    (NSDictionary<NSString *, id<LABTweakCollectionsProvider>> *)providers {
  if (self = [super init]) {
    _providers = providers;
    [self setupCategories];
    [self bindCategories];
  }
  return self;
}

- (void)setupCategories {
  _settingsCategory = [[FBTweakCategory alloc] initWithName:@"Settings"];
  auto providerCategories = [NSMutableDictionary dictionary];
  for (NSString *category in self.providers) {
    providerCategories[category] = [[FBTweakCategory alloc] initWithName:category];
    auto settingsCollection = [[FBTweakCollection alloc] initWithName:category];

    if ([self.providers[category] respondsToSelector:@selector(updateCollections)]) {
      auto updateTweak = [self updateTweakForCategory:category];
      [settingsCollection addTweak:updateTweak];
      [settingsCollection addTweak:[self statusTweakForCategory:category]];

      [updateTweak addObserver:self];
    }

    [settingsCollection addTweak:[self resetTweakForCategory:category]];
    [self.settingsCategory addTweakCollection:settingsCollection];
  }
  _internalProviderCategories = [providerCategories copy];
  _providerCategories = [[self.internalProviderCategories allValues]
      sortedArrayUsingComparator:^(FBTweakCategory *obj1, FBTweakCategory *obj2) {
        return [obj1.name compare:obj2.name];
      }];
}

- (FBTweak *)updateTweakForCategory:(NSString *)category {
  auto updateTweak = [[FBTweak alloc] initWithIdentifier:category];
  updateTweak.defaultValue = @NO;
  updateTweak.currentValue = @NO;
  updateTweak.name = kLABUpdateTweakName;
  return updateTweak;
}

- (FBTweak *)statusTweakForCategory:(NSString *)category {
  auto statusTweak =
      [[FBTweak alloc] initWithIdentifier:[self updateStatusTweakIDForCategory:category]];
  statusTweak.name = kLABUpdateStatusTweakNameStable;
  // This exists to make this tweak an action tweak. This makes the Tweaks UI display it as a
  // cell that when pressed on execute the action in \c defaultValue, instead of navigating to
  // the value selection screen, making this tweak a cell with a name and no action.
  statusTweak.defaultValue = ^{};
  return statusTweak;
}

- (NSString *)updateStatusTweakIDForCategory:(NSString *)category {
  return [@[category, @"status"] componentsJoinedByString:@"."];
}

- (FBTweak *)resetTweakForCategory:(NSString *)category {
  auto statusTweak =
      [[FBTweak alloc] initWithIdentifier:[@[category, @"reset"] componentsJoinedByString:@"."]];
  statusTweak.name = kLABResetTweakName;
  @weakify(self)
  statusTweak.defaultValue = ^{
    @strongify(self)
    [self.providers[category] resetTweaks];
  };
  return statusTweak;
}

- (void)bindCategories {
  [self.providers enumerateKeysAndObjectsUsingBlock:^(NSString *categoryName,
                                                      id<LABTweakCollectionsProvider> provider,
                                                      BOOL *) {
    @weakify(self)
    [RACObserve(provider, collections) subscribeNext:^(NSArray<FBTweakCollection *> *collections) {
      @strongify(self)
      auto category = self.internalProviderCategories[categoryName];
      for (FBTweakCollection *collection in collections) {
        auto _Nullable existingCollection = [category tweakCollectionWithName:collection.name];
        if (existingCollection) {
          [category removeTweakCollection:existingCollection];
        }
        [category addTweakCollection:collection];
      }
    }];
  }];
}

- (void)tweakDidChange:(FBTweak *)tweak {
  if ([tweak.currentValue boolValue]) {
    auto updateStatusTweak = [[self.settingsCategory tweakCollectionWithName:tweak.identifier]
        tweakWithIdentifier:[self updateStatusTweakIDForCategory:tweak.identifier]];
    updateStatusTweak.name = kLABUpdateStatusTweakNameUpdating;
    [[self.providers[tweak.identifier] updateCollections] subscribeError:^(NSError *error) {
      tweak.currentValue = @NO;
      LogError(@"Collection provider for category %@ failed, error: %@", tweak.identifier, error);
      updateStatusTweak.name = kLABUpdateStatusTweakNameStableUpdateFailed;
    } completed:^{
      tweak.currentValue = @NO;
      updateStatusTweak.name = kLABUpdateStatusTweakNameStable;
    }];
  }
}

- (NSArray<FBTweakCategory *> *)categories {
  return [@[self.settingsCategory] arrayByAddingObjectsFromArray:self.providerCategories];
}

@end

NS_ASSUME_NONNULL_END
