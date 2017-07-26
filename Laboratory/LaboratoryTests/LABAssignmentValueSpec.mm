// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentValue.h"

#import "LABAssignmentsManager.h"

LTEnumMake(NSUInteger, LABTestAssignmentEnum,
  LABTestAssignmentEnumA,
  LABTestAssignmentEnumB
);

SpecBegin(LABAssignmentValue)

__block id<LABAssignment> assignment;

beforeEach(^{
  assignment = OCMProtocolMock(@protocol(LABAssignment));
});

context(@"enum value", ^{
  it(@"should create an object from assignment with LTEnum value", ^{
    OCMStub([assignment value]).andReturn($(LABTestAssignmentEnumA).name);
    auto value = [LABAssignmentValue enumValueForAssignment:assignment
                                                  enumClass:LABTestAssignmentEnum.class];
    expect(value.value).to.equal($(LABTestAssignmentEnumA));
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should assert if enumClass does not conform to LTEnum", ^{
    expect(^{
      [LABAssignmentValue enumValueForAssignment:assignment enumClass:NSString.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return nil if value is not string", ^{
    OCMStub([assignment value]).andReturn(@6);
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });

  it(@"should return nil if value doesn't exist in enum", ^{
    OCMStub([assignment value]).andReturn(@"foo");
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });
});

context(@"NSString value", ^{
  it(@"should create an object from assignment with NSString value", ^{
    OCMStub([assignment value]).andReturn(@"foo");
    auto value = [LABAssignmentValue stringValueForAssignment:assignment];
    expect(value.value).to.equal(@"foo");
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should return nil if value is not NSString", ^{
    OCMStub([assignment value]).andReturn(@1337);
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });
});

context(@"NSNumber value", ^{
  it(@"should create an object from assignment with NSNumber value", ^{
    OCMStub([assignment value]).andReturn(@1337);
    auto value = [LABAssignmentValue numberValueForAssignment:assignment];
    expect(value.value).to.equal(@1337);
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should return nil if value is not NSNumber", ^{
    OCMStub([assignment value]).andReturn(@"foo");
    expect([LABAssignmentValue numberValueForAssignment:assignment]).to.beNil();
  });
});

it(@"should serialize and deserialize", ^{
  auto assignment = [[LABAssignment alloc] initWithValue:@"foo" key:@"bar" variant:@"baz"
                                              experiment:@"qux" sourceName:@"zorp"];
  auto value = [[LABAssignmentValue alloc] initWithValue:@"flop" andAssignment:assignment];
  auto data = [NSKeyedArchiver archivedDataWithRootObject:value];
  LABAssignmentValue * _Nullable deserializedValue =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:nil];

  expect(deserializedValue).to.equal(value);
});

SpecEnd
