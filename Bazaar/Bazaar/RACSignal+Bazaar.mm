// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+Bazaar.h"

#import "BZRModel.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Bazaar)

- (RACSignal *)bzr_deserializeModel:(Class)modelClass {
  LTParameterAssert([modelClass isSubclassOfClass:[BZRModel class]] &&
                    [modelClass conformsToProtocol:@protocol(MTLJSONSerializing)], @"Model class "
                    @"must be a subclass of BZRModel and conform to MTLJSONSerializing, got: %@",
                    modelClass);

  return [self tryMap:^BZRModel * _Nullable(NSDictionary *JSONDictionary, NSError **error) {
    @try {
      NSError *underlyingError;
      BZRModel *model = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary
                                              error:&underlyingError];
      if (!model || underlyingError) {
        *error = [NSError lt_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                          underlyingError:underlyingError];
      } else {
        return model;
      }
    } @catch (NSException *exception) {
      *error = [NSError bzr_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                                exception:exception];
    }
    return nil;
  }];
}

@end

NS_ASSUME_NONNULL_END
