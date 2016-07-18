// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryTransformer.h"

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

/// Geometry provider first delegating the geometry creation to another provider and afterwards
/// iterating over the constructed quads, transforming each quad according to a fixed
/// \c CGAffineTransform, and finally returning the transformed quads.
@interface DVNGeometryTransformer : NSObject <DVNGeometryProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c provider and \c transform.
- (instancetype)initWithProvider:(id<DVNGeometryProvider>)provider
                       transform:(CGAffineTransform)transform NS_DESIGNATED_INITIALIZER;

/// Internally used provider.
@property (readonly, nonatomic) id<DVNGeometryProvider> provider;

/// Transform applied to quads constructed by \c provider.
@property (readonly, nonatomic) CGAffineTransform transform;

@end

@implementation DVNGeometryTransformer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProvider:(id<DVNGeometryProvider>)provider
                       transform:(CGAffineTransform)transform {
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

  CGAffineTransform transform = self.transform;

  for (const lt::Quad &quad : quads) {
    transformedQuads.push_back(lt::Quad(CGPointApplyAffineTransform(quad.v0(), transform),
                                        CGPointApplyAffineTransform(quad.v1(), transform),
                                        CGPointApplyAffineTransform(quad.v2(), transform),
                                        CGPointApplyAffineTransform(quad.v3(), transform)));
  }

  return dvn::GeometryValues(transformedQuads, values.indices(), values.samples());
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNGeometryTransformerModel alloc]
          initWithGeometryProviderModel:[self.provider currentModel] transform:self.transform];
}

@end

@implementation DVNGeometryTransformerModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)model
                                    transform:(CGAffineTransform)transform {
  if (self = [super init]) {
    _model = model;
    _transform = transform;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNGeometryTransformerModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNGeometryTransformerModel class]]) {
    return NO;
  }

  return [self.model isEqual:model.model] && CGAffineTransformEqualToTransform(self.transform,
                                                                               model.transform);
}

- (NSUInteger)hash {
  return self.model.hash ^ std::hash<CGAffineTransform>()(self.transform);
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
  return [[DVNGeometryTransformer alloc] initWithProvider:[self.model provider]
                                                transform:self.transform];
}

@end

NS_ASSUME_NONNULL_END
