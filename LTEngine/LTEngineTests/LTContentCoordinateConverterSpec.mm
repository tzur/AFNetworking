// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentCoordinateConverter.h"

#import "LTContentLocationProvider.h"

static LTContentCoordinateConverter *LTTestConverter(CGRect visibleContentRect, CGFloat zoomScale,
                                                     CGFloat contentScaleFactor) {
  id<LTContentLocationProvider> locationProviderMock =
      OCMProtocolMock(@protocol(LTContentLocationProvider));
  OCMStub([locationProviderMock visibleContentRect]).andReturn(visibleContentRect);
  OCMStub([locationProviderMock zoomScale]).andReturn(zoomScale);
  OCMStub([locationProviderMock contentScaleFactor]).andReturn(contentScaleFactor);
  return [[LTContentCoordinateConverter alloc] initWithLocationProvider:locationProviderMock];
}

SpecBegin(LTContentCoordinateConverter)

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    expect(converter).toNot.beNil();
  });
});

context(@"conversion", ^{
  it(@"should convert points from content coordinate system to presentation coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGPoint convertedPoint =
        [converter convertPointFromContentToPresentationCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    convertedPoint =
        [converter convertPointFromContentToPresentationCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(1, 2));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    convertedPoint =
        [converter convertPointFromContentToPresentationCoordinates:CGPointMake(250, 400)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(25, 100 / 3.0));

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    convertedPoint =
        [converter convertPointFromContentToPresentationCoordinates:CGPointMake(0, 0)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 10));
  });

  it(@"should convert points from presentation coordinate system to content coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGPoint convertedPoint =
        [converter convertPointFromPresentationToContentCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    convertedPoint = [converter convertPointFromPresentationToContentCoordinates:CGPointMake(1, 2)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    convertedPoint =
        [converter convertPointFromPresentationToContentCoordinates:CGPointMake(25, 100 / 3.0)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(250, 400));

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    convertedPoint =
        [converter convertPointFromPresentationToContentCoordinates:CGPointMake(0, 10)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 0));
  });
});

SpecEnd
