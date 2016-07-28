// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIMenuItemModel

- (instancetype)initWithLocalizedTitle:(nullable NSString *)localizedTitle
                               iconURL:(nullable NSURL *)iconURL
                                   key:(nullable NSString *)key {
  NSError *initError;
  NSDictionary *values = @{
    @"localizedTitle": localizedTitle ?: [NSNull null],
    @"iconURL": iconURL ?: [NSNull null],
    @"key": key ?: [NSNull null]
  };
  self = [super initWithDictionary:values error:&initError];
  LTAssert(!initError, @"Error occurred during initialization: %@", initError);
  return self;
}

+ (NSValueTransformer *)iconURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

@end

NS_ASSUME_NONNULL_END
