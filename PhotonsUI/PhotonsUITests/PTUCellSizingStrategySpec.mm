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
                                                                  maximumScale:1.25
                                                           preserveAspectRatio:YES];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(24.25, 24.25), 0.1);

    expect([strategy isKindOfClass:[PTUAdaptiveCellSizingStrategy class]]).to.beTruthy();
  });

  it(@"should return correct adaptiveFitColumn resizing strategy", ^{
    id<PTUCellSizingStrategy> strategy = [PTUCellSizingStrategy adaptiveFitColumn:CGSizeMake(22, 22)
                                                                     maximumScale:1.25
                                                              preserveAspectRatio:NO];
    expect([strategy cellSizeForViewSize:CGSizeMake(100, 200) itemSpacing:1.0 lineSpacing:2.0])
        .to.beCloseToPointWithin(CGSizeMake(22, 23.25), 0.1);

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

  context(@"equality", ^{
    __block PTUConstantCellSizingStrategy *firstStrategy;
    __block PTUConstantCellSizingStrategy *secondStrategy;
    __block PTUConstantCellSizingStrategy *otherStrategy;

    beforeEach(^{
      firstStrategy = [[PTUConstantCellSizingStrategy alloc] initWithSize:CGSizeMake(20, 10)];
      secondStrategy = [[PTUConstantCellSizingStrategy alloc] initWithSize:CGSizeMake(20, 10)];
      otherStrategy = [[PTUConstantCellSizingStrategy alloc] initWithSize:CGSizeMake(10, 5)];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstStrategy).to.equal(secondStrategy);
      expect(secondStrategy).to.equal(firstStrategy);

      expect(firstStrategy).notTo.equal(otherStrategy);
      expect(secondStrategy).notTo.equal(otherStrategy);
    });

    it(@"should create proper hash", ^{
      expect(firstStrategy.hash).to.equal(secondStrategy.hash);
    });
  });
});

