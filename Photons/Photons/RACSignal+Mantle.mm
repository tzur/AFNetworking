// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "RACSignal+Mantle.h"

#import <Mantle/Mantle.h>

#import "NSErrorCodes+Photons.h"
#import "RACSignal+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Mantle)

- (RACSignal *)ptn_parseDictionaryWithClass:(Class)modelClass {
  return [[self
      tryMap:^RACSignal *(NSDictionary *dictionary, NSError *__autoreleasing *error) {
        return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:dictionary
                                      error:error];
      }]
      ptn_wrapErrorWithError:[NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed]];
}

@end

NS_ASSUME_NONNULL_END
