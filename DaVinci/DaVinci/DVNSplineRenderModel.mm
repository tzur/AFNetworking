// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderModel.h"

#import <LTEngine/LTControlPointModel.h>

#import "DVNPipelineConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNSplineRenderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithControlPointModel:(LTControlPointModel *)controlPointModel
                            configuration:(DVNPipelineConfiguration *)configuration
                              endInterval:(lt::Interval<CGFloat>)endInterval {
  LTParameterAssert(controlPointModel);
  LTParameterAssert(configuration);
  LTParameterAssert(endInterval.inf() >= 0);

  if (self = [super init]) {
    _controlPointModel = controlPointModel;
    _configuration = configuration;
    _endInterval = endInterval;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNSplineRenderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNSplineRenderModel class]]) {
    return NO;
  }

  return [self.controlPointModel isEqual:model.controlPointModel] &&
      [self.configuration isEqual:model.configuration] && self.endInterval == model.endInterval;
}

- (NSUInteger)hash {
  return self.controlPointModel.hash ^ self.configuration.hash ^ self.endInterval.hash();
}

@end

NS_ASSUME_NONNULL_END
