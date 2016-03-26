// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTriangle.h"

SpecBegin(LTTriangle)

__block CGPoint v0;
__block CGPoint v1;
__block CGPoint v2;

__block LTTriangle *triangle;

beforeAll(^{
  v0 = CGPointMake(0, 0);
  v1 = CGPointMake(1, 0);
  v2 = CGPointMake(1, 1);
});

context(@"initializers", ^{
  it(@"should initialize with corners", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    triangle = [[LTTriangle alloc] initWithCorners:corners];
    expect(triangle.v0).to.equal(v0);
    expect(triangle.v1).to.equal(v1);
    expect(triangle.v2).to.equal(v2);
  });

  it(@"should initialize with corners, ensuring clockwise order", ^{
    LTTriangleCorners corners{{v2, v1, v0}};
    triangle = [[LTTriangle alloc] initWithCorners:corners];
    expect(triangle.v0).to.equal(v0);
    expect(triangle.v1).to.equal(v1);
    expect(triangle.v2).to.equal(v2);
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion", ^{
    LTTriangleCorners corners{{v0, v1, v2}};
    triangle = [[LTTriangle alloc] initWithCorners:corners];
    expect([triangle containsPoint:v0]).to.beTruthy();
    expect([triangle containsPoint:(v0 + v1) / 2]).to.beTruthy();
    expect([triangle containsPoint:v1]).to.beTruthy();
    expect([triangle containsPoint:(v0 + v2) / 2 + CGPointMake(-0.125, 0)]).to.beFalsy();
    expect([triangle containsPoint:v2]).to.beTruthy();
    expect([triangle containsPoint:CGPointMake(0, 1)]).to.beFalsy();
  });
});

SpecEnd
