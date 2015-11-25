// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTErrorCodesRegistry.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTErrorCodesRegistry ()

/// Maps between an error code and its string description.
@property (strong, readwrite, nonatomic) LTMutableErrorCodeToDescription *mapping;

@end

@implementation LTErrorCodesRegistry

+ (instancetype)sharedRegistry {
  static LTErrorCodesRegistry *registry;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    registry = [[LTErrorCodesRegistry alloc] init];
  });

  return registry;
}

- (instancetype)init {
  if (self = [super init]) {
    self.mapping = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)registerErrorCodes:(LTErrorCodeToDescription *)errorCodes {
  NSMutableSet *keys = [NSMutableSet setWithArray:errorCodes.allKeys];
  [keys intersectSet:[NSSet setWithArray:self.mapping.allKeys]];
  LTParameterAssert(!keys.count, @"The error codes %@ already exist in the registry", keys);

  NSMutableSet *values = [NSMutableSet setWithArray:errorCodes.allValues];
  [values intersectSet:[NSSet setWithArray:self.mapping.allValues]];
  LTParameterAssert(!values.count, @"The error descriptions %@ already exist in the registry",
                    values);

  [self.mapping addEntriesFromDictionary:errorCodes];
}

- (nullable NSString *)descriptionForErrorCode:(NSInteger)errorCode {
  return self.mapping[@(errorCode)];
}

@end

NS_ASSUME_NONNULL_END
