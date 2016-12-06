// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNTestGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTestGeometryProvider

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  _state++;
  return dvn::GeometryValues({lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))},
                             {0, 1}, samples);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNTestGeometryProviderModel alloc] initWithState:self.state];
}

@end

@implementation DVNTestGeometryProviderModel

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (BOOL)isEqual:(DVNTestGeometryProviderModel *)model {
  if (self == model) {
    return YES;
  }
  
  if (![model isKindOfClass:[DVNTestGeometryProviderModel class]]) {
    return NO;
  }
  
  return self.state == model.state;
}

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (id<DVNGeometryProvider>)provider {
  return [[DVNTestGeometryProvider alloc] initWithState:self.state];
}

@end

NS_ASSUME_NONNULL_END
