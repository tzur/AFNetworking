// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRModel

#pragma mark -
#pragma mark Nullability Validation
#pragma mark -

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet set];
  });

  return optionalPropertyKeys;
}

+ (NSDictionary<NSString *, id> *)defaultPropertyValues {
  static NSDictionary<NSString *, id> *defaultPropertyValues;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultPropertyValues = @{};
  });

  return defaultPropertyValues;
}

+ (BOOL)validateDictionaryValue:(NSDictionary<NSString *, id> *)dictionaryValue
       withOptionalPropertyKeys:(NSSet<NSString *> *)optionalPropertyKeys
                          error:(NSError * __autoreleasing *)error {
  for (NSString *key in [self propertyKeys]) {
    if ([optionalPropertyKeys containsObject:key]) {
      continue;
    }

    id value = dictionaryValue[key];
    if (!value || value == [NSNull null]) {
      if (error) {
        *error = [self integrityValidationErrorWithFailingKey:key];
      }
      return NO;
    }
  }
  return YES;
}

+ (NSError *)integrityValidationErrorWithFailingKey:(NSString *)failingKey {
  return [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                       description:@"Invalid dictionary value for model %@, dictionary is lacking "
          "a required value or specified null value for a required property key: '%@'", self,
          failingKey];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                             error:(NSError * __autoreleasing *)error {
  NSDictionary<NSString *, id> *dictionaryWithDefaults = [[[self class] defaultPropertyValues]
       mtl_dictionaryByAddingEntriesFromDictionary:dictionaryValue];
  if (![[self class] validateDictionaryValue:dictionaryWithDefaults
                    withOptionalPropertyKeys:[[self class] optionalPropertyKeys] error:error]) {
    return nil;
  }

  @try {
    if (self = [super initWithDictionary:dictionaryWithDefaults error:error]) {
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

#pragma mark -
#pragma mark Mutating properties
#pragma mark -

- (instancetype)modelByOverridingProperty:(NSString *)propertyName withValue:(nullable id)value {
  NSMutableDictionary *dictionaryValue = [self.dictionaryValue mutableCopy];
  dictionaryValue[propertyName] = value;
  BZRModel *model = [[self class] modelWithDictionary:[dictionaryValue copy] error:nil];
  LTAssert(model, @"Failed to initialize model with dictionary value %@", dictionaryValue);
  return model;
}

@end

NS_ASSUME_NONNULL_END
