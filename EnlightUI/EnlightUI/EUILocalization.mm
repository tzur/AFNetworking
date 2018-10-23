// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUILocalization.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kEUIDefaultLocalizationTableName = @"Localizable";

/// Used to allow NSBundle to locate the bundle that contains EnlightUI.
@interface EUIBundleLocator : NSObject
@end

@implementation EUIBundleLocator
@end

@implementation EUILocalization

+ (NSDictionary<NSString *, LTLocalizationTable *> *)tablesMap {
  static NSDictionary<NSString *, LTLocalizationTable *> *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    auto _Nullable executableBundle = [NSBundle bundleForClass:EUIBundleLocator.class];
    auto _Nullable path = [executableBundle pathForResource:@"EnlightUIBundle" ofType:@"bundle"];
    LTAssert(path, @"Cannot find EnlightUI.bundle in EnlightUI's executable directory");

    auto _Nullable bundle = [NSBundle bundleWithPath:nn(path)];
    if (!bundle) {
      sharedInstance = @{};
      return;
    }

    sharedInstance = @{
      kEUIDefaultLocalizationTableName: [[LTLocalizationTable alloc]
                                         initWithBundle:nn(bundle)
                                         tableName:kEUIDefaultLocalizationTableName]
    };
  });

  return sharedInstance;
}

@end

NS_ASSUME_NONNULL_END
