// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentLocationProvider.h"

#import <LTKitTests/LTEqualityExamples.h>

SpecBegin(LTContentLocationInfo)

context(@"initialization", ^{
  __block CGSize contentSize;
  __block CGFloat contentScaleFactor;
  __block UIEdgeInsets contentInset;
  __block CGRect visibleContentRect;
  __block CGFloat maxZoomScale;
  __block CGFloat zoomScale;

  beforeEach(^{
    contentSize = CGSizeMake(1, 2);
    contentScaleFactor = 3;
    contentInset = UIEdgeInsetsMake(4, 5, 6, 7);
    visibleContentRect = CGRectMake(8, 9, 10, 11);
    maxZoomScale = 12;
    zoomScale = 13;
  });

  it(@"should initialize correctly", ^{
    LTContentLocationInfo *info =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    expect(info.contentSize).to.equal(contentSize);
    expect(info.contentScaleFactor).to.equal(contentScaleFactor);
    expect(info.contentInset).to.equal(contentInset);
    expect(info.visibleContentRect).to.equal(visibleContentRect);
    expect(info.maxZoomScale).to.equal(maxZoomScale);
    expect(info.zoomScale).to.equal(zoomScale);
  });

  it(@"should initialize correctly with values of another content location provider", ^{
    id provider = OCMProtocolMock(@protocol(LTContentLocationProvider));
    OCMStub([provider contentSize]).andReturn(contentSize);
    OCMStub([provider contentScaleFactor]).andReturn(contentScaleFactor);
    OCMStub([provider contentInset]).andReturn(contentInset);
    OCMStub([provider visibleContentRect]).andReturn(visibleContentRect);
    OCMStub([provider maxZoomScale]).andReturn(maxZoomScale);
    OCMStub([provider zoomScale]).andReturn(zoomScale);
    LTContentLocationInfo *info =
        [[LTContentLocationInfo alloc] initWithValuesOfContentLocationProvider:provider];
    expect(info.contentSize).to.equal(contentSize);
    expect(info.contentScaleFactor).to.equal(contentScaleFactor);
    expect(info.contentInset).to.equal(contentInset);
    expect(info.visibleContentRect).to.equal(visibleContentRect);
    expect(info.maxZoomScale).to.equal(maxZoomScale);
    expect(info.zoomScale).to.equal(zoomScale);
  });

  itShouldBehaveLike(kLTEqualityExamples, ^{
    LTContentLocationInfo *info =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *equalInfo =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentContentSize =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize + CGSizeMakeUniform(1)
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentContentScaleFactor =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor + 1
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentContentInset =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:UIEdgeInsetsMake(1, 2, 3, 4)
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentVisibleContentRect =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:CGRectMake(0, 1, 2, 3)
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentMaxZoomScale =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale + 1 zoomScale:zoomScale];
    LTContentLocationInfo *infoWithDifferentZoomScale =
        [[LTContentLocationInfo alloc] initWithContentSize:contentSize
                                        contentScaleFactor:contentScaleFactor
                                              contentInset:contentInset
                                        visibleContentRect:visibleContentRect
                                              maxZoomScale:maxZoomScale zoomScale:zoomScale + 1];
    return @{
      kLTEqualityExamplesObject: info,
      kLTEqualityExamplesEqualObject: equalInfo,
      kLTEqualityExamplesDifferentObjects: @[
          infoWithDifferentContentSize,
          infoWithDifferentContentScaleFactor,
          infoWithDifferentContentInset,
          infoWithDifferentVisibleContentRect,
          infoWithDifferentMaxZoomScale,
          infoWithDifferentZoomScale
      ]
    };
  });
});

SpecEnd
