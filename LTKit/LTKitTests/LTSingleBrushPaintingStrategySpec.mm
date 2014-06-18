// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTSingleBrushPaintingStrategy.h"

#import "LTBrush.h"
#import "LTPainter.h"

SpecBegin(LTSingleBrushPaintingStrategy)

__block LTSingleBrushPaintingStrategy *strategy;
__block id brush;

beforeEach(^{
  brush = [OCMockObject niceMockForClass:[LTBrush class]];
});

afterEach(^{
  strategy = nil;
  brush = nil;
});

context(@"initialization", ^{
  it(@"should initialize with brush", ^{
    expect(^{
      strategy = [[LTSingleBrushPaintingStrategy alloc] initWithBrush:brush];
    }).notTo.raiseAny();
    expect(strategy.brush).to.beIdenticalTo(brush);
  });
  
  it(@"should raise when initializing without brush", ^{
    expect(^{
      strategy = [[LTSingleBrushPaintingStrategy alloc] initWithBrush:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"abstract", ^{
  beforeEach(^{
    strategy = [[LTSingleBrushPaintingStrategy alloc] initWithBrush:brush];
  });
  
  it(@"should raise on call to abstract paintingWillBeginWithPainter:", ^{
    id painter = [OCMockObject niceMockForClass:[LTPainter class]];
    expect(^{
      [strategy paintingWillBeginWithPainter:painter];
    }).to.raise(NSInternalInconsistencyException);
  });
  
  it(@"should raise on call to abstract paintingDirectionsForStartingProgress:endingProgress:", ^{
    expect(^{
      [strategy paintingDirectionsForStartingProgress:0 endingProgress:1];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SpecEnd
