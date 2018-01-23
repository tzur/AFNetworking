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
    _brushModelVersion = $(DVNBrushModelVersionV1);
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
  return @{
    @instanceKeypath(DVNBrushModel, brushModelVersion): kDVNBrushModelVersionString,
    @instanceKeypath(DVNBrushModel, scale): @"scale",
    @instanceKeypath(DVNBrushModel, minScale): @"minScale",
    @instanceKeypath(DVNBrushModel, maxScale): @"maxScale"
  };
}

+ (NSValueTransformer *)brushModelVersionJSONTransformer {
  return [NSValueTransformer lt_enumTransformerWithMap:[kDVNBrushModelVersionMapping dictionary]];
}

#pragma mark -
#pragma mark Public API
#pragma mark -

NSString * const kDVNBrushModelVersionString = @"version";

LTBidirectionalMap<DVNBrushModelVersion *, NSString *> * const kDVNBrushModelVersionMapping =
    [[LTBidirectionalMap alloc] initWithDictionary:@{
      $(DVNBrushModelVersionV1): @"1"
    }];

@end

NS_ASSUME_NONNULL_END
