// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewPixelGrid.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTGridDrawer.h"

@interface LTViewPixelGrid ()
@property (strong, nonatomic) LTGridDrawer *gridDrawer;
@end

SpecBegin(LTViewPixelGrid)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

const CGSize contentSize = CGSizeMake(256, 512);
const CGRect contentBounds = CGRectFromOriginAndSize(CGPointZero, contentSize);

context(@"properties", ^{
  __block LTViewPixelGrid *grid;
  
  beforeEach(^{
    grid = [[LTViewPixelGrid alloc] initWithContentSize:contentSize];
  });
  
  afterEach(^{
    grid = nil;
  });
  
  it(@"should set and clamp maxOpacity", ^{
    grid.maxOpacity = 0.1;
    expect(grid.maxOpacity).to.equal(0.1);
    grid.maxOpacity = 0.9;
    expect(grid.maxOpacity).to.equal(0.9);
    grid.maxOpacity = -0.1;
    expect(grid.maxOpacity).to.equal(0);
    grid.maxOpacity = 1.1;
    expect(grid.maxOpacity).to.equal(1);
  });
  
  it(@"should set and clamp minZoomScale", ^{
    grid.minZoomScale = 0.1;
    expect(grid.minZoomScale).to.equal(0.1);
    grid.minZoomScale = CGFLOAT_MAX;
    expect(grid.minZoomScale).to.equal(CGFLOAT_MAX);
    grid.minZoomScale = -0.1;
    expect(grid.minZoomScale).to.equal(0);
  });
  
  it(@"should set and clamp maxZoomScale", ^{
    grid.maxZoomScale = 0.1;
    expect(grid.maxZoomScale).to.equal(0.1);
    grid.maxZoomScale = CGFLOAT_MAX;
    expect(grid.maxZoomScale).to.equal(CGFLOAT_MAX);
    grid.maxZoomScale = -0.1;
    expect(grid.maxZoomScale).to.equal(0);
  });
  
  it(@"should set color", ^{
    expect(grid.color).notTo.equal([UIColor redColor]);
    grid.color = [UIColor redColor];
    expect(grid.color).to.equal([UIColor redColor]);
    grid.color = nil;
    expect(grid.color).to.beNil();
  });
});

context(@"drawing", ^{
  __block LTViewPixelGrid *grid;
  __block LTGridDrawer *realDrawer;
  __block id mockDrawer;
  const CGFloat kSmallValue = 0.01;
  
  beforeEach(^{
    grid = [[LTViewPixelGrid alloc] initWithContentSize:contentSize];
    //    drawer = mock([LTGridDrawer class]);
    realDrawer = grid.gridDrawer;
    mockDrawer = [OCMockObject partialMockForObject:realDrawer];
    grid.gridDrawer = mockDrawer;
    grid.minZoomScale = 2;
    grid.maxZoomScale = 4;
    grid.maxOpacity = 0.75;
  });
  
  afterEach(^{
    grid = nil;
    mockDrawer = nil;
    realDrawer = nil;
  });

  it(@"should use maxOpacity above the maximal zoom scale", ^{
    CGSize targetSize = contentSize * (grid.maxZoomScale + kSmallValue);
    [grid drawContentRegion:contentBounds toFramebufferWithSize:targetSize];
    expect([(LTGridDrawer *)mockDrawer opacity]).to.beCloseTo(grid.maxOpacity);
  });
  
  it(@"should use zero opacity if minimal and maximal zoom scales are equal", ^{
    grid.maxZoomScale = grid.minZoomScale;
    [grid drawContentRegion:contentBounds toFramebufferWithSize:contentSize * grid.minZoomScale];
    expect([(LTGridDrawer *)mockDrawer opacity]).to.equal(0);
  });
  
  it(@"should use zero opacity if minimal zoom scale is larger than the maximal zoom scale", ^{
    grid.maxZoomScale = 1;
    [grid drawContentRegion:contentBounds toFramebufferWithSize:contentSize * grid.minZoomScale];
    expect([(LTGridDrawer *)mockDrawer opacity]).to.equal(0);
  });
  
  it(@"should interpolate opacity according to the zoom scale", ^{
    const CGFloat ratio = 0.33;
    const CGFloat zoomScale = (grid.minZoomScale * (1 - ratio) + ratio * grid.maxZoomScale);
    [grid drawContentRegion:contentBounds toFramebufferWithSize:contentSize * zoomScale];
    expect([(LTGridDrawer *)mockDrawer opacity]).to.beCloseToWithin(ratio * grid.maxOpacity,
                                                                    kSmallValue);
  });
  
  it(@"should not draw grid below minimal zoom scale", ^{
    [[[mockDrawer reject] ignoringNonObjectArgs] drawSubGridInRegion:CGRectZero
                                         inScreenFramebufferWithSize:CGSizeZero];
    [grid drawContentRegion:contentBounds toFramebufferWithSize:contentSize];
    [mockDrawer verify];
  });
  
  it(@"should draw grid above the minimal zoom scale", ^{
    const CGSize targetSize = contentSize * (grid.minZoomScale + kSmallValue);
    [[mockDrawer expect] drawSubGridInRegion:contentBounds inScreenFramebufferWithSize:targetSize];
    [grid drawContentRegion:contentBounds toFramebufferWithSize:targetSize];
    [mockDrawer verify];
  });
  
  it(@"should draw grid above the maximal zoom scale", ^{
    const CGSize targetSize = contentSize * (grid.maxZoomScale + kSmallValue);
    [[mockDrawer expect] drawSubGridInRegion:contentBounds inScreenFramebufferWithSize:targetSize];
    [grid drawContentRegion:contentBounds toFramebufferWithSize:targetSize];
    [mockDrawer verify];
  });
});

SpecEnd
