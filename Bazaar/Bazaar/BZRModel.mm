// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRModel

#pragma mark -
#pragma mark Nullability Validation
#pragma mark -

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet set];
  });

  return nullablePropertyKeys;
}

+ (BOOL)validateDictionaryValue:(NSDictionary *)dictionaryValue
       withNullablePropertyKeys:(NSSet<NSString *> *)nullablePropertyKeys
                          error:(NSError * __autoreleasing *)error {
  for (NSString *key in [self propertyKeys]) {
    if ([nullablePropertyKeys containsObject:key]) {
      continue;
    }

    id value = dictionaryValue[key];
    if (!value || value == [NSNull null]) {
      if (error) {
        *error = [self nullabilityValidationErrorWithFailingKey:key];
      }
      return NO;
    }
  }
  return YES;
}

+ (NSError *)nullabilityValidationErrorWithFailingKey:(NSString *)failingKey {
  NSString *description = [NSString stringWithFormat:@"Invalid dictionary value for model %@, "
                           "dictionary is lacking a value or specified null value for non-nullable "
                           "property key: '%@'", self, failingKey];
  return [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed description:description];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                             error:(NSError * __autoreleasing *)error {
  if (![[self class] validateDictionaryValue:dictionaryValue
                    withNullablePropertyKeys:[[self class] nullablePropertyKeys] error:error]) {
    return nil;
  }

  @try {
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
      if (![self validate:error]) {
        self = nil;
      }
    }
  } @catch (NSException *exception) {
    self = nil;
    if (error) {
      *error = [NSError bzr_errorWithCode:LTErrorCodeObjectCreationFailed exception:exception];
    }
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
