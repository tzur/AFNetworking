// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryKiosk.h"

#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakCollection.h>
#import <FBTweak/FBTweakStore.h>

#import "FBMutableTweak+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SHKCommonTweaks
@end

@implementation SHKTweakCategoryKiosk

+ (FBTweakCategory *)commonTweaksCategory {
  return [[FBTweakCategory alloc] initWithName:@"Common Tweaks" tweakCollections:@[]];
}

+ (void)addAllCategoriesToTweakStore {
  [[FBTweakStore sharedInstance] addTweakCategory:SHKTweakCategoryKiosk.commonTweaksCategory];
}

@end

NS_ASSUME_NONNULL_END
