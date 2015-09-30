// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEnumRegistry.h"

#import "LTBidirectionalMap.h"

@interface LTEnumRegistry ()

/// Maps enum name (\c NSString ) to an \c NSDictionary of field names (\c NSString) to their
/// numeric (\c NSNumber) values.
@property (strong, nonatomic) NSMutableDictionary<NSString *,
    LTBidirectionalMap<NSString *, NSNumber *> *> *enumMapping;

@end

@implementation LTEnumRegistry

+ (instancetype)sharedInstance {
  static LTEnumRegistry *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTEnumRegistry alloc] init];
  });

  return instance;
}

- (instancetype)init {
  if (self = [super init]) {
    self.enumMapping = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)registerEnumName:(NSString *)enumName withFieldToValue:(NSDictionary *)fieldToValue {
  LTParameterAssert(![self isEnumRegistered:enumName],
                    @"Given enum name '%@' is already registered", enumName);
  self.enumMapping[enumName] = [[LTBidirectionalMap alloc] initWithDictionary:fieldToValue];
}

- (BOOL)isEnumRegistered:(NSString *)enumName {
  return self.enumMapping[enumName] != nil;
}

- (LTBidirectionalMap<NSString *, NSNumber *> *)enumFieldToValueForName:(NSString *)enumName {
  return self.enumMapping[enumName];
}

- (id)objectForKeyedSubscript:(NSString *)key {
  return [self enumFieldToValueForName:key];
}

@end
