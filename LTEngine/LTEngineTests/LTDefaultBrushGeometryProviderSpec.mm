// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDefaultBrushGeometryProvider.h"

#import "LTParameterizationKeyToValues.h"
#import "LTParameterizedObject.h"
#import "LTRotatedRect.h"
#import "LTSplineControlPoint.h"

SpecBegin(LTDefaultBrushGeometryProvider)

__block LTDefaultBrushGeometryProvider *provider;

beforeEach(^{
  provider = [[LTDefaultBrushGeometryProvider alloc] initWithEdgeLength:10];
});

context(@"initialization", ^{
  it(@"should initialize the provided edge length", ^{
    expect(provider.edgeLength).to.equal(10);
  });
});

context(@"LTContinuousParametricValueProviderModel protocol", ^{
    it(@"should return itself as provider, due to immutability", ^{
    expect([provider provider]).to.beIdenticalTo(provider);
  });
});

context(@"LTContinuousParametricValueProvider protocol", ^{
  context(@"providing rotated rects", ^{
    it(@"should provide rotated rects for samples of a parameterized object", ^{
      id parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));

      NSSet<NSString *> *parameterizationKeys =
          [NSSet setWithArray:@[@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation),
                                @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)]];
      OCMStub([parameterizedObjectMock parameterizationKeys]).andReturn(parameterizationKeys);

      NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[
        @instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation),
        @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)
      ]];
      cv::Mat1g values = (cv::Mat1g(2, 2) << 0, 1, 1, 2);

      LTParameterizationKeyToValues *mapping =
          [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:values];

      OCMStub([[parameterizedObjectMock ignoringNonObjectArgs] mappingForParametricValues:{}])
          .andReturn(mapping);

      NSArray<LTRotatedRect *> *rotatedRects =
          [provider rotatedRectsFromParameterizedObject:parameterizedObjectMock
                                     atParametricValues:{0, 1}];

      expect(rotatedRects).to.haveACountOf(2);
      expect(rotatedRects[0]).to.equal([LTRotatedRect rectWithCenter:CGPointMake(0, 1)
                                                                size:CGSizeMakeUniform(10)
                                                               angle:0]);
      expect(rotatedRects[1]).to.equal([LTRotatedRect rectWithCenter:CGPointMake(1, 2)
                                                                size:CGSizeMakeUniform(10)
                                                               angle:0]);
    });

    it(@"should provide a rotated rect for a Euclidean spline control point", ^{
      LTSplineControlPoint *controlPoint =
          [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(1, 2)];

      LTRotatedRect *rotatedRect = [provider rotatedRectFromControlPoint:controlPoint];

      expect(rotatedRect).to.equal([LTRotatedRect rectWithCenter:CGPointMake(1, 2)
                                                            size:CGSizeMakeUniform(10) angle:0]);
    });
  });

  context(@"model extraction", ^{
    it(@"should return itself as model, due to immutability", ^{
      expect([provider currentModel]).to.beIdenticalTo(provider);
    });
  });
});

SpecEnd
