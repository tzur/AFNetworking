// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTValueObject.h"

/// Fake \c LTValueObject implementation with no properties.
@interface LTFakeValueObject : LTValueObject
@end

@implementation LTFakeValueObject
@end

/// Fake \c LTValueObject implementation with basic properties.
@interface LTFakeValueObjectWithProperties : LTValueObject

- (instancetype)initWithMyDouble:(double)myDouble myInteger:(NSInteger)myInteger
                        myString:(nullable NSString *)myString;

@property (nonatomic) double myDouble;
@property (nonatomic) NSInteger myInteger;
@property (strong, nonatomic, nullable) NSString *myString;

@end

@implementation LTFakeValueObjectWithProperties

- (instancetype)initWithMyDouble:(double)myDouble myInteger:(NSInteger)myInteger
                        myString:(nullable NSString *)myString {
  if (self = [super init]) {
    _myDouble = myDouble;
    _myInteger = myInteger;
    _myString = myString;
  }
  return self;
}

@end

/// Fake \c LTValueObject implementation with custom class properties.
@interface LTFakeValueObjectWithCompoundProperties : LTValueObject

- (instancetype)initWithMyValueObject:(nullable LTFakeValueObject *)myValueObject
   myPropertyValueObject:(nullable LTFakeValueObjectWithProperties *)myPropertyValueObject;

@property (strong, nonatomic, nullable) LTFakeValueObject *myValueObject;
@property (strong, nonatomic, nullable) LTFakeValueObjectWithProperties *myPropertyValueObject;

@end

@implementation LTFakeValueObjectWithCompoundProperties

- (instancetype)initWithMyValueObject:(nullable LTFakeValueObject *)myValueObject
    myPropertyValueObject:(nullable LTFakeValueObjectWithProperties *)myPropertyValueObject {
  if (self = [super init]) {
    _myValueObject = myValueObject;
    _myPropertyValueObject = myPropertyValueObject;
  }
  return self;
}

@end

/// Fake \c LTValueObject implementation with weak properties.
@interface LTFakeValueObjectWithWeakProperties : LTValueObject

- (instancetype)initWithMyDouble:(double)myDouble myInteger:(NSInteger)myInteger
                        myString:(nullable NSString *)myString;

@property (nonatomic) double myDouble;
@property (nonatomic) NSInteger myInteger;
@property (weak, nonatomic, nullable) NSString *myString;

@end

@implementation LTFakeValueObjectWithWeakProperties

- (instancetype)initWithMyDouble:(double)myDouble myInteger:(NSInteger)myInteger
                        myString:(nullable NSString *)myString {
  if (self = [super init]) {
    _myDouble = myDouble;
    _myInteger = myInteger;
    _myString = myString;
  }
  return self;
}

@end

SpecBegin(LTValueObject)

context(@"value object with no properties", ^{
  __block LTValueObject *firstObject;
  __block LTValueObject *secondObject;

  beforeEach(^{
    firstObject = [[LTFakeValueObject alloc] init];
    secondObject = [[LTFakeValueObject alloc] init];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstObject).to.equal(secondObject);
    expect(secondObject).to.equal(firstObject);

    expect(firstObject).notTo.equal(nil);
  });

  it(@"should return hash", ^{
    expect(firstObject.hash).to.equal(secondObject.hash);
  });

  it(@"should return descriptor", ^{
    NSString *description = [NSString stringWithFormat:@"<%@: %p>", firstObject.class, firstObject];
    expect([firstObject description]).to.equal(description);
  });
});

context(@"value object with properties", ^{
  __block LTFakeValueObjectWithProperties *firstObject;
  __block LTFakeValueObjectWithProperties *secondObject;
  __block LTFakeValueObjectWithProperties *thirdObject;

  beforeEach(^{
    firstObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                   myString:@"foo"];
    secondObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                    myString:@"foo"];
    thirdObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:8
                                                                   myString:@"foo"];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstObject).to.equal(secondObject);
    expect(secondObject).to.equal(firstObject);

    expect(firstObject).notTo.equal(thirdObject);
    expect(thirdObject).notTo.equal(firstObject);
    expect(firstObject).notTo.equal(nil);
  });

  it(@"should return hash", ^{
    expect(firstObject.hash).to.equal(secondObject.hash);
  });

  it(@"should return description", ^{
    NSString *description = [NSString stringWithFormat:@"<%@: %p, myDouble: %@, myInteger: %@, "
        "myString: %@>", firstObject.class, firstObject, @(0.3), @(7), @"foo"];
    expect([firstObject description]).to.equal(description);
  });
});

