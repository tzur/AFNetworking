// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryAdapter.h"

#import <FBTweak/FBTweakCollection.h>
#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation SHKTweakCategoryAdapter

- (instancetype)initWithTweakCategory:(id<SHKTweakCategory>)tweakCategory {
  if (self = [super initWithName:tweakCategory.name]) {
    _tweakCategory = tweakCategory;
    RAC(self, tweakCollections) = RACObserve(self.tweakCategory, tweakCollections);
  }
  return self;
}

- (void)updateWithCompletion:(FBTweakCategoryUpdateBlock)completion {
  if (![self.tweakCategory respondsToSelector:@selector(update)]) {
    completion(nil);
    return;
  }

  [self.tweakCategory.update subscribeError:^(NSError * _Nullable error) {
    completion(error);
  } completed:^{
    completion(nil);
  }];
}

- (void)reset {
  if ([self.tweakCategory respondsToSelector:@selector(reset)]) {
    [self.tweakCategory reset];
  }
}

- (FBTweakCollection * _Nullable)tweakCollectionWithName:(NSString *)name {
  return [self.tweakCollections lt_find:^BOOL(FBTweakCollection *tweakCollection) {
    return [name isEqualToString:tweakCollection.name];
  }];
}

- (void)addTweakCollection:(FBTweakCollection * __unused)tweakCollection {
}

- (void)removeTweakCollection:(FBTweakCollection * __unused)tweakCollection {
}

@end

NS_ASSUME_NONNULL_END
