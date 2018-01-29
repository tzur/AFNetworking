// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

#import <LTEngine/NSValueTransformer+LTEngine.h>

#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    _version = $(DVNBrushModelVersionV1);
    _scale = 1;
    _minScale = 0;
    _maxScale = CGFLOAT_MAX;
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
      @instanceKeypath(DVNBrushModel, minScale): @"minScale",
      @instanceKeypath(DVNBrushModel, maxScale): @"maxScale"
    };
  });

  return mapping;
}

+ (NSValueTransformer *)versionJSONTransformer {
  return [NSValueTransformer lt_enumTransformerWithMap:[kDVNBrushModelVersionMapping dictionary]];
}

#pragma mark -
#pragma mark Public API
#pragma mark -

LTBidirectionalMap<DVNBrushModelVersion *, NSString *> * const kDVNBrushModelVersionMapping =
    [[LTBidirectionalMap alloc] initWithDictionary:@{
      $(DVNBrushModelVersionV1): @"1"
    }];

#pragma mark -
#pragma mark Private API
#pragma mark -

/// Must be overridden by subclasses.
+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[];
}

@end

NS_ASSUME_NONNULL_END
