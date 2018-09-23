// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

#import <LTEngine/NSValue+LTInterval.h>
#import <LTEngine/NSValueTransformer+LTEngine.h>
#import <LTKit/NSArray+NSSet.h>

#import "DVNPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    _version = $(DVNBrushModelVersionV1);
    _scale = 1;
    _scaleRange = lt::Interval<CGFloat>({0, CGFLOAT_MAX}, lt::Interval<CGFloat>::Open,
                                        lt::Interval<CGFloat>::Closed);
  }
  return self;
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  static NSDictionary<NSString *, NSString *> *mapping;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mapping = @{
      @instanceKeypath(DVNBrushModel, version): @"version",
      @instanceKeypath(DVNBrushModel, scale): @"scale",
      @instanceKeypath(DVNBrushModel, scaleRange): @"scaleRange",
      @instanceKeypath(DVNBrushModel, randomInitialSeed): @"randomInitialSeed",
      @instanceKeypath(DVNBrushModel, initialSeed): @"initialSeed",
      @instanceKeypath(DVNBrushModel, splineSmoothness): @"splineSmoothness"
    };
  });

  return mapping;
}

+ (NSValueTransformer *)versionJSONTransformer {
  return [NSValueTransformer lt_enumTransformerWithMap:[kDVNBrushModelVersionMapping dictionary]];
}

+ (NSValueTransformer *)scaleRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTCGFloatIntervalValueTransformer];
}

#pragma mark -
#pragma mark Public API - Scaling
#pragma mark -

- (instancetype)scaledBy:(CGFloat)scale {
  DVNBrushModel *model = [self copy];
  [model setValue:[NSValue valueWithLTCGFloatInterval:scale * self.scaleRange]
           forKey:@keypath(model, scaleRange)];
  // Ensure that the scale is updated after the scale range since the scale range might be clamped.
  [model setValue:@(model.scaleRange.clamp(scale * self.scale).value_or(model.scaleRange.inf()))
           forKey:@keypath(model, scale)];
  return model;
}

#pragma mark -
#pragma mark Public API - Copying
#pragma mark -

- (instancetype)copyWithScale:(CGFloat)scale {
  DVNBrushModel *model = [self copy];
  [model setValue:@(model.scaleRange.clamp(scale).value_or(model.scaleRange.inf()))
           forKey:@keypath(model, scale)];
  return model;
}

- (instancetype)copyWithRandomInitialSeed:(BOOL)randomInitialSeed {
  DVNBrushModel *model = [self copy];
  [model setValue:@(randomInitialSeed) forKey:@keypath(model, randomInitialSeed)];
  return model;
}

- (instancetype)copyWithInitialSeed:(NSUInteger)initialSeed {
  DVNBrushModel *model = [self copy];
  [model setValue:@(initialSeed) forKey:@keypath(model, initialSeed)];
  return model;
}

- (instancetype)copyWithSplineSmoothness:(CGFloat)splineSmoothness {
  DVNBrushModel *model = [self copy];
  [model setValue:@(splineSmoothness) forKey:@keypath(model, splineSmoothness)];
  return model;
}

#pragma mark -
#pragma mark Public API - Texture Mapping
#pragma mark -

/// Must be overridden by subclasses.
- (BOOL)isValidTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  return [textureMapping.allKeys.lt_set isSubsetOfSet:[[self class] imageURLPropertyKeys].lt_set];
}

/// Must be overridden by subclasses.
+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[];
}

#pragma mark -
#pragma mark Public API - Version
#pragma mark -

LTBidirectionalMap<DVNBrushModelVersion *, NSString *> * const kDVNBrushModelVersionMapping =
    [[LTBidirectionalMap alloc] initWithDictionary:@{
      $(DVNBrushModelVersionV1): @"1"
    }];

#pragma mark -
#pragma mark Properties
#pragma mark -

DVNLeftOpenRangeClassProperty(CGFloat, allowedScale, AllowedScale, 0,
                              std::numeric_limits<CGFloat>::max());

- (void)setScaleRange:(lt::Interval<CGFloat>)scaleRange {
  _scaleRange = *scaleRange.clampedTo([[self class] allowedScaleRange]);
}

DVNClosedRangeClassProperty(NSUInteger, allowedInitialSeed, AllowedInitialSeed, 0, NSUIntegerMax);

DVNClosedRangeClassProperty(CGFloat, allowedSplineSmoothness, AllowedSplineSmoothness, 0, 1);

- (void)setSplineSmoothness:(CGFloat)splineSmoothness {
  _splineSmoothness = *[[self class] allowedSplineSmoothnessRange].clamp(splineSmoothness);
}

@end

NS_ASSUME_NONNULL_END