context(@"PTUAdaptiveCellSizingStrategy", ^{
  context(@"greater than one scaling", ^{
    it(@"should correctly adapt to width maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:YES preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(45, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(22, 11), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(46, 100) itemSpacing:2.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(22, 11), 0.1);
    });

    it(@"should correctly adapt to height maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:NO preserveAspectRatio:YES];

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

    it(@"should correctly adapt to width without maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:YES preserveAspectRatio:NO];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(45, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(22, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(46, 100) itemSpacing:2.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(22, 10), 0.1);
    });

    it(@"should correctly adapt to height without maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:NO preserveAspectRatio:NO];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 25) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 12), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 119) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 11), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 26) itemSpacing:0.0 lineSpacing:2.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 12), 0.1);
    });

    it(@"should return original size when can't adapt to width", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:YES preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(30, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(10, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    });

    it(@"should return original size when can't adapt to height", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:NO preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 15) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 5) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    });
  });

  context(@"less than one scaling", ^{
    it(@"should correctly adapt to width maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:YES preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(35, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(17, 8.5), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(34, 100) itemSpacing:2.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(16, 8), 0.1);
    });

    it(@"should correctly adapt to height maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:NO preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 17) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(16, 8), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 99) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(18, 9), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 18) itemSpacing:0.0 lineSpacing:2.0])
          .to.beCloseToPointWithin(CGSizeMake(16, 8), 0.1);
    });

    it(@"should correctly adapt to width without maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:YES preserveAspectRatio:NO];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(35, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(17, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(34, 100) itemSpacing:2.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(16, 10), 0.1);
    });

    it(@"should correctly adapt to height without maintaining apsect ratio", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:NO preserveAspectRatio:NO];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 100) itemSpacing:0.0 lineSpacing:0.0])
          .to.equal(CGSizeMake(20, 10));
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 17) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 8), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 99) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 9), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 18) itemSpacing:0.0 lineSpacing:2.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 8), 0.1);
    });

    it(@"should return original size when can't adapt to width", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:YES preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(30, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(10, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(20, 100) itemSpacing:1.0 lineSpacing:0.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    });

    it(@"should return original size when can't adapt to height", ^{
      id<PTUCellSizingStrategy> strategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:0.75 matchWidth:NO preserveAspectRatio:YES];

      expect([strategy cellSizeForViewSize:CGSizeMake(200, 15) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 5) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
      expect([strategy cellSizeForViewSize:CGSizeMake(200, 10) itemSpacing:0.0 lineSpacing:1.0])
          .to.beCloseToPointWithin(CGSizeMake(20, 10), 0.1);
    });
  });

  context(@"equality", ^{
    __block PTUAdaptiveCellSizingStrategy *firstStrategy;
    __block PTUAdaptiveCellSizingStrategy *secondStrategy;
    __block PTUAdaptiveCellSizingStrategy *otherStrategy;

    beforeEach(^{
      firstStrategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:NO preserveAspectRatio:YES];
      secondStrategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 10) maximumScale:1.25 matchWidth:NO preserveAspectRatio:YES];
      otherStrategy = [[PTUAdaptiveCellSizingStrategy alloc]
          initWithSize:CGSizeMake(20, 15) maximumScale:1.4 matchWidth:NO preserveAspectRatio:YES];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstStrategy).to.equal(secondStrategy);
      expect(secondStrategy).to.equal(firstStrategy);

      expect(firstStrategy).notTo.equal(otherStrategy);
      expect(secondStrategy).notTo.equal(otherStrategy);
    });

    it(@"should create proper hash", ^{
      expect(firstStrategy.hash).to.equal(secondStrategy.hash);
    });
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

  context(@"equality", ^{
    __block PTURowSizingStrategy *firstStrategy;
    __block PTURowSizingStrategy *secondStrategy;
    __block PTURowSizingStrategy *otherStrategy;

    beforeEach(^{
      firstStrategy = [[PTURowSizingStrategy alloc] initWithHeight:20];
      secondStrategy = [[PTURowSizingStrategy alloc] initWithHeight:20];
      otherStrategy = [[PTURowSizingStrategy alloc] initWithHeight:25];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstStrategy).to.equal(secondStrategy);
      expect(secondStrategy).to.equal(firstStrategy);

      expect(firstStrategy).notTo.equal(otherStrategy);
      expect(secondStrategy).notTo.equal(otherStrategy);
    });

    it(@"should create proper hash", ^{
      expect(firstStrategy.hash).to.equal(secondStrategy.hash);
    });
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

  context(@"equality", ^{
    __block PTUDynamicRowSizingStrategy *firstStrategy;
    __block PTUDynamicRowSizingStrategy *secondStrategy;
    __block PTUDynamicRowSizingStrategy *otherStrategy;

    beforeEach(^{
      firstStrategy = [[PTUDynamicRowSizingStrategy alloc] initWithWidthRatio:0.5];
      secondStrategy = [[PTUDynamicRowSizingStrategy alloc] initWithWidthRatio:0.5];
      otherStrategy = [[PTUDynamicRowSizingStrategy alloc] initWithWidthRatio:0.2];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstStrategy).to.equal(secondStrategy);
      expect(secondStrategy).to.equal(firstStrategy);

      expect(firstStrategy).notTo.equal(otherStrategy);
      expect(secondStrategy).notTo.equal(otherStrategy);
    });

    it(@"should create proper hash", ^{
      expect(firstStrategy.hash).to.equal(secondStrategy.hash);
    });
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

  context(@"equality", ^{
    __block PTUGridSizingStrategy *firstStrategy;
    __block PTUGridSizingStrategy *secondStrategy;
    __block PTUGridSizingStrategy *otherStrategy;

    beforeEach(^{
      firstStrategy = [[PTUGridSizingStrategy alloc] initWithItemsPerRow:4];
      secondStrategy = [[PTUGridSizingStrategy alloc] initWithItemsPerRow:4];
      otherStrategy = [[PTUGridSizingStrategy alloc] initWithItemsPerRow:3];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstStrategy).to.equal(secondStrategy);
      expect(secondStrategy).to.equal(firstStrategy);

      expect(firstStrategy).notTo.equal(otherStrategy);
      expect(secondStrategy).notTo.equal(otherStrategy);
    });

    it(@"should create proper hash", ^{
      expect(firstStrategy.hash).to.equal(secondStrategy.hash);
    });
  });
});

SpecEnd
