// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerParams.h"

#import "LTGLKitExtensions.h"

SpecBegin(LTShapeDrawerParams)

__block LTShapeDrawerParams *params;

afterEach(^{
  params = nil;
});

context(@"initialization", ^{
  it(@"should initialize", ^{
    expect(^{
      params = [[LTShapeDrawerParams alloc] init];
    }).notTo.raiseAny();
  });
});

context(@"properties", ^{
  __block LTShapeDrawerParams *otherParams;
  
  beforeEach(^{
    params = [[LTShapeDrawerParams alloc] init];
    otherParams = [[LTShapeDrawerParams alloc] init];
  });
  
  afterEach(^{
    otherParams = nil;
  });
  
  it(@"should be equal", ^{
    expect(params).notTo.beIdenticalTo(otherParams);
    expect(params).to.equal(otherParams);
  });
            
  it(@"should have default properties", ^{
    expect(params.lineWidth).to.equal(1);
    expect(params.shadowWidth).to.equal(0);
    expect(params.fillColor).to.equal(LTVector4::ones());
    expect(params.strokeColor).to.equal(LTVector4::ones());
    expect(params.shadowColor).to.equal(LTVector4(0, 0, 0, 1));
  });
  
  it(@"should update lineWidth", ^{
    CGFloat newValue = 2;
    expect(params.lineWidth).notTo.equal(newValue);
    params.lineWidth = newValue;
    expect(params.lineWidth).to.equal(newValue);
    expect(params).notTo.equal(otherParams);
  });
  
  it(@"should update shadowWidth", ^{
    CGFloat newValue = 1;
    expect(params.shadowWidth).notTo.equal(newValue);
    params.shadowWidth = newValue;
    expect(params.shadowWidth).to.equal(newValue);
    expect(params).notTo.equal(otherParams);
  });
  
  it(@"should update fillColor", ^{
    LTVector4 newValue = LTVector4::ones() * 0.5;
    expect(params.fillColor).notTo.equal(newValue);
    params.fillColor = newValue;
    expect(params.fillColor).to.equal(newValue);
    expect(params).notTo.equal(otherParams);
  });
  
  it(@"should update strokeColor", ^{
    LTVector4 newValue = LTVector4::ones() * 0.5;
    expect(params.strokeColor).notTo.equal(newValue);
    params.strokeColor = newValue;
    expect(params.strokeColor).to.equal(newValue);
    expect(params).notTo.equal(otherParams);
  });
  
  it(@"should update shadowColor", ^{
    LTVector4 newValue = LTVector4::ones() * 0.5;
    expect(params.shadowColor).notTo.equal(newValue);
    params.shadowColor = newValue;
    expect(params.shadowColor).to.equal(newValue);
    expect(params).notTo.equal(otherParams);
  });
  
  it(@"should return lineRadius", ^{
    params.lineWidth = 2;
    expect(params.lineRadius).to.beCloseTo(0.5 * params.lineWidth);
    params.lineWidth = 3;
    expect(params.lineRadius).to.beCloseTo(0.5 * params.lineWidth);
  });
  
  it(@"should copy", ^{
    params.lineWidth += 1;
    params.shadowWidth += 1;
    params.fillColor = LTVector4::ones() * 0.5;
    params.strokeColor = LTVector4::ones() * 0.5;
    params.shadowColor = LTVector4::ones() * 0.5;
    LTShapeDrawerParams *paramsCopy = [params copy];
    expect(paramsCopy).notTo.beIdenticalTo(params);
    expect(paramsCopy).to.equal(params);
  });
});

SpecEnd
