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
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:3 withSignalLength:3])
        .to.beCloseTo(3.0);
  });

  it(@"should apply boundary condition if outside signal", ^{
    // Left.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:-0.75 withSignalLength:3])
        .to.beCloseTo(0.75);

    // Right.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:3.5 withSignalLength:3])
        .to.beCloseTo(2.5);

    // Exactly one hop.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:6 withSignalLength:3])
        .to.beCloseTo(0);

    // More than one hop.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:6.5 withSignalLength:3])
        .to.beCloseTo(0.5);
  });

  it(@"should return correct values for signal length of 1", ^{
    // Inside.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:0.5 withSignalLength:1])
        .to.beCloseTo(0.5);

    // On the edge.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:1 withSignalLength:1])
        .to.beCloseTo(1);

    // Outside.
    expect([LTSymmetricBoundaryCondition boundaryConditionForPosition:2 withSignalLength:1])
        .to.beCloseTo(0);
  });
});

context(@"two-dimensions boundary condition", ^{
  it(@"should return same location if inside signal", ^{
    // Start.
    LTVector2 start = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:LTVector2(0, 0)
                        withSignalSize:CGSizeMake(3, 5)];
    expect(start.x).to.beCloseTo(0);
    expect(start.y).to.beCloseTo(0);

    // Middle.
    LTVector2 middle = [LTSymmetricBoundaryCondition
                         boundaryConditionForPoint:LTVector2(1.5, 3.5)
                         withSignalSize:CGSizeMake(3, 5)];
    expect(middle.x).to.beCloseTo(1.5);
    expect(middle.y).to.beCloseTo(3.5);

    // End.
    LTVector2 end = [LTSymmetricBoundaryCondition
                      boundaryConditionForPoint:LTVector2(3, 5)
                      withSignalSize:CGSizeMake(3, 5)];
    expect(end.x).to.beCloseTo(3);
    expect(end.y).to.beCloseTo(5);
  });

  it(@"should apply boundary condition if outside signal", ^{
    // Left.
    LTVector2 left = [LTSymmetricBoundaryCondition
                       boundaryConditionForPoint:LTVector2(-0.5, -0.75)
                       withSignalSize:CGSizeMake(3, 5)];
    expect(left.x).to.beCloseTo(0.5);
    expect(left.y).to.beCloseTo(0.75);

    // Right.
    LTVector2 right = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:LTVector2(4.5, 6)
                        withSignalSize:CGSizeMake(3, 5)];
    expect(right.x).to.beCloseTo(1.5);
    expect(right.y).to.beCloseTo(4);

    // Exactly one hop.
    LTVector2 exact = [LTSymmetricBoundaryCondition
                        boundaryConditionForPoint:LTVector2(6.0, 10.0)
                        withSignalSize:CGSizeMake(3, 5)];
    expect(exact.x).to.beCloseTo(0);
    expect(exact.y).to.beCloseTo(0);

    // More than one hop.
    LTVector2 hop = [LTSymmetricBoundaryCondition
                      boundaryConditionForPoint:LTVector2(4.5, 9.0)
                      withSignalSize:CGSizeMake(3, 5)];
    expect(hop.x).to.beCloseTo(1.5);
    expect(hop.y).to.beCloseTo(1);
  });
});

SpecEnd
