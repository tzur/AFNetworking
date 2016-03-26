// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTJSONSerializationAdapter.h"

#import "LTTransformers.h"

@implementation LTJSONSerializationAdapter

#pragma mark -
#pragma mark Public
#pragma mark -

+ (NSDictionary *)JSONDictionaryFromDictionary:(NSDictionary *)dictionary {
  NSMutableDictionary *result = [NSMutableDictionary dictionary];

  [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    LTParameterAssert([key isKindOfClass:[NSString class]], @"Key must be a string, got: %@",
                      [key class]);
    result[key] = [self JSONObjectFromObject:obj];
  }];

  return [result copy];
}

+ (NSDictionary *)dictionaryFromJSONDictionary:(NSDictionary *)dictionary
                                      forClass:(Class)objectClass {
  LTParameterAssert([objectClass conformsToProtocol:@protocol(LTJSONSerializing)],
                    @"Given object class must conform to LTJSONSerializing");

  NSMutableDictionary *result = [NSMutableDictionary dictionary];
  NSSet *validKeyPaths = [objectClass serializableKeyPaths];

  [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    LTParameterAssert([key isKindOfClass:[NSString class]], @"Key must be a string, got: %@",
                      [key class]);

    // Ignore key paths that are not defined as serializable.
    if (![validKeyPaths containsObject:key]) {
      return;
    }

    result[key] = [self objectFromJSONObject:obj key:key forClass:objectClass];
  }];

  return [result copy];
}

+ (void)mergeJSONDictionary:(NSDictionary *)dictionary
                   toObject:(NSObject<LTJSONSerializing> *)object {
  NSDictionary *deserialized = [self dictionaryFromJSONDictionary:dictionary
                                                         forClass:[object class]];
  [object setValuesForKeysWithDictionary:deserialized];
}

#pragma mark -
#pragma mark Private
#pragma mark -

+ (id)objectFromJSONObject:(id)object key:(NSString *)key forClass:(Class)objectClass {
  ext_propertyAttributes *attributes = [self propertyAttributesForClass:objectClass key:key];
  if (!attributes) {
    LTAssert(NO, @"Given key %@ cannot be found on object of class %@", key, objectClass);
  }
  @onExit {
    free(attributes);
  };

  // If property is an object deserialize using property class.
  if (attributes->objectClass) {
    id deserialized = [self deserializeObject:object toClass:attributes->objectClass];
    LTParameterAssert(deserialized, @"Got nil deserialized object from %@, for class %@", object,
                      attributes->objectClass);
    return deserialized;
  } else {
    // Otherwise, use property type encoding.
    id deserialized = [self deserializeObject:object toTypeEncoding:@(attributes->type)];
    LTParameterAssert(deserialized, @"Got nil deserialized object from %@, for type encoding %@",
                      object, @(attributes->type));
    return deserialized;
  }
}

+ (id)JSONObjectFromObject:(id)object {
  // Can be directly written to JSON.
  if ([NSJSONSerialization isValidJSONObject:object]) {
    return object;
  }

  // NSString and NSNumber objects can be written directly to JSON.
  if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]] ||
      [object isKindOfClass:[NSNull class]]) {
    return object;
  }

  // Can be serialized using Mantle.
  if ([object isKindOfClass:[MTLModel class]] &&
      [object conformsToProtocol:@protocol(MTLJSONSerializing)]) {
    return [MTLJSONAdapter JSONDictionaryFromModel:object];
  }

  // Transform object manually.
  NSValueTransformer *transformer = [self transformerForObject:object];
  LTParameterAssert(transformer, @"No transformer found for object: %@", object);
  return [transformer reverseTransformedValue:object];
}

+ (id)deserializeObject:(id)object toClass:(Class)classObj {
  // No deserialization required.
  // TODO:(yaron) should this be isMemberOfClass: instead?
  if ([object isKindOfClass:classObj] || object == [NSNull null]) {
    return object;
  }

  // Deserialize using Mantle.
  if ([classObj isSubclassOfClass:[MTLModel class]] &&
      [classObj conformsToProtocol:@protocol(MTLJSONSerializing)]) {
    LTParameterAssert([object isKindOfClass:[NSDictionary class]], @"Mantle object is target for "
                      "deserialization, but got %@ instead of NSDictionary", [object class]);
    NSError *error;
    id deserialized = [MTLJSONAdapter modelOfClass:classObj fromJSONDictionary:object error:&error];
    LTParameterAssert(!error, @"Got error from Mantle while deserializing: %@",
                      error.description);
    return deserialized;
  }

  // Transform object manually.
  NSValueTransformer *transformer = [LTTransformers transformerForClass:classObj];
  LTParameterAssert(transformer, @"Object is not serializable and no transformer found: %@",
                    object);
  return [transformer transformedValue:object];
}

+ (id)deserializeObject:(id)object toTypeEncoding:(NSString *)typeEncoding {
  // Given object is a number and destination is a primitive number.
  if ([object isKindOfClass:[NSNumber class]] && [self typeEncodingIsNumeric:typeEncoding]) {
    return object;
  }

  // Transform object manually.
  NSValueTransformer *transformer = [LTTransformers transformerForTypeEncoding:typeEncoding];
  LTParameterAssert(transformer, @"No transformer is available for type encoding %@", typeEncoding);
  return [transformer transformedValue:object];
}

+ (BOOL)typeEncodingIsNumeric:(NSString *)typeEncoding {
  static NSSet * const kNumericTypeEncodings = [NSSet setWithArray:@[@"c", @"C", @"s", @"S", @"i",
                                                                     @"I", @"l", @"L", @"q", @"Q",
                                                                     @"f", @"d", @"B"]];
  return [kNumericTypeEncodings containsObject:typeEncoding];
}

#pragma mark -
#pragma mark Reflection
#pragma mark -

+ (ext_propertyAttributes *)propertyAttributesForClass:(Class)classObj key:(NSString *)key {
  const char *name = [key cStringUsingEncoding:NSUTF8StringEncoding];
  objc_property_t property = class_getProperty(classObj, name);
  if (!property) {
    return nil;
  }

  return ext_copyPropertyAttributes(property);
}

#pragma mark -
#pragma mark Transformers
#pragma mark -

+ (NSValueTransformer *)transformerForObject:(id)object {
  if ([object isKindOfClass:[NSValue class]]) {
    return [LTTransformers transformerForTypeEncoding:@([object objCType])];
  } else {
    return [LTTransformers transformerForClass:[object class]];
  }
  return nil;
}

@end
