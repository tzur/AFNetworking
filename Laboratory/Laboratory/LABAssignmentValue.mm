// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentValue.h"

#import <LTKit/LTKeyPathCoding.h>

#import "LABAssignmentsManager.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LABAssignmentValue

+ (nullable LABAssignmentValue<id<LTEnum>> *)
    enumValueForAssignment:(nullable id<LABAssignment>)assignment enumClass:(Class)enumClass {
  LTParameterAssert([enumClass conformsToProtocol:@protocol(LTEnum)], @"Given enumClass %@ doesn't "
                    "conform to the LTEnum protocol", enumClass);
  if (![assignment.value isKindOfClass:NSString.class]) {
    LogError(@"Expected assignment %@ value to be of type NSString but got %@", assignment,
             [assignment.value class]);
    return nil;
  }

  if (![enumClass fieldNamesToValues][assignment.value]) {
    LogError(@"%@ is not a field in %@ enum", assignment.value, enumClass);
    return nil;
  }
  return [[LABAssignmentValue alloc] initWithValue:[[enumClass alloc] initWithName:assignment.value]
                                     andAssignment:assignment];
}

+ (nullable LABAssignmentValue<NSString *> *)
    stringValueForAssignment:(nullable id<LABAssignment>)assignment {
  if (![assignment.value isKindOfClass:NSString.class]) {
    LogError(@"Expected assignment %@ value to be of type NSString but got %@", assignment,
             [assignment.value class]);
    return nil;
  }
  return [[LABAssignmentValue alloc] initWithValue:assignment.value andAssignment:assignment];
}

+ (nullable LABAssignmentValue<NSNumber *> *)
    numberValueForAssignment:(nullable id<LABAssignment>)assignment {
  if (![assignment.value isKindOfClass:NSNumber.class]) {
    LogError(@"Expected assignment %@ value to be of type NSNumber but got %@", assignment,
             [assignment.value class]);
    return nil;
  }
  return [[LABAssignmentValue alloc] initWithValue:assignment.value andAssignment:assignment];
}

- (instancetype)initWithValue:(id)value andAssignment:(id<LABAssignment>)assignment {
  if (self = [super init]) {
    _assignment = assignment;
    _value = value;
  }
  return self;
}

#pragma mark -
#pragma mark NSCoding
#pragma mark -

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.assignment forKey:@instanceKeypath(LABAssignmentValue, assignment)];
  [aCoder encodeObject:self.value forKey:@instanceKeypath(LABAssignmentValue, value)];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  id<LABAssignment> _Nullable assignment =
      [aDecoder decodeObjectForKey:@instanceKeypath(LABAssignmentValue, assignment)];
  id _Nullable value =
      [aDecoder decodeObjectForKey:@instanceKeypath(LABAssignmentValue, value)];

  if (![assignment conformsToProtocol:@protocol(LABAssignment)] || !value) {
    return nil;
  }

  return [self initWithValue:value andAssignment:assignment];
}

@end

NS_ASSUME_NONNULL_END
