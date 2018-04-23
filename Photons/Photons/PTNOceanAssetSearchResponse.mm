// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetSearchResponse.h"

#import <Mantle/Mantle.h>

#import "NSErrorCodes+Photons.h"
#import "PTNOceanAssetDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNOceanAssetSearchResponse

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError *__autoreleasing *)error {
  if (![[[self class] propertyKeys] isEqualToSet:[NSSet setWithArray:dictionaryValue.allKeys]]) {
    if (error) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed];
    }
    return nil;
  }
  return [super initWithDictionary:dictionaryValue error:error];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @"page": @"page",
    @"count": @"result_count",
    @"results": @"results",
    @"pagesCount": @"total_pages",
    @"totalCount": @"total_results"
  };
}

+ (NSValueTransformer *)resultsJSONTransformer {
  return [NSValueTransformer
          mtl_JSONArrayTransformerWithModelClass:[PTNOceanAssetDescriptor class]];
}

@end

NS_ASSUME_NONNULL_END
