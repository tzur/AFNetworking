// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

#import <extobjc/extobjc.h>

#import "LTGLKitExtensions.h"
#import "LTVector.h"

LTEnumMake(NSUInteger, LTImageProcessorEnum,
  LTImageProcessorEnumA,
  LTImageProcessorEnumB,
  LTImageProcessorEnumC
);

@interface LTFakeImageProcessor : LTImageProcessor

@property (nonatomic) float floatValue;
@property (nonatomic) NSInteger integerValue;

@property (nonatomic) LTVector2 vector2Value;
@property (nonatomic) LTVector3 vector3Value;
@property (nonatomic) LTVector4 vector4Value;

@property (strong, nonatomic) NSString *stringValue;

@property (strong, nonatomic) LTImageProcessorEnum *enumValue;

@end

@implementation LTFakeImageProcessor

- (void)process {
}

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTFakeImageProcessor, floatValue),
      @instanceKeypath(LTFakeImageProcessor, integerValue),
      @instanceKeypath(LTFakeImageProcessor, vector2Value),
      @instanceKeypath(LTFakeImageProcessor, vector3Value),
      @instanceKeypath(LTFakeImageProcessor, vector4Value),
      @instanceKeypath(LTFakeImageProcessor, stringValue),
      @instanceKeypath(LTFakeImageProcessor, enumValue),
    ]];
  });

  return properties;
}

- (float)defaultFloatValue {
  return 1;
}

- (NSInteger)defaultIntegerValue {
  return 1337;
}

- (LTVector2)defaultVector2Value {
  return LTVector2(2, 1);
}

- (LTVector3)defaultVector3Value {
  return LTVector3(3, 2, 1);
}

- (LTVector4)defaultVector4Value {
  return LTVector4(4, 3, 2, 1);
}

- (NSString *)defaultStringValue {
  return @"foo";
}

- (LTImageProcessorEnum *)defaultEnumValue {
  return $(LTImageProcessorEnumB);
}

@end

SpecBegin(LTImageProcessor)

context(@"input model", ^{
  __block LTFakeImageProcessor *processor;

  beforeEach(^{
    processor = [[LTFakeImageProcessor alloc] init];

    processor.floatValue = 5.f;
    processor.integerValue = 7;
    processor.stringValue = @"hello";
    processor.enumValue = $(LTImageProcessorEnumB);

    processor.vector2Value = LTVector2(1, 2);
    processor.vector3Value = LTVector3(1, 2, 3);
    processor.vector4Value = LTVector4(1, 2, 3, 4);
  });

  context(@"getting model", ^{
    it(@"should get input model", ^{
      NSDictionary *model = processor.inputModel;

      expect(model[@keypath(processor, floatValue)]).to.equal(processor.floatValue);
      expect(model[@keypath(processor, integerValue)]).to.equal(processor.integerValue);
      expect(model[@keypath(processor, stringValue)]).to.equal(processor.stringValue);
      expect(model[@keypath(processor, enumValue)]).to.equal(processor.enumValue);

      expect(model[@keypath(processor, vector2Value)]).to.equal($(processor.vector2Value));
      expect(model[@keypath(processor, vector3Value)]).to.equal($(processor.vector3Value));
      expect(model[@keypath(processor, vector4Value)]).to.equal($(processor.vector4Value));
    });

    it(@"should raise when trying to access non-existing key", ^{
      expect(^{
        [processor valueForKeyPath:@"foo"];
      }).to.raiseAny();
    });
  });

  context(@"setting input model", ^{
    __block NSDictionary *model = @{
      @keypath(processor, floatValue): @(5.f),
      @keypath(processor, integerValue): @(7),
      @keypath(processor, stringValue): @"hello",
      @keypath(processor, enumValue): $(LTImageProcessorEnumB),
      @keypath(processor, vector2Value): $(LTVector2(1, 2)),
      @keypath(processor, vector3Value): $(LTVector3(1, 2, 3)),
      @keypath(processor, vector4Value): $(LTVector4(1, 2, 3, 4))
    };

    it(@"should set input model", ^{
      [processor setInputModel:model];

      expect(processor.floatValue).to.equal([model[@keypath(processor, floatValue)] floatValue]);
      expect(processor.integerValue).to.equal([model[@keypath(processor, integerValue)]
                                               integerValue]);
      expect(processor.stringValue).to.equal(model[@keypath(processor, stringValue)]);
      expect(processor.enumValue).to.equal(model[@keypath(processor, enumValue)]);

      expect($(processor.vector2Value)).to.equal(model[@keypath(processor, vector2Value)]);
      expect($(processor.vector3Value)).to.equal(model[@keypath(processor, vector3Value)]);
      expect($(processor.vector4Value)).to.equal(model[@keypath(processor, vector4Value)]);
    });

    it(@"should raise when setting an incomplete model", ^{
      NSDictionary *model = @{
        @keypath(processor, floatValue): @(5.f),
        @keypath(processor, integerValue): @(7),
      };

      expect(^{
        [processor setInputModel:model];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when setting an overcomplete model", ^{
      NSMutableDictionary *overcompleteModel = [model mutableCopy];
      overcompleteModel[@"foo"] = @"bar";

      expect(^{
        [processor setInputModel:overcompleteModel];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"resetting input model", ^{
    it(@"should reset input model", ^{
      [processor resetInputModel];

      expect(processor.floatValue).to.equal(processor.defaultFloatValue);
      expect(processor.integerValue).to.equal(processor.defaultIntegerValue);
      expect(processor.stringValue).to.equal(processor.defaultStringValue);
      expect(processor.enumValue).to.equal(processor.defaultEnumValue);
      expect(processor.vector2Value).to.equal(processor.defaultVector2Value);
      expect(processor.vector3Value).to.equal(processor.defaultVector3Value);
      expect(processor.vector4Value).to.equal(processor.defaultVector4Value);
    });

    it(@"should reset input model without specific keys", ^{
      NSSet *keys = [NSSet setWithArray:@[@keypath(processor.floatValue),
                                          @keypath(processor.vector2Value)]];
      [processor resetInputModelExceptKeys:keys];

      expect(processor.floatValue).to.equal(5.f);
      expect(processor.vector2Value).to.equal(LTVector2(1, 2));

      expect(processor.integerValue).to.equal(processor.defaultIntegerValue);
      expect(processor.stringValue).to.equal(processor.defaultStringValue);
      expect(processor.enumValue).to.equal(processor.defaultEnumValue);
      expect(processor.vector3Value).to.equal(processor.defaultVector3Value);
      expect(processor.vector4Value).to.equal(processor.defaultVector4Value);
    });

    it(@"should return default input model", ^{
      NSDictionary *model = processor.defaultInputModel;

      NSDictionary *expectedModel = @{
        @keypath(processor.floatValue): @(processor.defaultFloatValue),
        @keypath(processor.integerValue): @(processor.defaultIntegerValue),
        @keypath(processor.stringValue): processor.defaultStringValue,
        @keypath(processor.enumValue): processor.defaultEnumValue,
        @keypath(processor.vector2Value): $(processor.defaultVector2Value),
        @keypath(processor.vector3Value): $(processor.defaultVector3Value),
        @keypath(processor.vector4Value): $(processor.defaultVector4Value),
      };

      expect(model).to.equal(expectedModel);
    });
  });
});

SpecEnd
