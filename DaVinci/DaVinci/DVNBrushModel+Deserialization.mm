// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel+Deserialization.h"

#import "DVNBrushModelErrorCode.h"
#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushModel (Deserialization)

#pragma mark -
#pragma mark Public API - Deserialization
#pragma mark -

+ (nullable instancetype)modelFromJSONDictionary:(NSDictionary *)dictionary
                                           error:(NSError *__autoreleasing *)error {
  LTParameterAssert(dictionary);

  if (!dictionary[@"version"]) {
    if (error) {
      *error = [NSError lt_errorWithCode:$(DVNBrushModelErrorCodeNoSerializedVersion).value
                             description:@"No version string found in dictionary %@", dictionary];
    }
    return nil;
  }

  DVNBrushModelVersion * _Nullable version =
      [kDVNBrushModelVersionMapping keyForObject:dictionary[@"version"]];

  if (!version) {
    if (error) {
      *error = [NSError lt_errorWithCode:$(DVNBrushModelErrorCodeNoValidVersion).value
                             description:@"No valid version computable from retrieved dictionary "
                "(%@)", dictionary];
    }
    return nil;
  }

  return [MTLJSONAdapter modelOfClass:[version classOfBrushModel] fromJSONDictionary:dictionary
                                error:error];
}

@end

NS_ASSUME_NONNULL_END
