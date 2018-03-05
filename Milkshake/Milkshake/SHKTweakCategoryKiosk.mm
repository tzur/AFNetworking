// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryKiosk.h"

#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakCollection.h>
#import <FBTweak/FBTweakStore.h>

#import "FBMutableTweak+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SHKCommonTweaks

+ (FBPersistentTweak *)activeLanguageTweak {
  FBPersistentTweak *languageTweak = [[FBPersistentTweak alloc]
                                      initWithIdentifier:@"Active Language"
                                      name:@"Locale (Requires restart)" defaultValue:@""];
  NSMutableDictionary *possibleLocales = [NSMutableDictionary dictionary];
  /// A space is prepended to make this default value appear first in the list of languages.
  possibleLocales[@""] = @" Device Language";
  auto englishLocale = [NSLocale localeWithLocaleIdentifier:@"en"];
  for (NSString *localeID in [NSBundle mainBundle].localizations) {
    NSString * _Nullable language = [englishLocale displayNameForKey:NSLocaleIdentifier
                                                               value:localeID];
    if (!language) {
      continue;
    }
    possibleLocales[localeID] = [NSString stringWithFormat:@"%@ (%@)",language, localeID];
  }

  languageTweak.possibleValues = possibleLocales;
  [[languageTweak shk_valueChanged] subscribeNext:^(NSString *locale) {
    [[NSUserDefaults standardUserDefaults] setObject:@[locale] forKey:@"AppleLanguages"];
  }];
  return languageTweak;
}

@end

@implementation SHKTweakCategoryKiosk

+ (FBTweakCategory *)commonTweaksCategory {
  auto collection = [[FBTweakCollection alloc]
                     initWithName:@"Language"
                     tweaks:@[SHKCommonTweaks.activeLanguageTweak]];
  return [[FBTweakCategory alloc] initWithName:@"Common Tweaks" tweakCollections:@[collection]];
}

+ (void)addAllCategoriesToTweakStore {
  [[FBTweakStore sharedInstance] addTweakCategory:SHKTweakCategoryKiosk.commonTweaksCategory];
}

@end

NS_ASSUME_NONNULL_END
