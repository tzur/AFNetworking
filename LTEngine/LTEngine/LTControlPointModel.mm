// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTControlPointModel.h"

#import "LTBasicParameterizedObjectFactory.h"
#import "LTParameterizedObjectType.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTControlPointModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTParameterizedObjectType *)type {
  return [self initWithType:type controlPoints:@[]];
}

- (instancetype)initWithType:(LTParameterizedObjectType *)type
                  controlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints {
  if (self = [super init]) {
    _type = type;
    _controlPoints = [controlPoints copy];
  }
  return self;
}

#pragma mark -
#pragma mark Equality
#pragma mark -

- (BOOL)isEqual:(LTControlPointModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[LTControlPointModel class]]) {
    return NO;
  }

  return [self.type isEqual:model.type] && [self.controlPoints isEqualToArray:model.controlPoints];
}

- (NSUInteger)hash {
  return self.type.hash ^ self.controlPoints.hash;
}

@end

NS_ASSUME_NONNULL_END
