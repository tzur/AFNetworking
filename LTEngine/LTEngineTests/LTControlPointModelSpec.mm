// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTControlPointModel.h"

#import "LTParameterizedObjectType.h"
#import "LTSplineControlPoint.h"

SpecBegin(LTControlPointModel)

__block LTControlPointModel *model;
__block id typeMock;
__block NSArray *controlPointMocks;

beforeEach(^{
  typeMock = OCMClassMock([LTParameterizedObjectType class]);
  controlPointMocks = @[OCMClassMock([LTSplineControlPoint class])];
  model = [[LTControlPointModel alloc] initWithType:typeMock controlPoints:controlPointMocks];
});

afterEach(^{
  model = nil;
  typeMock = nil;
  controlPointMocks = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model.type).to.equal(typeMock);
    expect(model.controlPoints).to.equal(controlPointMocks);
  });
});

context(@"NSObject protocol", ^{
  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([model isEqual:model]).to.beTruthy();
    });

    it(@"should return YES when comparing to equal model", ^{
      LTControlPointModel *anotherModel =
          [[LTControlPointModel alloc] initWithType:typeMock controlPoints:controlPointMocks];
      expect([model isEqual:anotherModel]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([model isEqual:nil]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([model isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to model with different type", ^{
      LTParameterizedObjectType *anotherTypeMock = OCMClassMock([LTParameterizedObjectType class]);
      LTControlPointModel *anotherModel =
          [[LTControlPointModel alloc] initWithType:anotherTypeMock
                                      controlPoints:controlPointMocks];
      expect([model isEqual:anotherModel]).to.beFalsy();
    });

    it(@"should return NO when comparing to model with different control points", ^{
      LTControlPointModel *anotherModel =
          [[LTControlPointModel alloc] initWithType:typeMock controlPoints:@[]];
      expect([model isEqual:anotherModel]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTControlPointModel *anotherModel =
          [[LTControlPointModel alloc] initWithType:typeMock controlPoints:controlPointMocks];
      expect(model.hash).to.equal(anotherModel.hash);
    });
  });
});

SpecEnd
