// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestMTLModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTestMTLModel

- (instancetype)initWithName:(NSString *)name value:(NSUInteger)value {
  if (self = [super init]) {
    _name = name;
    _value = value;
  }
  return self;
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError *__autoreleasing *)error {
  if (self = [super initWithDictionary:dictionaryValue error:error]) {
    if (!self.name || !self.value) {
      return nil;
    }
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

@end

NS_ASSUME_NONNULL_END
