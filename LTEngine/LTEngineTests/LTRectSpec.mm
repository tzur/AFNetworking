// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRect.h"

#import "LTCGExtensions.h"

SpecBegin(LTRect)

context(@"initialization", ^{
  it(@"should initailize null rectangle", ^{
    LTRect rect;
    expect(CGRectIsNull(rect)).to.beTruthy();
  });
  
  it(@"should initialize from cgrect", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect).to.equal(CGRectMake(1, 2, 3, 4));
  });
  
  it(@"should initialize from origin and size", ^{
    LTRect rect(CGPointMake(1, 2), CGSizeMake(3, 4));
    expect(rect).to.equal(CGRectMake(1, 2, 3, 4));
  });
  
  it(@"should initialize from corners", ^{
    LTRect rect(CGPointMake(1, 2), CGPointMake(3, 4));
    expect(rect).to.equal(CGRectMake(1, 2, 2, 2));
  });
  
  it(@"should initialize from x, y, width, height", ^{
    LTRect rect(1, 2, 3, 4);
    expect(rect).to.equal(CGRectMake(1, 2, 3, 4));
  });
});

context(@"casting", ^{
  it(@"should cast to cgrect", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    CGRect castedRect = rect;
    expect(castedRect).to.equal(CGRectMake(1, 2, 3, 4));
  });
});

context(@"getters", ^{
  it(@"should return rect", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect.rect()).to.equal(CGRectMake(1, 2, 3, 4));
  });
  
  it(@"should return edges", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect.top()).to.equal(2);
    expect(rect.left()).to.equal(1);
    expect(rect.right()).to.equal(4);
    expect(rect.bottom()).to.equal(6);
  });
  
  it(@"should return corners", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect.topLeft()).to.equal(CGPointMake(1, 2));
    expect(rect.topRight()).to.equal(CGPointMake(4, 2));
    expect(rect.bottomLeft()).to.equal(CGPointMake(1, 6));
    expect(rect.bottomRight()).to.equal(CGPointMake(4, 6));
  });
  
  it(@"should return center", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect.center()).to.beCloseToPoint(CGPointMake(2.5, 4));
  });
  
  it(@"should return aspect ratio", ^{
    LTRect rect(CGRectMake(1, 2, 3, 4));
    expect(rect.aspectRatio()).to.beCloseTo(3.0 / 4.0);
  });
});

SpecEnd
