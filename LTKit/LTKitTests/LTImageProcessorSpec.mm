// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

#import <extobjc/extobjc.h>

#import "LTGLKitExtensions.h"

@interface LTFakeImageProcessor : LTImageProcessor

@property (nonatomic) CGFloat floatValue;
@property (nonatomic) NSInteger integerValue;

@property (nonatomic) GLKVector2 vector2Value;
@property (nonatomic) GLKVector3 vector3Value;
@property (nonatomic) GLKVector4 vector4Value;

@property (nonatomic) GLKMatrix2 matrix2Value;
@property (nonatomic) GLKMatrix3 matrix3Value;
@property (nonatomic) GLKMatrix4 matrix4Value;

@property (strong, nonatomic) NSString *stringValue;

@end

@implementation LTFakeImageProcessor

- (id<LTImageProcessorOutput>)process {
  return nil;
}

+ (NSSet *)inputModelProperties {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTFakeImageProcessor, floatValue),
      @instanceKeypath(LTFakeImageProcessor, integerValue),
      @instanceKeypath(LTFakeImageProcessor, vector2Value),
      @instanceKeypath(LTFakeImageProcessor, vector3Value),
      @instanceKeypath(LTFakeImageProcessor, vector4Value),
      @instanceKeypath(LTFakeImageProcessor, matrix2Value),
      @instanceKeypath(LTFakeImageProcessor, matrix3Value),
      @instanceKeypath(LTFakeImageProcessor, matrix4Value),
      @instanceKeypath(LTFakeImageProcessor, stringValue)
    ]];
  });

  return properties;
}

@end

SpecBegin(LTImageProcessor)

context(@"input model", ^{
  GLKMatrix2 matrix2 = {{1, 2,
                         3, 4}};
  GLKMatrix3 matrix3 = {{1, 2, 3,
                         4, 5, 6,
                         7, 8, 9}};
  GLKMatrix4 matrix4 = {{1, 2, 3, 4,
                         5, 6, 7, 8,
                         9, 10, 11, 12,
                         14, 15, 16, 17}};

  __block LTFakeImageProcessor *processor;

  beforeEach(^{
    processor = [[LTFakeImageProcessor alloc] init];
  });

  it(@"should get input model", ^{
    processor.floatValue = 5.f;
    processor.integerValue = 7;
    processor.stringValue = @"hello";

    processor.vector2Value = GLKVector2Make(1, 2);
    processor.vector3Value = GLKVector3Make(1, 2, 3);
    processor.vector4Value = GLKVector4Make(1, 2, 3, 4);

    processor.matrix2Value = matrix2;
    processor.matrix3Value = matrix3;
    processor.matrix4Value = matrix4;

    NSDictionary *model = [processor inputModel];

    expect(model[@keypath(processor, floatValue)]).to.equal(processor.floatValue);
    expect(model[@keypath(processor, integerValue)]).to.equal(processor.integerValue);
    expect(model[@keypath(processor, stringValue)]).to.equal(processor.stringValue);

    expect(model[@keypath(processor, vector2Value)]).to.equal($(processor.vector2Value));
    expect(model[@keypath(processor, vector3Value)]).to.equal($(processor.vector3Value));
    expect(model[@keypath(processor, vector4Value)]).to.equal($(processor.vector4Value));

    expect(model[@keypath(processor, matrix2Value)]).to.equal($(processor.matrix2Value));
    expect(model[@keypath(processor, matrix3Value)]).to.equal($(processor.matrix3Value));
    expect(model[@keypath(processor, matrix4Value)]).to.equal($(processor.matrix4Value));
  });

  it(@"should set input model", ^{
    NSDictionary *model = @{
      @keypath(processor, floatValue): @(5.f),
      @keypath(processor, integerValue): @(7),
      @keypath(processor, stringValue): @"hello",
      @keypath(processor, vector2Value): $(GLKVector2Make(1, 2)),
      @keypath(processor, vector3Value): $(GLKVector3Make(1, 2, 3)),
      @keypath(processor, vector4Value): $(GLKVector4Make(1, 2, 3, 4)),
      @keypath(processor, matrix2Value): $(matrix2),
      @keypath(processor, matrix3Value): $(matrix3),
      @keypath(processor, matrix4Value): $(matrix4)
    };

    [processor setInputModel:model];

    expect(processor.floatValue).to.equal([model[@keypath(processor, floatValue)] floatValue]);
    expect(processor.integerValue).to.equal([model[@keypath(processor, integerValue)]
                                             integerValue]);
    expect(processor.stringValue).to.equal(model[@keypath(processor, stringValue)]);

    expect($(processor.vector2Value)).to.equal(model[@keypath(processor, vector2Value)]);
    expect($(processor.vector3Value)).to.equal(model[@keypath(processor, vector3Value)]);
    expect($(processor.vector4Value)).to.equal(model[@keypath(processor, vector4Value)]);

    expect($(processor.matrix2Value)).to.equal(model[@keypath(processor, matrix2Value)]);
    expect($(processor.matrix3Value)).to.equal(model[@keypath(processor, matrix3Value)]);
    expect($(processor.matrix4Value)).to.equal(model[@keypath(processor, matrix4Value)]);
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
    NSDictionary *model = @{
      @keypath(processor, floatValue): @(5.f),
      @keypath(processor, integerValue): @(7),
      @keypath(processor, stringValue): @"hello",
      @keypath(processor, vector2Value): $(GLKVector2Make(1, 2)),
      @keypath(processor, vector3Value): $(GLKVector3Make(1, 2, 3)),
      @keypath(processor, vector4Value): $(GLKVector4Make(1, 2, 3, 4)),
      @keypath(processor, matrix2Value): $(matrix2),
      @keypath(processor, matrix3Value): $(matrix3),
      @keypath(processor, matrix4Value): $(matrix4),
      @"foo": @"bar",
    };

    expect(^{
      [processor setInputModel:model];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
