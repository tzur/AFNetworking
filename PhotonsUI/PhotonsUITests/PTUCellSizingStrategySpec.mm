// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCellSizingStrategy.h"

SpecBegin(PTUCellSizingStrategy)

context(@"factory", ^{
  it(@"should return correct constant resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy constant:CGSizeMake(10, 20)];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.equal(CGSizeMake(10, 20));

    expect([strategy isKindOfClass:[PTUConstantCellSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct adaptiveFitRow resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(22, 22)
                                                                  maximumScale:1.25];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(24.25, 24.25), 0.1);

    expect([strategy isKindOfClass:[PTUAdaptiveCellSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct adaptiveFitColumn resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(22, 22)
                                                                  maximumScale:1.25];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(24.25, 24.25), 0.1);

    expect([strategy isKindOfClass:[PTUAdaptiveCellSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct rowWithHeight resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy rowWithHeight:30];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(100, 30), 0.1);

    expect([strategy isKindOfClass:[PTURowSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct rowWithWidthRatio resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy rowWithWidthRatio:0.3];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(100, 30), 0.1);

    expect([strategy isKindOfClass:[PTUDynamicRowSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct gridWithItemsPerRow resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy gridWithItemsPerRow:4];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.equal(CGSizeMake(24.25, 24.25));

    expect([strategy isKindOfClass:[PTUGridSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct gridWithItemsPerColumn resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy gridWithItemsPerColumn:8];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.equal(CGSizeMake(23.25, 23.25));

    expect([strategy isKindOfClass:[PTUGridSizingStrategy class]]).to.beTruthy();
  });
});

context(@"PTUConstantCellSizingStrategy", ^{
  it(@"should return the same size", ^{
    CGSize size = CGSizeMake(10, 20);
    id<PTUCellSizingStrategy> strategy = [[PTUConstantCellSizingStrategy alloc]
        initWithSize:CGSizeMake(10, 20)];

    expect([strategy cellSizeForViewSize:CGSizeMake(1, 1) itemSpacing:1.0 lineSpacing:1.0])
        .to.equal(size);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:1.0])
        .to.equal(size);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:4.0 lineSpacing:7.0])
        .to.equal(size);
  });
});

context(@"PTUAdaptiveCellSizingStrategy", ^{
  it(@"should correctly adapt to width", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
        initMatchingWidthWithSize:CGSizeMake(20, 10) maximumScale:1.25];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
        .to.equal(CGSizeMake(20, 10));
    expect([strategy cellSizeForViewSize:CGSizeMake(45, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(22, 11), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(46, 100) itemSpacing:2.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(22, 11), 0.1);
  });

  it(@"should correctly adapt to height", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
        initMatchingHeightWithSize:CGSizeMake(20, 10) maximumScale:1.25];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
        .to.equal(CGSizeMake(20, 10));
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 25) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(24, 12), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 119) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(22, 11), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 26) itemSpacing:0.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(24, 12), 0.1);
  });

  it(@"should return original size when can't adapt to width", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
        initMatchingWidthWithSize:CGSizeMake(20, 10) maximumScale:1.25];

    expect([strategy cellSizeForViewSize:CGSizeMake(30, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(10, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
  });

  it(@"should return original size when can't adapt to height", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
        initMatchingHeightWithSize:CGSizeMake(20, 10) maximumScale:1.25];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 15) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 5) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
  });
});

context(@"PTURowSizingStrategy", ^{
  it(@"should correctly size rows", ^{
    id<PTUCellSizingStrategy> strategy = [[PTURowSizingStrategy alloc] initWithHeight:20];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(200, 20), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 100) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(100, 20), 0.1);
  });
});

context(@"PTUDynamicRowSizingStrategy", ^{
  it(@"should correctly size rows with ratio of less than 1", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUDynamicRowSizingStrategy alloc]
       initWithWidthRatio:0.5];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(200, 100), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 100) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(100, 50), 0.1);
  });

  it(@"should correctly size rows with ratio of more than 1", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUDynamicRowSizingStrategy alloc]
       initWithWidthRatio:1.25];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(200, 250), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 100) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(100, 125), 0.1);
  });
});

context(@"PTUGridSizingStrategy", ^{
  it(@"should correctly size when matching width", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUGridSizingStrategy alloc] initWithItemsPerRow:4];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(50, 50), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 100) itemSpacing:0.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(25, 25), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 100) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(24.25, 24.25), 0.1);
  });

  it(@"should correctly size when matching height", ^{
    id<PTUCellSizingStrategy> strategy = [[PTUGridSizingStrategy alloc] initWithItemsPerColumn:4];

    expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(25, 25), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 200) itemSpacing:1.0 lineSpacing:0.0])
        .to.beCloseToPointWithin(CGSizeMake(50, 50), 0.1);
    expect([strategy cellSizeForViewSize:CGSizeMake(200, 200) itemSpacing:1.0 lineSpacing:1.0])
        .to.beCloseToPointWithin(CGSizeMake(49.25, 49.25), 0.1);
  });
});

SpecEnd
