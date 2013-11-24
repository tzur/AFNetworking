// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStruct.h"

LTGPUStructMake(MySimpleStruct,
                float, value);

#pragma pack(4)
LTGPUStructMake(MyMediumStruct,
                GLKVector2, position,
                GLKVector3, intensity,
                GLKVector4, color);

LTGPUStructMake(MyShortStruct,
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
    expect(position.type).to.equal(@"GLKVector2");
    expect(position.size).to.equal(sizeof(GLKVector2));
    expect(position.componentType).to.equal(GL_FLOAT);
    expect(position.componentCount).to.equal(2);

    LTGPUStructField *intensity = gpuStruct.fields[@"intensity"];
    expect(intensity.name).to.equal(@"intensity");
    expect(intensity.offset).to.equal(sizeof(GLKVector2));
    expect(intensity.type).to.equal(@"GLKVector3");
    expect(intensity.size).to.equal(sizeof(GLKVector3));
    expect(intensity.componentType).to.equal(GL_FLOAT);
    expect(intensity.componentCount).to.equal(3);

    LTGPUStructField *color = gpuStruct.fields[@"color"];
    expect(color.name).to.equal(@"color");
    expect(color.offset).to.equal(intensity.offset + intensity.size);
    expect(color.type).to.equal(@"GLKVector4");
    expect(color.size).to.equal(sizeof(GLKVector4));
    expect(color.componentType).to.equal(GL_FLOAT);
    expect(color.componentCount).to.equal(4);
  });
});

SpecEnd
