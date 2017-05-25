// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContext+Merge.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTAnalytricksContext (Merge)

- (instancetype)merge:(NSDictionary<NSString *,id> *)dictionary {
  NSUUID * _Nullable runID = dictionary[@keypath(self, runID)];
  if (![runID isKindOfClass:NSUUID.class]) {
    runID = self.runID;
  }

  NSUUID * _Nullable sessionID =
      [self mergeValue:dictionary[@keypath(self, sessionID)] toValue:self.sessionID
               ofClass:NSUUID.class];
  NSUUID * _Nullable screenUsageID =
      [self mergeValue:dictionary[@keypath(self, screenUsageID)] toValue:self.screenUsageID
               ofClass:NSUUID.class];
  NSString * _Nullable screenName =
      [self mergeValue:dictionary[@keypath(self, screenName)] toValue:self.screenName
               ofClass:NSString.class];
  NSUUID * _Nullable openProjectID =
      [self mergeValue:dictionary[@keypath(self, openProjectID)] toValue:self.openProjectID
               ofClass:NSUUID.class];

  return [[INTAnalytricksContext alloc] initWithRunID:runID sessionID:sessionID
                                        screenUsageID:screenUsageID screenName:screenName
                                        openProjectID:openProjectID];
}

- (nullable id)mergeValue:(nullable id)newValue toValue:(nullable id)value ofClass:(Class)classObj {
  if ([newValue isKindOfClass:NSNull.class]) {
    return nil;
  }

  if ([newValue isKindOfClass:classObj]) {
    return newValue;
  }

  return value;
}

@end

NS_ASSUME_NONNULL_END
