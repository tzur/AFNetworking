// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksCategory.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRTweakCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSArray<FBTweakCollection *> BZRCollectionArray;

@interface BZRTweaksCategory ()

/// Tweak collection that is used to show Bazaar related tweaks.
@property (strong, readwrite, nonatomic) NSArray<FBTweakCollection *> *tweakCollections;

@end

@implementation BZRTweaksCategory

@synthesize name = _name;

- (instancetype)initWithCollectionsProviders:(NSArray<id<BZRTweakCollectionsProvider>> *)providers {
  if (self = [super init]) {
    _name = @"Bazaar";
    [self setupTweakCollectionsFromProviders:providers];
  }
  return self;
}

- (void)setupTweakCollectionsFromProviders:(NSArray<id<BZRTweakCollectionsProvider>> *)providers {
  auto collectionsSignals = [providers
      lt_map:^RACSignal<BZRCollectionArray *> *(id<BZRTweakCollectionsProvider> provider) {
        return RACObserve(provider, collections);
      }];

  @weakify(self)
  RAC(self, tweakCollections) = [[RACSignal combineLatest:collectionsSignals]
      map:^BZRCollectionArray *(RACTuple *tupleOfArrays) {
        @strongify(self)
        if (!self) {
          return @[];
        }
        return [self flattenTupleOfArrays:tupleOfArrays];
      }];
}

- (NSArray *)flattenTupleOfArrays:(RACTuple *)tupleOfArrays {
  return [[tupleOfArrays allObjects] valueForKeyPath:@"@unionOfArrays.self"];
}

@end

NS_ASSUME_NONNULL_END
