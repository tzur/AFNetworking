// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTJSONSerializationAdapter.h"

LTEnumMake(NSUInteger, LTTestSerializableEnum,
  LTTestSerializableEnumA,
  LTTestSerializableEnumB
);

@interface LTTestMantleObject : MTLModel <MTLJSONSerializing>
@property (strong, nonatomic) NSString *field;
@end

@implementation LTTestMantleObject

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @"field": @"json_field"
  };
}

@end

@interface LTTestSerializableObject : NSObject <LTJSONSerializing>

/// Primitive.
@property (nonatomic) CGFloat floatValue;

/// ObjC object.
@property (strong, nonatomic) NSString *stringValue;

/// Enum.
@property (strong, nonatomic) LTTestSerializableEnum *enumValue;

/// JSON compatible object.
@property (strong, nonatomic) NSDictionary *jsonValue;

/// Mantle object.
@property (strong, nonatomic) LTTestMantleObject *mantleValue;

/// Value to be ignored when serializing.
@property (strong, nonatomic) NSNumber *ignoredValue;

@end

@implementation LTTestSerializableObject

+ (NSSet *)serializableKeyPaths {
  return [NSSet setWithArray:@[@"floatValue", @"stringValue", @"enumValue",
                               @"jsonValue", @"mantleValue"]];
}

@end

SpecBegin(LTJSONSerializationAdapter)

__block LTTestSerializableObject *object;
__block LTTestMantleObject *mantleObject;

beforeEach(^{
  mantleObject = [[LTTestMantleObject alloc] init];
  mantleObject.field = @"value";

  object = [[LTTestSerializableObject alloc] init];
  object.floatValue = 5.5;
  object.stringValue = @"foo";
  object.enumValue = $(LTTestSerializableEnumA);
  object.jsonValue = @{@"array": @[@"a", @"b"], @"key": @1};
  object.mantleValue = mantleObject;
  object.ignoredValue = @1337;
});

it(@"should serialize to json dictionary", ^{
  NSArray *keys = @[@"floatValue", @"stringValue", @"enumValue", @"jsonValue", @"mantleValue"];
  NSDictionary *values = [object dictionaryWithValuesForKeys:keys];

  NSDictionary *json = [LTJSONSerializationAdapter JSONDictionaryFromDictionary:values];

  expect(json[@"floatValue"]).to.equal(@(object.floatValue));
  expect(json[@"stringValue"]).to.equal(object.stringValue);
  expect(json[@"enumValue"]).to.equal(@{@"type": @"LTTestSerializableEnum",
                                        @"name": @"LTTestSerializableEnumA"});
  expect(json[@"jsonValue"]).to.equal(object.jsonValue);
  expect(json[@"mantleValue"]).to.equal(@{@"json_field": @"value"});
  expect(json[@"ignoredValue"]).to.beNil();
});

it(@"should deserialize from json dictionary", ^{
  NSDictionary *values = @{
    @"floatValue": @5.5,
    @"stringValue": @"foo",
    @"enumValue": @{@"type": @"LTTestSerializableEnum", @"name": @"LTTestSerializableEnumA"},
    @"jsonValue": @{@"array": @[@"a", @"b"], @"key": @1},
    @"mantleValue": @{@"json_field": @"value"},
    @"ignoredValue": @1337
  };

  NSDictionary *deserialized = [LTJSONSerializationAdapter
                                dictionaryFromJSONDictionary:values
                                forClass:[LTTestSerializableObject class]];

  expect(deserialized[@"floatValue"]).to.equal(@(object.floatValue));
  expect(deserialized[@"stringValue"]).to.equal(object.stringValue);
  expect(deserialized[@"enumValue"]).to.equal($(LTTestSerializableEnumA));
  expect(deserialized[@"jsonValue"]).to.equal(object.jsonValue);
  expect(deserialized[@"mantleValue"]).to.equal(mantleObject);
  expect(deserialized[@"ignoredValue"]).to.beNil();
});

it(@"should merge json values to object", ^{
  NSDictionary *values = @{
    @"floatValue": @10.5,
    @"stringValue": @"bar",
    @"enumValue": @{@"type": @"LTTestSerializableEnum", @"name": @"LTTestSerializableEnumB"},
    @"jsonValue": @{@"array": @[@"c", @"d"], @"key": @2},
    @"mantleValue": @{@"json_field": @"eulav"},
    @"ignoredValue": @42
  };

  [LTJSONSerializationAdapter mergeJSONDictionary:values toObject:object];

  LTTestMantleObject *mantleObject = [[LTTestMantleObject alloc] init];
  mantleObject.field = values[@"mantleValue"][@"json_field"];

  expect(object.floatValue).to.equal(values[@"floatValue"]);
  expect(object.stringValue).to.equal(values[@"stringValue"]);
  expect(object.enumValue).to.equal($(LTTestSerializableEnumB));
  expect(object.jsonValue).to.equal(values[@"jsonValue"]);
  expect(object.mantleValue).to.equal(mantleObject);
  expect(object.ignoredValue).to.equal(@1337);
});

SpecEnd
