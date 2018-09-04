// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXLocalization.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSPXDefaultLocalizationTableName = @"Localizable";

/// Used to allow NSBundle to locate the bundle that contains Shopix.
@interface SPXBundleLocator : NSObject
@end

@implementation SPXBundleLocator
@end

@implementation SPXLocalization

+ (NSDictionary<NSString *, LTLocalizationTable *> *)localizationTables {
  static NSDictionary<NSString *, LTLocalizationTable *> *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    auto _Nullable executableBundle = [NSBundle bundleForClass:SPXBundleLocator.class];
    auto _Nullable path = [executableBundle pathForResource:@"Shopix" ofType:@"bundle"];
    LTAssert(path, @"Cannot find Shopix.bundle in Shopix's executable directory");

    auto _Nullable bundle = [NSBundle bundleWithPath:path];
    if (!bundle) {
      sharedInstance = @{};
      return;
    }

    sharedInstance = @{
      kSPXDefaultLocalizationTableName: [[LTLocalizationTable alloc]
                                         initWithBundle:bundle
                                         tableName:kSPXDefaultLocalizationTableName]
    };
  });

  return sharedInstance;
}

@end

NS_ASSUME_NONNULL_END
