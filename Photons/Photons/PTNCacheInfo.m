// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheInfo.h"

#import <LTKit/NSObject+AddToContainer.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheInfo

- (instancetype)initWithMaxAge:(NSTimeInterval)maxAge responseTime:(NSDate *)responseTime
                     entityTag:(nullable NSString *)entityTag {
  if (self = [super init]) {
    _maxAge = maxAge;
    _entityTag = entityTag;
    _responseTime = responseTime;
  }
  return self;
}

- (instancetype)initWithMaxAge:(NSTimeInterval)maxAge entityTag:(nullable NSString *)entityTag {
  return [self initWithMaxAge:maxAge responseTime:[NSDate date] entityTag:entityTag];
}

- (instancetype)refreshedCacheInfo {
  return [[PTNCacheInfo alloc] initWithMaxAge:self.maxAge entityTag:self.entityTag];
}

- (BOOL)isFreshComparedTo:(NSDate *)date {
  NSDate *expiration = [self.responseTime dateByAddingTimeInterval:self.maxAge];
  return [expiration compare:date] != NSOrderedAscending;
}

- (BOOL)isFresh {
  return [self isFreshComparedTo:[NSDate date]];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, max age: %g, response time: %@, entity tag: %@>",
          self.class, self, self.maxAge, self.responseTime, self.entityTag];
}

- (BOOL)isEqual:(PTNCacheInfo *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.maxAge == object.maxAge && [self.responseTime isEqual:object.responseTime] &&
      (self.entityTag == object.entityTag || [self.entityTag isEqualToString:object.entityTag]);
}

- (NSUInteger)hash {
  return self.responseTime.hash ^ self.entityTag.hash ^ @(self.maxAge).hash;
}

@end

@implementation PTNCacheInfo (Serialization)

/// Current version of this object and its serialization paradigm. This must change when the model
/// changes to allow correct deserialization of the serialized cache info.
+ (NSUInteger)modelVersion {
  return 0;
}

static NSString * const kVersionKey = @"version";
static NSString * const kMaxAgeKey = @"max-age";
static NSString * const kResponseTimeKey = @"response-time";
static NSString * const kEntityTagKey = @"entity-tag";

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary {
  if (![dictionary[kVersionKey] isEqual:@([self.class modelVersion])]) {
    return nil;
  }

  NSDate *responseTime = dictionary[kResponseTimeKey];
  if (!responseTime) {
    return nil;
  }

  NSString *entityTag = dictionary[kEntityTagKey];
  NSNumber *maxAge = dictionary[kMaxAgeKey];
  return [self initWithMaxAge:maxAge.doubleValue responseTime:responseTime entityTag:entityTag];
}

- (NSDictionary *)dictionary {
  NSMutableDictionary *data = [@{
    kVersionKey: @([self.class modelVersion]),
    kMaxAgeKey: @(self.maxAge),
    kResponseTimeKey: self.responseTime
  } mutableCopy];

  [self.entityTag setInDictionary:data forKey:kEntityTagKey];
  return [data copy];
}

@end

NS_ASSUME_NONNULL_END
