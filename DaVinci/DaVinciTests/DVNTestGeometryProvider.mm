// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNTestGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTestGeometryProvider

- (instancetype)initWithState:(NSUInteger)state quads:(std::vector<lt::Quad>)quads {
  if (self = [super init]) {
    _state = state;
    _quads = quads;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  _state++;
  std::vector<NSUInteger> indices;
  for (std::vector<lt::Quad>::size_type i = 0; i < self.quads.size(); ++i) {
    indices.push_back((NSUInteger)i);
  }
  return dvn::GeometryValues(self.quads, indices, samples);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNTestGeometryProviderModel alloc] initWithState:self.state quads:self.quads];
}

@end

@implementation DVNTestGeometryProviderModel

- (instancetype)initWithState:(NSUInteger)state quads:(std::vector<lt::Quad>)quads {
  if (self = [super init]) {
    _state = state;
    _quads = quads;
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

  return self.state == model.state && self.quads == model.quads;
}

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (id<DVNGeometryProvider>)provider {
  return [[DVNTestGeometryProvider alloc] initWithState:self.state quads:self.quads];
}

@end

NS_ASSUME_NONNULL_END
