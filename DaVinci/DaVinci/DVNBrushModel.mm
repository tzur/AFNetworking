// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

#import <LTEngine/NSValue+LTInterval.h>
#import <LTEngine/NSValueTransformer+LTEngine.h>

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
      @instanceKeypath(DVNBrushModel, scaleRange): @"scaleRange"
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
#pragma mark Public API
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

- (instancetype)copyWithScale:(CGFloat)scale {
  DVNBrushModel *model = [self copy];
  [model setValue:@(model.scaleRange.clamp(scale).value_or(model.scaleRange.inf()))
           forKey:@keypath(model, scale)];
  return model;
}

/// Must be overridden by subclasses.
+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[];
}

LTBidirectionalMap<DVNBrushModelVersion *, NSString *> * const kDVNBrushModelVersionMapping =
    [[LTBidirectionalMap alloc] initWithDictionary:@{
      $(DVNBrushModelVersionV1): @"1"
    }];

DVNLeftOpenRangeClassProperty(CGFloat, allowedScale, AllowedScale, 0,
                              std::numeric_limits<CGFloat>::max());

- (void)setScaleRange:(lt::Interval<CGFloat>)scaleRange {
  _scaleRange = *scaleRange.clampedTo([[self class] allowedScaleRange]);
}

@end

NS_ASSUME_NONNULL_END
