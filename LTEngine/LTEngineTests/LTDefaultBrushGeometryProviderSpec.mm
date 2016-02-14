// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTDefaultBrushGeometryProvider.h"

#import "LTEuclideanSplineControlPoint.h"
#import "LTParameterizedObject.h"
#import "LTRotatedRect.h"

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
          [NSSet setWithArray:@[@instanceKeypath(LTEuclideanSplineControlPoint,
                                                 xCoordinateOfLocation),
                                @instanceKeypath(LTEuclideanSplineControlPoint,
                                                 yCoordinateOfLocation)]];
      OCMStub([parameterizedObjectMock parameterizationKeys]).andReturn(parameterizationKeys);

      LTParameterizationKeyToValues *mapping =
          @{@instanceKeypath(LTEuclideanSplineControlPoint, xCoordinateOfLocation): @[@0, @1],
            @instanceKeypath(LTEuclideanSplineControlPoint, yCoordinateOfLocation): @[@1, @2]};
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
      LTEuclideanSplineControlPoint *controlPoint =
          [[LTEuclideanSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(1, 2)];

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
