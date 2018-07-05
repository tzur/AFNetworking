// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStruct.h"

LTGPUStructMake(MySimpleStruct,
                float, value);

#pragma pack(4)
LTGPUStructMake(MyMediumStruct,
                LTVector2, position,
                LTVector3, intensity,
                LTVector4, color);

LTGPUStructMake(MyByteStruct,
                GLbyte, value);

LTGPUStructMake(MyUnsignedByteStruct,
                GLubyte, value);

LTGPUStructMake(MyShortStruct,
                GLshort, index);

LTGPUStructMake(MyUnsignedShortStruct,
                GLushort, index);

SpecBegin(LTGPUStructs)

context(@"struct registration", ^{
  it(@"should register simple struct", ^{
    NSString *structName = @"MySimpleStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MySimpleStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(1);

    LTGPUStructField *value = gpuStruct.fields[@"value"];
    expect(value.name).to.equal(@"value");
    expect(value.offset).to.equal(0);
    expect(value.type).to.equal(@"float");
    expect(value.size).to.equal(sizeof(float));
    expect(value.componentType).to.equal(GL_FLOAT);
    expect(value.componentCount).to.equal(1);
  });

  it(@"should register byte struct", ^{
    NSString *structName = @"MyByteStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MyByteStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(1);

    LTGPUStructField *value = gpuStruct.fields[@"value"];
    expect(value.name).to.equal(@"value");
    expect(value.offset).to.equal(0);
    expect(value.type).to.equal(@"GLbyte");
    expect(value.size).to.equal(sizeof(GLbyte));
    expect(value.componentType).to.equal(GL_BYTE);
    expect(value.componentCount).to.equal(1);
  });

  it(@"should register byte struct", ^{
    NSString *structName = @"MyUnsignedByteStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MyUnsignedByteStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(1);

    LTGPUStructField *value = gpuStruct.fields[@"value"];
    expect(value.name).to.equal(@"value");
    expect(value.offset).to.equal(0);
    expect(value.type).to.equal(@"GLubyte");
    expect(value.size).to.equal(sizeof(GLubyte));
    expect(value.componentType).to.equal(GL_UNSIGNED_BYTE);
    expect(value.componentCount).to.equal(1);
  });

  it(@"should register short struct", ^{
    NSString *structName = @"MyShortStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MyShortStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(1);

    LTGPUStructField *value = gpuStruct.fields[@"index"];
    expect(value.name).to.equal(@"index");
    expect(value.offset).to.equal(0);
    expect(value.type).to.equal(@"GLshort");
    expect(value.size).to.equal(sizeof(GLshort));
    expect(value.componentType).to.equal(GL_SHORT);
    expect(value.componentCount).to.equal(1);
  });

  it(@"should register unsigned short struct", ^{
    NSString *structName = @"MyUnsignedShortStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MyUnsignedShortStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(1);

    LTGPUStructField *value = gpuStruct.fields[@"index"];
    expect(value.name).to.equal(@"index");
    expect(value.offset).to.equal(0);
    expect(value.type).to.equal(@"GLushort");
    expect(value.size).to.equal(sizeof(GLushort));
    expect(value.componentType).to.equal(GL_UNSIGNED_SHORT);
    expect(value.componentCount).to.equal(1);
  });

  it(@"should register medium struct", ^{
    NSString *structName = @"MyMediumStruct";

    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                               structForName:structName];

    expect(gpuStruct).toNot.beNil();
    expect(gpuStruct.name).to.equal(structName);
    expect(gpuStruct.size).to.equal(sizeof(MyMediumStruct));

    expect(gpuStruct.fields).toNot.beNil();
    expect(gpuStruct.fields.count).to.equal(3);

    LTGPUStructField *position = gpuStruct.fields[@"position"];
    expect(position.name).to.equal(@"position");
    expect(position.offset).to.equal(0);
    expect(position.type).to.equal(@"LTVector2");
    expect(position.size).to.equal(sizeof(LTVector2));
    expect(position.componentType).to.equal(GL_FLOAT);
    expect(position.componentCount).to.equal(2);

    LTGPUStructField *intensity = gpuStruct.fields[@"intensity"];
    expect(intensity.name).to.equal(@"intensity");
    expect(intensity.offset).to.equal(sizeof(LTVector2));
    expect(intensity.type).to.equal(@"LTVector3");
    expect(intensity.size).to.equal(sizeof(LTVector3));
    expect(intensity.componentType).to.equal(GL_FLOAT);
    expect(intensity.componentCount).to.equal(3);

    LTGPUStructField *color = gpuStruct.fields[@"color"];
    expect(color.name).to.equal(@"color");
    expect(color.offset).to.equal(intensity.offset + intensity.size);
    expect(color.type).to.equal(@"LTVector4");
    expect(color.size).to.equal(sizeof(LTVector4));
    expect(color.componentType).to.equal(GL_FLOAT);
    expect(color.componentCount).to.equal(4);
  });
});

