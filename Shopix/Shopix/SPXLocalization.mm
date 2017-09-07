// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXLocalization.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kSPXDefaultLocalizationTableName = @"Localizable";

@implementation SPXLocalization

+ (NSDictionary<NSString *, LTLocalizationTable *> *)localizationTables {
  static NSDictionary<NSString *, LTLocalizationTable *> *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString * _Nullable path = [[NSBundle mainBundle] pathForResource:@"ShopixBundle"
                                                                ofType:@"bundle"];
    if (!path) {
      sharedInstance = @{};
      return;
    }

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