context(@"value object with nil properties", ^{
  __block LTFakeValueObjectWithProperties *firstObject;
  __block LTFakeValueObjectWithProperties *secondObject;
  __block LTFakeValueObjectWithProperties *thirdObject;

  beforeEach(^{
    firstObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                   myString:nil];
    secondObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                    myString:nil];
    thirdObject = [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                   myString:@"foo"];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstObject).to.equal(secondObject);
    expect(secondObject).to.equal(firstObject);

    expect(firstObject).notTo.equal(thirdObject);
    expect(thirdObject).notTo.equal(firstObject);
    expect(firstObject).notTo.equal(nil);
  });

  it(@"should return hash", ^{
    expect(firstObject.hash).to.equal(secondObject.hash);
  });

  it(@"should return description", ^{
    NSString *description = [NSString stringWithFormat:@"<%@: %p, myDouble: %@, myInteger: %@, "
        "myString: %@>", firstObject.class, firstObject, @(0.3), @(7), (id)nil];
    expect([firstObject description]).to.equal(description);
  });
});

context(@"value object with compound properties", ^{
  __block LTFakeValueObjectWithCompoundProperties *firstObject;
  __block LTFakeValueObjectWithCompoundProperties *secondObject;
  __block LTFakeValueObjectWithCompoundProperties *thirdObject;

  beforeEach(^{
    LTFakeValueObject *property = [[LTFakeValueObject alloc] init];
    LTFakeValueObjectWithProperties *firstPropertyWithProperties =
        [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:0.3 myInteger:7 myString:@"foo"];
    LTFakeValueObjectWithProperties *secondPropertyWithProperties =
        [[LTFakeValueObjectWithProperties alloc] initWithMyDouble:-0.4 myInteger:7 myString:@"foo"];

    firstObject = [[LTFakeValueObjectWithCompoundProperties alloc] initWithMyValueObject:property
        myPropertyValueObject:firstPropertyWithProperties];
    secondObject = [[LTFakeValueObjectWithCompoundProperties alloc] initWithMyValueObject:property
        myPropertyValueObject:firstPropertyWithProperties];
    thirdObject = [[LTFakeValueObjectWithCompoundProperties alloc] initWithMyValueObject:property
        myPropertyValueObject:secondPropertyWithProperties];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstObject).to.equal(secondObject);
    expect(secondObject).to.equal(firstObject);

    expect(firstObject).notTo.equal(thirdObject);
    expect(thirdObject).notTo.equal(firstObject);
    expect(firstObject).notTo.equal(nil);
  });

  it(@"should return hash", ^{
    expect(firstObject.hash).to.equal(secondObject.hash);
  });

  it(@"should return description", ^{
    NSString *description = [NSString stringWithFormat:@"<%@: %p, myValueObject: <%@: %p>, "
        "myPropertyValueObject: <%@: %p, myDouble: %@, myInteger: %@, myString: %@>>",
        firstObject.class, firstObject, firstObject.myValueObject.class, firstObject.myValueObject,
        firstObject.myPropertyValueObject.class, firstObject.myPropertyValueObject, @(0.3), @(7),
        @"foo"];
    expect([firstObject description]).to.equal(description);
  });
});

context(@"value object with weak properties", ^{
  __block LTFakeValueObjectWithWeakProperties *firstObject;
  __block LTFakeValueObjectWithWeakProperties *secondObject;
  __block NSString *string;
  
  beforeEach(^{
    string = @"foo";
    firstObject = [[LTFakeValueObjectWithWeakProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                       myString:string];
    secondObject = [[LTFakeValueObjectWithWeakProperties alloc] initWithMyDouble:0.3 myInteger:7
                                                                       myString:string];
  });
  
  it(@"should raise on isEqual", ^{
    expect(^{
      [firstObject isEqual:secondObject];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise on hash", ^{
    expect(^{
      [firstObject hash];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise on description", ^{
    expect(^{
      [firstObject description];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SpecEnd
