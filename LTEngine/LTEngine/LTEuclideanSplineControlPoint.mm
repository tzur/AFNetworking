// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTEuclideanSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTEuclideanSplineControlPoint ()

/// Set of keys of interpolatable attributes.
@property (strong, nonatomic) NSSet<NSString *> *propertiesToInterpolate;

@end

@implementation LTEuclideanSplineControlPoint

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp location:(CGPoint)location {
  return [self initWithTimestamp:timestamp location:location attributes:@{}];
}

- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp location:(CGPoint)location
                       attributes:(NSDictionary<NSString *, NSNumber *> *)attributes {
  LTParameterAssert(!CGPointIsNull(location), @"Provided point must not be CGPointNull");
  LTParameterAssert(attributes);

  if (self = [super init]) {
    _timestamp = timestamp;
    _location = location;
    _propertiesToInterpolate = [self propertiesToInterpolateWithAttributes:attributes];
    _attributes = [attributes copy];
  }
  return self;
}

- (NSSet<NSString *> *)propertiesToInterpolateWithAttributes:
    (NSDictionary<NSString *, NSNumber *> *)attributes {
  NSMutableSet<NSString *> *mutableSet =
      [NSMutableSet setWithArray:@[@keypath(self, xCoordinateOfLocation),
                                   @keypath(self, yCoordinateOfLocation)]];
  NSSet<NSString *> *attributeKeys = [NSSet setWithArray:[attributes allKeys]];
  LTParameterAssert(![mutableSet intersectsSet:attributeKeys],
                    @"The keys of the provided attributes (%@) must not intersect with the default "
                    "interpolatable properties (%@)", attributes, mutableSet);
  [mutableSet unionSet:attributeKeys];
  return [mutableSet copy];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTEuclideanSplineControlPoint *)controlPoint {
  if (self == controlPoint) {
    return YES;
  }

  if (![controlPoint isKindOfClass:[self class]]) {
    return NO;
  }

  return self.timestamp == controlPoint.timestamp && [self isEqualIgnoringTimestamp:controlPoint];
}

- (BOOL)isEqualIgnoringTimestamp:(LTEuclideanSplineControlPoint *)controlPoint {
  return CGPointEqualToPoint(self.location, controlPoint.location) &&
      [self.attributes isEqualToDictionary:controlPoint.attributes];
}

- (NSUInteger)hash {
  return @(self.timestamp).hash ^ CGPointHash(self.location) ^ self.attributes.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ : %p, timestamp: %g, location: (%g, %g), "
          "attributes: (%@)>", self.class, self, self.timestamp, self.location.x, self.location.y,
          self.attributes];
}

#pragma mark -
#pragma mark NSKeyValueCoding
#pragma mark -

- (nullable id)valueForKey:(NSString *)key {
  id value = self.attributes[key];

  if (value) {
    return value;
  }

  return [super valueForKey:key];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)xCoordinateOfLocation {
  return self.location.x;
}

- (CGFloat)yCoordinateOfLocation {
  return self.location.y;
}

@end

NS_ASSUME_NONNULL_END
