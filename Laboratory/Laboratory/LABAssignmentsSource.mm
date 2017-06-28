// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentsSource.h"

#import <LTKit/LTKeyPathCoding.h>

NS_ASSUME_NONNULL_BEGIN

@implementation LABVariant

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSString * _Nullable name = [aDecoder decodeObjectOfClass:[NSString class]
                                                     forKey:@instanceKeypath(LABVariant, name)];
  NSDictionary * _Nullable assignments =
      [aDecoder decodeObjectOfClass:[NSDictionary class]
                             forKey:@instanceKeypath(LABVariant, assignments)];
  NSString * _Nullable experiment =
      [aDecoder decodeObjectOfClass:[NSString class]
                             forKey:@instanceKeypath(LABVariant, experiment)];

  if (![name isKindOfClass:NSString.class] ||
      ![assignments isKindOfClass:NSDictionary.class] ||
      ![experiment isKindOfClass:NSString.class]) {
    return nil;
  }

  for (NSString *key in assignments) {
    if (![key isKindOfClass:NSString.class]) {
      return nil;
    }
  }

  return [self initWithName:name assignments:assignments experiment:experiment];
}

- (instancetype)initWithName:(NSString *)name
                 assignments:(NSDictionary<NSString *, id> *)assignments
                  experiment:(NSString *)experiment {
  if (self = [super init]) {
    _name = name;
    _assignments = assignments;
    _experiment = experiment;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:@instanceKeypath(LABVariant, name)];
  [aCoder encodeObject:self.assignments forKey:@instanceKeypath(LABVariant, assignments)];
  [aCoder encodeObject:self.experiment forKey:@instanceKeypath(LABVariant, experiment)];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

NS_ASSUME_NONNULL_END
