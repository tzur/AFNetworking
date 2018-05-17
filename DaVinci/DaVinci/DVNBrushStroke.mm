// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushStroke.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/NSValueTransformer+LTEngine.h>
#import <LTKit/LTHashExtensions.h>

#import "DVNBrushModel.h"
#import "DVNBrushRenderModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushStrokeSpecification

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithControlPointModel:(LTControlPointModel *)controlPointModel
                         brushRenderModel:(DVNBrushRenderModel *)brushRenderModel
                              endInterval:(lt::Interval<CGFloat>)endInterval {
  LTParameterAssert(controlPointModel);
  LTParameterAssert(brushRenderModel);
  LTParameterAssert(endInterval.inf() >= 0, @"Infimum of end interval (%@) must be non-negative",
                    endInterval.description());

  if (self = [super init]) {
    _controlPointModel = controlPointModel;
    _brushRenderModel = brushRenderModel;
    _endInterval = endInterval;
  }
  return self;
}

#pragma mark -
#pragma mark Factory Methods
#pragma mark -

+ (instancetype)specificationWithControlPointModel:(LTControlPointModel *)controlPointModel
                                  brushRenderModel:(DVNBrushRenderModel *)brushRenderModel
                                       endInterval:(lt::Interval<CGFloat>)endInterval {
  return [[self alloc] initWithControlPointModel:controlPointModel brushRenderModel:brushRenderModel
                                     endInterval:endInterval];
}

@end

@implementation DVNBrushStrokeData

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSpecification:(DVNBrushStrokeSpecification *)specification
                       textureMapping:(NSDictionary<NSString *, LTTexture *> *)mapping {
  LTParameterAssert(specification);
  LTParameterAssert(mapping);
  LTParameterAssert([specification.brushRenderModel.brushModel isValidTextureMapping:mapping],
                    @"Invalid texture mapping (%@) for given brush model (%@)", mapping,
                    specification.brushRenderModel.brushModel);

  if (self = [super init]) {
    _specification = specification;
    _textureMapping = mapping;
  }
  return self;
}

#pragma mark -
#pragma mark Factory Methods
#pragma mark -

+ (instancetype)dataWithSpecification:(DVNBrushStrokeSpecification *)specification
                       textureMapping:(NSDictionary<NSString *, LTTexture *> *)mapping {
  return [[self alloc] initWithSpecification:specification textureMapping:mapping];
}

@end

NS_ASSUME_NONNULL_END
