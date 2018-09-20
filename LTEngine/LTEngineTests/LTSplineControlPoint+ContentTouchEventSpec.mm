// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint+ContentTouchEvent.h"

#import "LTSplineControlPoint+AttributeKeys.h"

SpecBegin(LTSplineControlPoint_ContentTouchEvent)

static const NSTimeInterval kTimestamp = 1;
static const NSTimeInterval kOtherTimestamp = 2;
static const CGPoint kContentLocation = CGPointMake(1, 2);
static const CGPoint kOtherContentLocation = CGPointMake(3, 4);
static const CGFloat kMajorContentRadius = 5;
static const CGFloat kOtherMajorContentRadius = 6;
static const NSNumber *kSpeedInViewCoordinates = @7;
static const NSNumber *kOtherSpeedInViewCoordinates = @8;
static const NSNumber *kForce = @9;
static const NSNumber *kOtherForce = @10;

__block id<LTContentTouchEvent> contentTouchEventMock;
__block id<LTContentTouchEvent> otherContentTouchEventMock;
__block NSArray<id<LTContentTouchEvent>> *contentTouchEvents;

beforeEach(^{
  contentTouchEventMock = OCMProtocolMock(@protocol(LTContentTouchEvent));
  otherContentTouchEventMock = OCMProtocolMock(@protocol(LTContentTouchEvent));
  OCMStub([contentTouchEventMock timestamp]).andReturn(kTimestamp);
  OCMStub([otherContentTouchEventMock timestamp]).andReturn(kOtherTimestamp);
  OCMStub([contentTouchEventMock contentLocation]).andReturn(kContentLocation);
  OCMStub([otherContentTouchEventMock contentLocation]).andReturn(kOtherContentLocation);
  OCMStub([contentTouchEventMock majorContentRadius]).andReturn(kMajorContentRadius);
  OCMStub([otherContentTouchEventMock majorContentRadius]).andReturn(kOtherMajorContentRadius);
  OCMStub([contentTouchEventMock speedInViewCoordinates]).andReturn(kSpeedInViewCoordinates);
  OCMStub([otherContentTouchEventMock speedInViewCoordinates])
      .andReturn(kOtherSpeedInViewCoordinates);
  contentTouchEvents = @[contentTouchEventMock, otherContentTouchEventMock];
});

afterEach(^{
  contentTouchEvents = nil;
});

it(@"should convert content touch events to control points", ^{
  NSArray<LTSplineControlPoint *> *controlPoints =
      [LTSplineControlPoint pointsFromTouchEvents:contentTouchEvents];

  expect(controlPoints).toNot.beNil();
  expect(controlPoints).to.haveCountOf(2);
  LTSplineControlPoint *firstControlPoint = controlPoints.firstObject;
  LTSplineControlPoint *secondControlPoint = controlPoints.lastObject;
  expect(firstControlPoint.timestamp).to.equal(kTimestamp);
  expect(firstControlPoint.location).to.equal(kContentLocation);
  expect(firstControlPoint.attributes).to.haveACountOf(2);
  expect(firstControlPoint.attributes[[LTSplineControlPoint keyForRadius]])
      .to.equal(@(kMajorContentRadius));
  expect(firstControlPoint.attributes[[LTSplineControlPoint keyForSpeedInScreenCoordinates]])
      .to.equal(kSpeedInViewCoordinates);

  expect(secondControlPoint.timestamp).to.equal(kOtherTimestamp);
  expect(secondControlPoint.location).to.equal(kOtherContentLocation);
  expect(secondControlPoint.attributes).to.haveACountOf(2);
  expect(secondControlPoint.attributes[[LTSplineControlPoint keyForRadius]])
      .to.equal(@(kOtherMajorContentRadius));
  expect(secondControlPoint.attributes[[LTSplineControlPoint keyForSpeedInScreenCoordinates]])
      .to.equal(kOtherSpeedInViewCoordinates);
});

it(@"should convert content touch events to control points with force value", ^{
  OCMStub([contentTouchEventMock force]).andReturn(kForce);
  OCMStub([otherContentTouchEventMock force]).andReturn(kOtherForce);

  NSArray<LTSplineControlPoint *> *controlPoints =
      [LTSplineControlPoint pointsFromTouchEvents:contentTouchEvents];

  expect(controlPoints).toNot.beNil();
  expect(controlPoints).to.haveCountOf(2);
  LTSplineControlPoint *firstControlPoint = controlPoints.firstObject;
  LTSplineControlPoint *secondControlPoint = controlPoints.lastObject;
  expect(firstControlPoint.attributes).to.haveACountOf(3);
  expect(firstControlPoint.attributes[[LTSplineControlPoint keyForForce]])
      .to.equal(kForce);
  expect(secondControlPoint.attributes).to.haveACountOf(3);
  expect(secondControlPoint.attributes[[LTSplineControlPoint keyForForce]])
      .to.equal(kOtherForce);
});

SpecEnd
