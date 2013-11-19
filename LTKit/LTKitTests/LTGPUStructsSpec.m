// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUStructs.h"

LTGPUMakeStruct(MySimpleStruct,
                float, value);

#pragma pack(4)
LTGPUMakeStruct(MyMediumStruct,
                GLKVector2, position,
                GLKVector3, intensity,
                GLKVector4, color);

SpecBegin(LTGPUStructs)

context(@"struct registration", ^{
  it(@"should register simple struct", ^{
    NSArray *members = [[LTGPUStructs sharedInstance] structMembersForName:@"MySimpleStruct"];

    expect(members).toNot.beNil();
    expect(members.count).to.equal(1);

    expect(members[0][kLTGPUStructMemberName]).to.equal(@"value");
    expect(members[0][kLTGPUStructMemberOffset]).to.equal(0);
    expect(members[0][kLTGPUStructMemberType]).to.equal(@"float");
    expect(members[0][kLTGPUStructMemberTypeSize]).to.equal(sizeof(float));
  });

  it(@"should register medium struct", ^{
    NSArray *members = [[LTGPUStructs sharedInstance] structMembersForName:@"MyMediumStruct"];

    expect(members).toNot.beNil();
    expect(members.count).to.equal(3);

    expect(members[0][kLTGPUStructMemberName]).to.equal(@"position");
    expect(members[0][kLTGPUStructMemberOffset]).to.equal(0);
    expect(members[0][kLTGPUStructMemberType]).to.equal(@"GLKVector2");
    expect(members[0][kLTGPUStructMemberTypeSize]).to.equal(sizeof(GLKVector2));

    expect(members[1][kLTGPUStructMemberName]).to.equal(@"intensity");
    expect(members[1][kLTGPUStructMemberOffset]).to.equal(sizeof(GLKVector2));
    expect(members[1][kLTGPUStructMemberType]).to.equal(@"GLKVector3");
    expect(members[1][kLTGPUStructMemberTypeSize]).to.equal(sizeof(GLKVector3));

    expect(members[2][kLTGPUStructMemberName]).to.equal(@"color");
    expect(members[2][kLTGPUStructMemberOffset]).to.
        equal([members[1][kLTGPUStructMemberOffset] unsignedIntegerValue] + sizeof(GLKVector3));
    expect(members[2][kLTGPUStructMemberType]).to.equal(@"GLKVector4");
    expect(members[2][kLTGPUStructMemberTypeSize]).to.equal(sizeof(GLKVector4));
  });
});

SpecEnd
