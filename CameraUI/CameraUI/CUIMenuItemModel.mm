// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMenuItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUIMenuItemModel

- (instancetype)initWithLocalizedTitle:(NSString *)localizedTitle iconURL:(NSURL *)iconURL
                                   key:(NSString *)key {
  NSError *initError;
  NSDictionary *values = @{
    @"localizedTitle": localizedTitle,
    @"iconURL": iconURL,
    @"key": key
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