context(@"NSObject protocol", ^{
  context(@"gpu structs", ^{
    __block LTGPUStruct *gpuStruct;
    __block NSArray<LTGPUStructField *> *fields;

    beforeEach(^{
      gpuStruct = [[LTGPUStructRegistry sharedInstance] structForName:@"MyMediumStruct"];
      fields = [gpuStruct.fields allValues];
    });

    context(@"equality", ^{
      it(@"should return YES when comparing to itself", ^{
        expect([gpuStruct isEqual:gpuStruct]).to.beTruthy();
      });

      it(@"should return NO when comparing to nil", ^{
        expect([gpuStruct isEqual:nil]).to.beFalsy();
      });

      it(@"should return YES when comparing to equal gpu struct", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:gpuStruct.name
                                                                     size:gpuStruct.size
                                                                andFields:fields];
        expect([gpuStruct isEqual:anotherGPUStruct]).to.beTruthy();
      });

      it(@"should return NO when comparing to an object of a different class", ^{
        expect([gpuStruct isEqual:[[NSObject alloc] init]]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct with different name", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:@"anotherName"
                                                                     size:gpuStruct.size
                                                                andFields:fields];
        expect([gpuStruct isEqual:anotherGPUStruct]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct with different size", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:gpuStruct.name
                                                                     size:gpuStruct.size + 1
                                                                andFields:fields];
        expect([gpuStruct isEqual:anotherGPUStruct]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct with different fields", ^{
        NSMutableArray<LTGPUStructField *> *fields = [[gpuStruct.fields allValues] mutableCopy];
        [fields removeLastObject];
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:gpuStruct.name
                                                                     size:gpuStruct.size
                                                                andFields:fields];
        expect([gpuStruct isEqual:anotherGPUStruct]).to.beFalsy();
      });
    });

    context(@"hash", ^{
      it(@"should return the same hash value for equal objects", ^{
        LTGPUStruct *anotherGPUStruct = [[LTGPUStruct alloc] initWithName:gpuStruct.name
                                                                     size:gpuStruct.size
                                                                andFields:fields];
        expect(gpuStruct.hash).to.equal(anotherGPUStruct.hash);
      });
    });
  });

  context(@"gpu struct fields", ^{
    __block LTGPUStructField *field;

    beforeEach(^{
      field = [[LTGPUStructField alloc] initWithName:@"name" type:@"float" size:1 andOffset:0];
    });

    context(@"equality", ^{
      it(@"should return YES when comparing to itself", ^{
        expect([field isEqual:field]).to.beTruthy();
      });

      it(@"should return NO when comparing to nil", ^{
        expect([field isEqual:nil]).to.beFalsy();
      });

      it(@"should return YES when comparing to equal gpu struct field", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"name" type:@"float" size:1 andOffset:0];
        expect([field isEqual:anotherField]).to.beTruthy();
      });

      it(@"should return NO when comparing to an object of a different class", ^{
        expect([field isEqual:[[NSObject alloc] init]]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct field with different name", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"anotherName" type:@"float" size:1 andOffset:0];
        expect([field isEqual:anotherField]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct field with different type", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"name" type:@"GLKVector2" size:1 andOffset:0];
        expect([field isEqual:anotherField]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct field with different size", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"name" type:@"float" size:2 andOffset:0];
        expect([field isEqual:anotherField]).to.beFalsy();
      });

      it(@"should return NO when comparing to gpu struct field with different offset", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"name" type:@"float" size:1 andOffset:1];
        expect([field isEqual:anotherField]).to.beFalsy();
      });
    });

    context(@"hash", ^{
      it(@"should return the same hash value for equal objects", ^{
        LTGPUStructField *anotherField =
            [[LTGPUStructField alloc] initWithName:@"name" type:@"float" size:1 andOffset:0];
        expect(field.hash).to.equal(anotherField.hash);
      });
    });
  });
});

SpecEnd
