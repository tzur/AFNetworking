// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTransformers.h"

#import <LTKit/LTEnum.h>

#import "LTVector.h"

@implementation LTTransformers

+ (NSValueTransformer *)transformerForClass:(Class)objectClass {
  if ([objectClass conformsToProtocol:@protocol(LTEnum)]) {
    return [self LTEnumTransformerForClass:objectClass];
  }
  return nil;
}

+ (NSValueTransformer *)transformerForTypeEncoding:(NSString *)typeEncoding {
  return [self typeEncodingToTransformer][typeEncoding];
}

+ (NSDictionary *)typeEncodingToTransformer {
  static NSDictionary *mapping;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mapping = @{
      @(@encode(LTVector2)): [self LTVector2Transformer],
      @(@encode(LTVector3)): [self LTVector3Transformer],
      @(@encode(LTVector4)): [self LTVector4Transformer]
    };
  });

  return mapping;
}

+ (NSValueTransformer *)transformerForArrayByApplying:(LTTransformerBlock)itemTransform {
  LTParameterAssert(itemTransform, @"Block transform must be non-nil");
  return [MTLValueTransformer transformerWithBlock:^NSArray *(NSArray *input) {
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:input.count];
    for (id item in input) {
      [output addObject:itemTransform(item)];
    }
    return [output copy];
  }];
}

#pragma mark -
#pragma mark Transformers
#pragma mark -

+ (MTLValueTransformer *)LTEnumTransformerForClass:(Class)objectClass {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^id<LTEnum>(id object) {
            if ([object isKindOfClass:[NSDictionary class]]) {
              return [self enumFromDictionary:object];
            } else if ([object isKindOfClass:[NSString class]]) {
              return [objectClass enumWithName:object];
            } else {
              return nil;
            }
          } reverseBlock:^NSString *(id<LTEnum> value) {
            return value.name;
          }];
}

+ (id<LTEnum>)enumFromDictionary:(NSDictionary *)dictionary {
  NSString *enumClass = dictionary[@"type"];
  NSString *enumValue = dictionary[@"name"];

  Class classObject = NSClassFromString(enumClass);
  if (!classObject || ![classObject conformsToProtocol:@protocol(LTEnum)]) {
    return nil;
  }

  return [[classObject alloc] initWithName:enumValue];
}

+ (MTLValueTransformer *)LTVector2Transformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSValue *(id string) {
    if (![string isKindOfClass:[NSString class]]) {
      return nil;
    }
    return $(LTVector2FromString(string));
  } reverseBlock:^NSString *(NSValue *value) {
    return NSStringFromLTVector2([value LTVector2Value]);
  }];
}

+ (MTLValueTransformer *)LTVector3Transformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSValue *(id string) {
    if (![string isKindOfClass:[NSString class]]) {
      return nil;
    }
    return $(LTVector3FromString(string));
  } reverseBlock:^NSString *(NSValue *value) {
    return NSStringFromLTVector3([value LTVector3Value]);
  }];
}

+ (MTLValueTransformer *)LTVector4Transformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSValue *(id string) {
    if (![string isKindOfClass:[NSString class]]) {
      return nil;
    }
    return $(LTVector4FromString(string));
  } reverseBlock:^NSString *(NSValue *value) {
    return NSStringFromLTVector4([value LTVector4Value]);
  }];
}

@end
