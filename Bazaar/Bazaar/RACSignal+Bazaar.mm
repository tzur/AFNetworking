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
    BZRModel *model = nil;
    @try {
      NSError *underlyingError;
      model = [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:JSONDictionary
                                     error:&underlyingError];
      if (!model && error) {
        *error = [NSError lt_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                           underlyingError:underlyingError];
      }
    } @catch (NSException *exception) {
      if (error) {
        *error = [NSError bzr_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                                  exception:exception];
      }
    }
    return model;
  }];
}

- (RACSignal *)bzr_deserializeArrayOfModels:(Class)modelClass {
  LTParameterAssert([modelClass isSubclassOfClass:[BZRModel class]] &&
                    [modelClass conformsToProtocol:@protocol(MTLJSONSerializing)], @"Model class "
                    @"must be a subclass of BZRModel and conform to MTLJSONSerializing, got: %@",
                    modelClass);

  return [self tryMap:^NSArray * _Nullable(NSArray<NSDictionary *> *JSONArray, NSError **error) {
    NSArray<BZRModel *> *models = nil;
    @try {
      NSError *underlyingError;
      models = [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:JSONArray
                                       error:&underlyingError];
      if (!models && error) {
        *error = [NSError lt_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                           underlyingError:underlyingError];
      }
    } @catch (NSException *exception) {
      if (error) {
        *error = [NSError bzr_errorWithCode:BZRErrorCodeModelJSONDeserializationFailed
                                  exception:exception];
      }
    }
    return models;
  }];
}

- (RACSignal *)delayedRetry:(NSUInteger)retryCount initialDelay:(NSTimeInterval)initialDelay {
  __block NSTimeInterval secondsUntilNextTry = initialDelay;
  return [[[self
      catch:^(NSError *error) {
        return [[[RACSignal empty]
            delay:secondsUntilNextTry]
            concat:[RACSignal error:error]];
      }]
      doError:^(NSError *) {
        secondsUntilNextTry *= 2;
      }]
      retry:retryCount];
}

@end

NS_ASSUME_NONNULL_END
