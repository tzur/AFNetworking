// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

#import "NSError+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Validating keypath
#pragma mark -

/// Validator used to validate that a given keypath is a legal path to variable.
@interface BZRKeypathValidator : NSObject

/// Returns \c YES if \c keypath is a valid keypath, \c NO otherwise.
+ (BOOL)isKeypathValid:(NSString *)keypath;

@end

@implementation BZRKeypathValidator

+ (BOOL)isKeypathValid:(NSString *)keypath {
  NSError *error;
  NSString *propertyNameMatch = @"([_a-zA-Z\\$][_a-zA-Z\\$\\d]*(\\[\\d+\\])?)";
  NSString *keypathMatch =
      [NSString stringWithFormat:@"^(%@\\.)*(%@)$", propertyNameMatch, propertyNameMatch];

  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:keypathMatch options:0 error:&error];
  NSRange matchRange =
      [regex rangeOfFirstMatchInString:keypath options:0 range:NSMakeRange(0, [keypath length])];
  return matchRange.location != NSNotFound;
}

@end

#pragma mark -
#pragma mark BZRModel
#pragma mark -

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

    id _Nullable value = dictionaryValue[key];
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

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
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
  return [self modelWithDictionaryValue:dictionaryValue];
}

- (instancetype)modelWithDictionaryValue:(NSDictionary<NSString *, id> *)dictionaryValue {
  BZRModel *model = [[self class] modelWithDictionary:dictionaryValue error:nil];
  LTAssert(model, @"Failed to initialize model with dictionary value %@", dictionaryValue);
  return model;
}

- (instancetype)modelByOverridingPropertyAtKeypath:(NSString *)keypath
                                         withValue:(nullable id)value {
  LTParameterAssert([BZRKeypathValidator isKeypathValid:keypath], @"Got an invalid keypath: %@",
                    keypath);
  NSArray<NSString *> *keypathElements = [keypath componentsSeparatedByString:@"."];
  return [self modelByOverridingPropertyAtKeypathInternal:keypathElements withValue:value];
}

- (instancetype)modelByOverridingPropertyAtKeypathInternal:(NSArray<NSString *> *)keypath
                                                 withValue:(nullable id)value {
  if (keypath.count == 1 && ![self isFirstKeyPathComponentAnArrayElement:keypath]) {
    return [self modelByOverridingProperty:keypath.firstObject withValue:value];
  }

  NSDictionary<NSString *, id> *dictionaryValue =
      [self isFirstKeyPathComponentAnArrayElement:keypath] ?
      [self dictionaryWithModifiedArrayAtKeypath:keypath withValue:value] :
      [self dictionaryWithModifiedObjectAtKeyPath:keypath withValue:value];

  return [self modelWithDictionaryValue:dictionaryValue];
}

- (NSDictionary<NSString *, id> *)dictionaryWithModifiedObjectAtKeyPath:
    (NSArray<NSString *> *)keypath withValue:(nullable id)value {
  NSString *propertyName = keypath.firstObject;
  NSArray<NSString *> *remainingKeypath =
      [keypath subarrayWithRange:NSMakeRange(1, keypath.count - 1)];
  id propertyValue = self.dictionaryValue[propertyName];
  LTParameterAssert(propertyValue, @"Got a keypath with invalid property name: %@", propertyName);
  LTParameterAssert([propertyValue isKindOfClass:BZRModel.class], @"Got a keypath with "
                    "non-BZRModel in non-final component: %@ of type %@", propertyName,
                    ((NSObject *)propertyValue).class);
  return [self.dictionaryValue mtl_dictionaryByAddingEntriesFromDictionary:@{
    propertyName: [propertyValue modelByOverridingPropertyAtKeypathInternal:remainingKeypath
                                                                  withValue:value]
  }];
}

- (NSDictionary<NSString *, id> *)dictionaryWithModifiedArrayAtKeypath:
    (NSArray<NSString *> *)keypath withValue:(nullable id)value {
  NSString *propertyName = keypath.firstObject;

  NSArray *arrayPropertyWithReplacedElement =
      [self arrayPropertyWithReplacedElement:propertyName keypath:keypath withValue:value];
  return [self.dictionaryValue mtl_dictionaryByAddingEntriesFromDictionary:@{
    [self arrayNameFromPropertyName:propertyName]: arrayPropertyWithReplacedElement
  }];
}

- (NSArray<NSString *> *)arrayPropertyWithReplacedElement:(NSString *)propertyName
    keypath:(NSArray<NSString *> *)keypath withValue:(nullable id)value {
  NSUInteger elementIndex = [self indexFromPropertyName:propertyName];
  NSArray *arrayProperty = [self arrayFromPropertyName:propertyName];
  LTParameterAssert(elementIndex < arrayProperty.count, @"Got index %lu that is out of bounds for "
                    "array property with name %@ that has size %lu", (unsigned long)elementIndex,
                    propertyName, (unsigned long)arrayProperty.count);

  id newElement =
      [self newElementAtKeypath:propertyName element:arrayProperty[elementIndex] keypath:keypath
                      withValue:value];
  NSMutableArray *arrayWithReplacedElement = [arrayProperty mutableCopy];
  arrayWithReplacedElement[elementIndex] = newElement ?: [NSNull null];
  return [arrayWithReplacedElement copy];
}

- (nullable id)newElementAtKeypath:(NSString *)propertyName element:(id)element
                           keypath:(NSArray<NSString *> *)keypath withValue:(nullable id)value {
  if(keypath.count <= 1) {
    return value;
  }

  LTParameterAssert([element isKindOfClass:BZRModel.class], @"Got a keypath that has an element in "
                    "an array that is a non-BZRModel in not-final component. Array property name "
                    "is: %@, keypath is: %@", propertyName, keypath);
  NSArray<NSString *> *remainingKeypath =
      [keypath subarrayWithRange:NSMakeRange(1, keypath.count - 1)];
  return [element modelByOverridingPropertyAtKeypathInternal:remainingKeypath withValue:value];
}

- (NSArray *)arrayFromPropertyName:(NSString *)propertyName {
  NSString *arrayPropertyName = [self arrayNameFromPropertyName:propertyName];
  LTParameterAssert([self.dictionaryValue[arrayPropertyName] isKindOfClass:NSArray.class], @"Got a "
                    "keypath with index for a property that is not an NSArray. Property name is: "
                    "%@", arrayPropertyName);
  return self.dictionaryValue[arrayPropertyName];
}

- (NSString *)arrayNameFromPropertyName:(NSString *)propertyName {
  NSUInteger indexOfStartBracket = [propertyName rangeOfString:@"["].location;
  return [propertyName substringToIndex:indexOfStartBracket];
}

- (NSUInteger)indexFromPropertyName:(NSString *)propertyName {
  NSUInteger indexOfStartBracket = [propertyName rangeOfString:@"["].location;
  NSUInteger indexOfCloseBracket = [propertyName rangeOfString:@"]"].location;
  NSRange indexRange =
      NSMakeRange(indexOfStartBracket + 1, indexOfCloseBracket - indexOfStartBracket - 1);
  return [[propertyName substringWithRange:indexRange] integerValue];
}

- (BOOL)isFirstKeyPathComponentAnArrayElement:(NSArray<NSString *> *)keypath {
  return [keypath.firstObject containsString:@"["];
}

@end

NS_ASSUME_NONNULL_END
