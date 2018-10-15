// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTErrorCodesRegistry.h"

#import "NSArray+NSSet.h"
#import "NSSet+Operations.h"

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
  NSSet *keys = [[errorCodes.allKeys lt_set]
                 lt_intersect:[self.mapping.allKeys lt_set]];
  LTParameterAssert(!keys.count, @"The error codes %@ already exist in the registry", keys);

  NSSet<NSString *> *values = [[errorCodes.allValues lt_set]
                               lt_intersect:[self.mapping.allValues lt_set]];
  LTParameterAssert(!values.count, @"The error descriptions %@ already exist in the registry",
                    values);

  [self.mapping addEntriesFromDictionary:errorCodes];
}

- (nullable NSString *)descriptionForErrorCode:(NSInteger)errorCode {
  return self.mapping[@(errorCode)];
}

@end

NS_ASSUME_NONNULL_END
