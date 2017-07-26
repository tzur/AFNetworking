// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentValue.h"

#import "LABAssignmentsManager.h"

LTEnumMake(NSUInteger, LABTestAssignmentEnum,
  LABTestAssignmentEnumA,
  LABTestAssignmentEnumB
);

LABAssignment *assignmentWithValue(id value) {
  return [[LABAssignment alloc] initWithValue:value key:@"bar" variant:@"baz" experiment:@"qux"
                                   sourceName:@"zorp"];
}

SpecBegin(LABAssignmentValue)

__block LABAssignment *assignment;

context(@"enum value", ^{
  it(@"should create an object from assignment with LTEnum value", ^{
    assignment = assignmentWithValue($(LABTestAssignmentEnumA).name);
    auto value = [LABAssignmentValue enumValueForAssignment:assignment
                                                  enumClass:LABTestAssignmentEnum.class];
    expect(value.value).to.equal($(LABTestAssignmentEnumA));
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should assert if enumClass does not conform to LTEnum", ^{
    assignment = assignmentWithValue($(LABTestAssignmentEnumA));
    expect(^{
      [LABAssignmentValue enumValueForAssignment:assignment enumClass:NSString.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return nil if value is not string", ^{
    assignment = assignmentWithValue(@6);
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });

  it(@"should return nil if value doesn't exist in enum", ^{
    assignment = assignmentWithValue(@"foo");
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });
});

context(@"NSString value", ^{
  it(@"should create an object from assignment with NSString value", ^{
    assignment = assignmentWithValue(@"foo");
    auto value = [LABAssignmentValue stringValueForAssignment:assignment];
    expect(value.value).to.equal(@"foo");
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should return nil if value is not NSString", ^{
    assignment = assignmentWithValue(@1337);
    expect([LABAssignmentValue enumValueForAssignment:assignment
                                            enumClass:LABTestAssignmentEnum.class]).to.beNil();
  });
});

context(@"NSNumber value", ^{
  it(@"should create an object from assignment with NSNumber value", ^{
    assignment = assignmentWithValue(@1337);
    auto value = [LABAssignmentValue numberValueForAssignment:assignment];
    expect(value.value).to.equal(@1337);
    expect(value.assignment).to.beIdenticalTo(assignment);
  });

  it(@"should return nil if value is not NSNumber", ^{
    assignment = assignmentWithValue(@"foo");
    expect([LABAssignmentValue numberValueForAssignment:assignment]).to.beNil();
  });
});

it(@"should serialize and deserialize", ^{
  assignment = assignmentWithValue(@"foo");
  auto value = [[LABAssignmentValue alloc] initWithValue:@"flop" andAssignment:assignment];
  auto data = [NSKeyedArchiver archivedDataWithRootObject:value];
  LABAssignmentValue * _Nullable deserializedValue =
      [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:nil];

  expect(deserializedValue).to.equal(value);
});

SpecEnd
