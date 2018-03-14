// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategoryKiosk.h"

#import <AdSupport/AdSupport.h>
#import <FBTweak/FBTweakCategory.h>
#import <FBTweak/FBTweakCollection.h>
#import <FBTweak/FBTweakStore.h>
#import <LTKit/UIDevice+Hardware.h>

#import "FBMutableTweak+RACSignalSupport.h"
#import "SHKTweakCategory.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SHKCommonTweaks

+ (NSArray<id<FBTweak>> *)generalInformationTweaks {
  auto device = [UIDevice currentDevice];
  auto deviceModel = device.lt_deviceKindString;
  auto iOSVersion = device.systemVersion;
  auto identifierManager = [ASIdentifierManager sharedManager];
  auto advertisingID = identifierManager.advertisingIdentifier.UUIDString;
  auto idForVendor = device.identifierForVendor.UUIDString ?: @"Unknown";
  auto infoDict = [[NSBundle mainBundle] infoDictionary];
  NSString *appVersion = infoDict[(__bridge NSString *)kCFBundleVersionKey] ?: @"Unknown";
  NSString *appVersionShort = infoDict[@"CFBundleShortVersionString"] ?: @"Unknown";

  return @[
    [[FBTweak alloc] initWithIdentifier:@"Device Model" name:@"Device Model"
                           currentValue:deviceModel],
    [[FBTweak alloc] initWithIdentifier:@"iOS Version" name:@"iOS Version" currentValue:iOSVersion],
    [[FBTweak alloc] initWithIdentifier:@"IDFA" name:@"IDFA" currentValue:advertisingID],
    [[FBTweak alloc] initWithIdentifier:@"IDFV" name:@"IDFV" currentValue:idForVendor],
    [[FBTweak alloc] initWithIdentifier:@"Build number" name:@"Build number"
                           currentValue:appVersion],
    [[FBTweak alloc] initWithIdentifier:@"App Version" name:@"App Version"
                           currentValue:appVersionShort],
  ];
}

@end

@implementation SHKTweakCategoryKiosk

+ (FBTweakCategory *)commonTweaksCategory {
  auto generalInformationCollection = [[FBTweakCollection alloc]
                                       initWithName:@"General Information"
                                       tweaks:[SHKCommonTweaks generalInformationTweaks]];
  return [[FBTweakCategory alloc] initWithName:@"Common Tweaks" tweakCollections:@[
    generalInformationCollection
  ]];
}

+ (void)addAllCategoriesToTweakStore {
  [[FBTweakStore sharedInstance] addTweakCategory:SHKTweakCategoryKiosk.commonTweaksCategory];
}

@end

NS_ASSUME_NONNULL_END
