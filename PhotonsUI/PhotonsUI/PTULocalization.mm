// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTULocalization.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kPTUDefaultLocalizationTableName = @"Localizable";

@implementation PTULocalization

+ (NSDictionary<NSString *, LTLocalizationTable *> *)localizationTables {
  static NSDictionary<NSString *, LTLocalizationTable *> *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString * _Nullable path = [[NSBundle mainBundle] pathForResource:@"PhotonsUIBundle"
                                                                ofType:@"bundle"];
    if (!path) {
      sharedInstance = @{};
      return;
    }

    NSBundle * _Nullable bundle = [NSBundle bundleWithPath:path];
    if (!bundle) {
      sharedInstance = @{};
      return;
    }

    sharedInstance = @{
      kPTUDefaultLocalizationTableName: [[LTLocalizationTable alloc]
                                         initWithBundle:bundle
                                         tableName:kPTUDefaultLocalizationTableName]
    };
  });
  return sharedInstance;
}

@end

NS_ASSUME_NONNULL_END
