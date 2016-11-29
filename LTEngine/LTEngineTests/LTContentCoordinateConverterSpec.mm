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

static const CGFloat kEpsilon = 1e-14;

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    expect(converter).toNot.beNil();
  });
});

context(@"conversion", ^{
  it(@"should convert points from pixel content to point presentation coordinate system", ^{
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
    expect(convertedPoint).to.beCloseToPointWithin(CGPointMake(25, 100 / 3.0), kEpsilon);

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    convertedPoint =
        [converter convertPointFromContentToPresentationCoordinates:CGPointZero];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 10));
  });

  it(@"should convert points from pixel content to pixel presentation coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGPoint convertedPoint =
        [converter convertPointFromContentToPixelPresentationCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    convertedPoint =
        [converter convertPointFromContentToPixelPresentationCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(1, 2));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    convertedPoint =
        [converter convertPointFromContentToPixelPresentationCoordinates:CGPointMake(250, 400)];
    expect(convertedPoint).to.beCloseToPointWithin(CGPointMake(75, 100), kEpsilon);

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    convertedPoint =
        [converter convertPointFromContentToPixelPresentationCoordinates:CGPointZero];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 20));
  });

  it(@"should convert points from point presentation to pixel content coordinate system", ^{
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
    expect(convertedPoint).to.beCloseToPoint(CGPointZero);
  });

  it(@"should convert points from pixel presentation to pixel content coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGPoint convertedPoint =
        [converter convertPointFromPixelPresentationToContentCoordinates:CGPointMake(2, 3)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    convertedPoint =
        [converter convertPointFromPixelPresentationToContentCoordinates:CGPointMake(1, 2)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    convertedPoint =
        [converter
         convertPointFromPixelPresentationToContentCoordinates:CGPointMake(25, 100 / 3.0)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(150, 200 + 200 / 3.0));

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    convertedPoint =
        [converter convertPointFromPixelPresentationToContentCoordinates:CGPointMake(0, 10)];
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, -50));
  });
});

context(@"transform", ^{
  it(@"should provide transform from content pixel to presentation point coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGAffineTransform transform = converter.contentToPresentationCoordinateTransform;
    CGPoint convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    transform = converter.contentToPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(1, 2));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    transform = converter.contentToPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(250, 400), transform);
    expect(convertedPoint).to.beCloseToPointWithin(CGPointMake(25, 100 / 3.0), kEpsilon);

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    transform = converter.contentToPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointZero, transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 10));
  });

  it(@"should provide transform from content pixel to presentation pixel coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGAffineTransform transform = converter.contentToPixelPresentationCoordinateTransform;
    CGPoint convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    transform = converter.contentToPixelPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(1, 2));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    transform = converter.contentToPixelPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(250, 400), transform);
    expect(convertedPoint).to.beCloseToPointWithin(CGPointMake(75, 100), kEpsilon);

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    transform = converter.contentToPixelPresentationCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointZero, transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, 20));
  });

  it(@"should provide transform from presentation point to content pixel coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGAffineTransform transform = converter.presentationToContentCoordinateTransform;
    CGPoint convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    transform = converter.presentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(1, 2), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    transform = converter.presentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(25, 100 / 3.0), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(250, 400));

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    transform = converter.presentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(0, 10), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointZero);
  });

  it(@"should provide transform from presentation pixel to content pixel coordinate system", ^{
    LTContentCoordinateConverter *converter = LTTestConverter(CGRectMake(0, 0, 1, 1), 1, 1);
    CGAffineTransform transform = converter.pixelPresentationToContentCoordinateTransform;
    CGPoint convertedPoint = CGPointApplyAffineTransform(CGPointMake(2, 3), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(1, 1, 1, 1), 1, 1);
    transform = converter.pixelPresentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(1, 2), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(2, 3));

    converter = LTTestConverter(CGRectMake(100, 200, 300, 400), 0.5, 3);
    transform = converter.pixelPresentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(25, 100 / 3.0), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(150, 200 + 200 / 3.0));

    converter = LTTestConverter(CGRectMake(0, -100, 300, 400), 0.2, 2);
    transform = converter.pixelPresentationToContentCoordinateTransform;
    convertedPoint = CGPointApplyAffineTransform(CGPointMake(0, 10), transform);
    expect(convertedPoint).to.beCloseToPoint(CGPointMake(0, -50));
  });
});

SpecEnd
