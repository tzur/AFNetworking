// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNProjectiveGeometryTransformerModel.h"

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

/// Geometry provider first delegating the geometry creation to another provider and afterwards
/// iterating over the constructed quads, transforming each quad according to a fixed
/// \c GLKMatrix3, and finally returning the transformed quads.
@interface DVNProjectiveGeometryTransformer : NSObject <DVNGeometryProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c provider and \c transform.
- (instancetype)initWithProvider:(id<DVNGeometryProvider>)provider
                       transform:(GLKMatrix3)transform NS_DESIGNATED_INITIALIZER;

/// Internally used provider.
@property (readonly, nonatomic) id<DVNGeometryProvider> provider;

/// Transform applied to quads constructed by \c provider.
@property (readonly, nonatomic) GLKMatrix3 transform;

@end

@implementation DVNProjectiveGeometryTransformer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProvider:(id<DVNGeometryProvider>)provider
                       transform:(GLKMatrix3)transform {
  if (self = [super init]) {
    _provider = provider;
    _transform = transform;
  }
  return self;
}

#pragma mark -
#pragma mark DVNGeometryProvider
#pragma mark -

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(BOOL)end {
  dvn::GeometryValues values = [self.provider valuesFromSamples:samples end:end];

  const std::vector<lt::Quad> &quads = values.quads();
  std::vector<lt::Quad> transformedQuads;
  transformedQuads.reserve(quads.size());

  for (const lt::Quad &quad : quads) {
    transformedQuads.push_back(quad.transformedBy(self.transform));
  }
  return dvn::GeometryValues(transformedQuads, values.indices(), values.samples());
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNProjectiveGeometryTransformerModel alloc]
          initWithGeometryProviderModel:[self.provider currentModel] transform:self.transform];
}

@end

@implementation DVNProjectiveGeometryTransformerModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)model
                                    transform:(GLKMatrix3)transform {
  if (self = [super init]) {
    _model = model;
    _transform = transform;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNProjectiveGeometryTransformerModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNProjectiveGeometryTransformerModel class]]) {
    return NO;
  }
  for (NSUInteger i = 0; i < sizeof(self.transform.m) / sizeof(self.transform.m[0]); ++i) {
    if (self.transform.m[i] != model.transform.m[i]) {
      return NO;
    }
  }
  return [self.model isEqual:model.model];
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, self.model.hash);
  lt::hash_combine(seed, std::hash<GLKMatrix3>()(self.transform));
  return seed;
}

#pragma mark -
#pragma mark Copying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTPRQuadProviderModel
#pragma mark -

- (id<DVNGeometryProvider>)provider {
  return [[DVNProjectiveGeometryTransformer alloc] initWithProvider:[self.model provider]
                                                          transform:self.transform];
}

@end

NS_ASSUME_NONNULL_END
