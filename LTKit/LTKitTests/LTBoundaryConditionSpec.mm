// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBoundaryCondition.h"

SpecBegin(LTSymmetricBoundaryCondition)

context(@"one-dimension boundary condition", ^{
  it(@"should return same location if inside signal", ^{
    // Start.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:0 withSignalLength:3])
        .to.beCloseTo(0);

    // Middle.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:0.5 withSignalLength:3])
        .to.beCloseTo(0.5);

    // End.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:2.0 withSignalLength:3])
        .to.beCloseTo(2.0);
  });

  it(@"should apply boundary condition if outside signal", ^{
    // Left.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:-0.75 withSignalLength:3])
        .to.beCloseTo(0.75);

    // Right.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:3.5 withSignalLength:3])
        .to.beCloseTo(0.5);

    // Exactly one hop.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:4.0 withSignalLength:3])
        .to.beCloseTo(0.0);

    // More than one hop.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:5.5 withSignalLength:3])
        .to.beCloseTo(1.5);
  });
});

context(@"two-dimensions boundary condition", ^{
  it(@"should return same location if inside signal", ^{
    // Start.
    GLKVector2 start = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:GLKVector2Make(0, 0)
                        withSignalSize:cv::Size2i(3, 5)];
    expect(start.x).to.beCloseTo(0);
    expect(start.y).to.beCloseTo(0);

    // Middle.
    GLKVector2 middle = [LTSymmetricBoundaryCondition
                         boundaryConditionForPoint:GLKVector2Make(1.5, 3.5)
                         withSignalSize:cv::Size2i(3, 5)];
    expect(middle.x).to.beCloseTo(1.5);
    expect(middle.y).to.beCloseTo(3.5);

    // End.
    GLKVector2 end = [LTSymmetricBoundaryCondition
                      boundaryConditionForPoint:GLKVector2Make(2.0, 4.0)
                      withSignalSize:cv::Size2i(3, 5)];
    expect(end.x).to.beCloseTo(2.0);
    expect(end.y).to.beCloseTo(4.0);
  });

  it(@"should apply boundary condition if outside signal", ^{
    // Left.
    GLKVector2 left = [LTSymmetricBoundaryCondition
                       boundaryConditionForPoint:GLKVector2Make(-0.5, -0.75)
                       withSignalSize:cv::Size2i(3, 5)];
    expect(left.x).to.beCloseTo(0.5);
    expect(left.y).to.beCloseTo(0.75);

    // Right.
    GLKVector2 right = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:GLKVector2Make(4.5, 6)
                        withSignalSize:cv::Size2i(3, 5)];
    expect(right.x).to.beCloseTo(0.5);
    expect(right.y).to.beCloseTo(2.0);

    // Exactly one hop.
    GLKVector2 exact = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:GLKVector2Make(4.0, 8.0)
                        withSignalSize:cv::Size2i(3, 5)];
    expect(exact.x).to.beCloseTo(0);
    expect(exact.y).to.beCloseTo(0);

    // More than one hop.
    GLKVector2 hop = [LTSymmetricBoundaryCondition
                      boundaryConditionForPoint:GLKVector2Make(4.5, 9.0)
                      withSignalSize:cv::Size2i(3, 5)];
    expect(hop.x).to.beCloseTo(0.5);
    expect(hop.y).to.beCloseTo(1);
  });
});

SpecEnd
