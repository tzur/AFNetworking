// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIPreviewViewModel.h"

#import "CUIFocusIconMode.h"

@interface CAMDeviceStub () <CUIPreviewDevice>
@end

SpecBegin(CUIPreviewViewModel)

__block CAMDeviceStub *deviceStub;
__block RACSubject *previewSignal;
__block CUIPreviewViewModel *previewViewModel;
__block RACSubject *subjectAreaChanged;
__block RACSubject *usePreviewLayerSignal;
__block CALayer *deviceLayer;

beforeEach(^{
  deviceStub = [[CAMDeviceStub alloc] init];
  previewSignal = [RACSubject subject];
  deviceLayer = [CALayer layer];
  deviceStub.previewLayer = deviceLayer;
  subjectAreaChanged = [RACSubject subject];
  deviceStub.subjectAreaChanged = subjectAreaChanged;
  usePreviewLayerSignal = [RACSubject subject];
  previewViewModel = [[CUIPreviewViewModel alloc] initWithDevice:deviceStub
                                                   previewSignal:previewSignal
                                           usePreviewLayerSignal:usePreviewLayerSignal];
});

context(@"preview properties initialization", ^{
  it(@"should initialize correctly", ^{
    expect(previewViewModel.usePreviewLayer).to.beFalsy();
    expect(previewViewModel.previewLayer).to.equal(deviceLayer);
    expect(previewViewModel.previewSignal).to.equal(previewSignal);
  });

  it(@"should change usePreviewLayer", ^{
    expect(previewViewModel.usePreviewLayer).to.beFalsy();
    [usePreviewLayerSignal sendNext:@(YES)];
    expect(previewViewModel.usePreviewLayer).to.beTruthy();
    [usePreviewLayerSignal sendNext:@(NO)];
    expect(previewViewModel.usePreviewLayer).to.beFalsy();
    [usePreviewLayerSignal sendNext:@(YES)];
    [usePreviewLayerSignal sendNext:@(YES)];
    expect(previewViewModel.usePreviewLayer).to.beTruthy();
  });
});

it(@"should have grid hidden set to YES", ^{
  expect(previewViewModel.gridHidden).to.beTruthy();
});

it(@"should have tap enabled", ^{
  expect(previewViewModel.tapEnabled).to.beTruthy();
});

it(@"should enable pinch if there is zoom", ^{
  expect(previewViewModel.pinchEnabled).to.beFalsy();
  deviceStub.hasZoom = YES;
  expect(previewViewModel.pinchEnabled).to.beTruthy();
});

it(@"should signal animateCapture", ^{
  LLSignalTestRecorder *recorder = [previewViewModel.animateCapture testRecorder];
  expect(recorder).to.sendValuesWithCount(0);
  [previewViewModel performCaptureAnimation];
  expect(recorder).to.sendValues(@[[RACUnit defaultUnit]]);
  [previewViewModel performCaptureAnimation];
  expect(recorder).to.sendValues(@[[RACUnit defaultUnit], [RACUnit defaultUnit]]);
});

it(@"animateCapture signal should complete", ^{
  __weak id weakPreviewViewModel;
  LLSignalTestRecorder *recorder;
  @autoreleasepool {
    CUIPreviewViewModel *newPreviewViewModel =
        [[CUIPreviewViewModel alloc] initWithDevice:deviceStub
                                      previewSignal:[RACSignal never]
                              usePreviewLayerSignal:[RACSignal never]];
    weakPreviewViewModel = newPreviewViewModel;
    recorder = [newPreviewViewModel.animateCapture testRecorder];
  }
  expect(weakPreviewViewModel).to.beNil();
  expect(recorder).to.complete();
});

it(@"should not retain from animateCapture signal", ^{
  __weak id weakPreviewViewModel;
  RACSignal *signal;
  @autoreleasepool {
    CUIPreviewViewModel *newPreviewViewModel =
        [[CUIPreviewViewModel alloc] initWithDevice:deviceStub
                                      previewSignal:[RACSignal never]
                              usePreviewLayerSignal:[RACSignal never]];
    weakPreviewViewModel = newPreviewViewModel;
    signal = newPreviewViewModel.animateCapture;
  }
  expect(signal).toNot.beNil();
  expect(weakPreviewViewModel).to.beNil();
});

context(@"zoom", ^{
  static const CGFloat pinchValue = 0.125;
  static const CGFloat zoomFactor = 4;
  static const CGFloat minZoomFactor = 0.01;
  static const CGFloat maxZoomFactor = 1;

  __block RACSubject *zoomSignal;
  __block id pinchMock;

  beforeEach(^{
    zoomSignal = [[RACSubject alloc] init];
    deviceStub.setZoomSignal = zoomSignal;
    deviceStub.zoomFactor = zoomFactor;
    deviceStub.minZoomFactor = minZoomFactor;
    deviceStub.maxZoomFactor = maxZoomFactor;
    pinchMock = OCMClassMock([UIPinchGestureRecognizer class]);
    OCMStub([(UIPinchGestureRecognizer *)pinchMock scale]).andReturn(pinchValue);
  });

  it(@"should call set zoom with zoom factor", ^{
    [previewViewModel previewPinched:pinchMock];
    expect(deviceStub.lastReceivedZoom).to.equal(zoomFactor * pinchValue);
  });

  it(@"should call set zoom with clamped zoom factor", ^{
    id bigPinchMock = OCMClassMock([UIPinchGestureRecognizer class]);
    OCMStub([(UIPinchGestureRecognizer *)bigPinchMock scale]).andReturn(50.0);
    [previewViewModel previewPinched:bigPinchMock];
    expect(deviceStub.lastReceivedZoom).to.equal(maxZoomFactor);

    id smallPinchMock = OCMClassMock([UIPinchGestureRecognizer class]);
    OCMStub([(UIPinchGestureRecognizer *)smallPinchMock scale]).andReturn(0.001f);
    [previewViewModel previewPinched:smallPinchMock];
    expect(deviceStub.lastReceivedZoom).to.equal(minZoomFactor);
  });

  it(@"should not set zoom with value bigger than 4", ^{
    deviceStub.maxZoomFactor = 5;
    id bigPinchMock = OCMClassMock([UIPinchGestureRecognizer class]);
    OCMStub([(UIPinchGestureRecognizer *)bigPinchMock scale]).andReturn(4.5);
    [previewViewModel previewPinched:bigPinchMock];
    expect(deviceStub.lastReceivedZoom).to.equal(4);
  });

  it(@"should subscribe each zoom signal", ^{
    [zoomSignal startCountingSubscriptions];

    [previewViewModel previewPinched:pinchMock];
    expect(zoomSignal).to.beSubscribedTo(1);

    RACSubject *newZoomSignal = [[RACSubject alloc] init];
    [newZoomSignal startCountingSubscriptions];
    deviceStub.setZoomSignal = newZoomSignal;

    [previewViewModel previewPinched:pinchMock];
    expect(newZoomSignal).to.beSubscribedTo(1);
  });

  it(@"should subscribe after zoom error", ^{
    RACSignal *errZoomSignal = [RACSignal error:[NSError lt_errorWithCode:13]];
    deviceStub.setZoomSignal = errZoomSignal;
    [errZoomSignal startCountingSubscriptions];

    [previewViewModel previewPinched:pinchMock];
    expect(errZoomSignal).to.beSubscribedTo(1);

    [zoomSignal startCountingSubscriptions];
    deviceStub.setZoomSignal = zoomSignal;

    [previewViewModel previewPinched:pinchMock];
    expect(zoomSignal).to.beSubscribedTo(1);
  });
});

context(@"focus", ^{
  static const CGPoint kTapPoint = CGPointMake(2.5, 4.0);
  static const CGPoint kDeviceCenterPoint = CGPointMake(0.5, 0.5);
  static CUIFocusIconMode * const kDefiniteFocusAtTapPoint =
      [CUIFocusIconMode definiteFocusAtPosition:kTapPoint];
  static CUIFocusIconMode * const kHiddenFocus = [CUIFocusIconMode hiddenFocus];

  __block CGPoint deviceTapPoint;
  __block CGPoint centerPoint;
  __block RACSubject *singleFocusSignal;
  __block RACSubject *singleExposureSignal;
  __block RACSubject *continuousFocusSignal;
  __block RACSubject *continuousExposureSignal;
  __block CUIFocusIconMode *focusAction;
  __block id tapMock;

  beforeEach(^{
    singleFocusSignal = [[RACSubject alloc] init];
    singleExposureSignal = [[RACSubject alloc] init];
    deviceStub.setSingleFocusPointSignal = singleFocusSignal;
    deviceStub.setSingleExposurePointSignal = singleExposureSignal;
    deviceTapPoint = [deviceStub devicePointFromPreviewLayerPoint:kTapPoint];
    tapMock = OCMClassMock([UITapGestureRecognizer class]);
    OCMStub([(UITapGestureRecognizer *)tapMock locationInView:OCMOCK_ANY]).andReturn(kTapPoint);

    continuousFocusSignal = [[RACSubject alloc] init];
    continuousExposureSignal = [[RACSubject alloc] init];
    deviceStub.setContinuousFocusPointSignal = continuousFocusSignal;
    deviceStub.setContinuousExposurePointSignal = continuousExposureSignal;
    centerPoint = [deviceStub previewLayerPointFromDevicePoint:kDeviceCenterPoint];
    focusAction = [CUIFocusIconMode indefiniteFocusAtPosition:centerPoint];
  });

  it(@"focusModeAndPosition should complete", ^{
    __weak id weakPreviewViewModel;
    LLSignalTestRecorder *recorder;
    @autoreleasepool {
      CUIPreviewViewModel *newPreviewViewModel =
          [[CUIPreviewViewModel alloc] initWithDevice:deviceStub
                                        previewSignal:[RACSignal never]
                                usePreviewLayerSignal:[RACSignal never]];
      weakPreviewViewModel = newPreviewViewModel;
      recorder = [newPreviewViewModel.focusModeAndPosition testRecorder];
    }
    expect(weakPreviewViewModel).to.beNil();
    expect(recorder).to.complete();
  });

  it(@"should not retain from focusModeAndPosition signal", ^{
    __weak id weakPreviewViewModel;
    RACSignal *signal;
    @autoreleasepool {
      CUIPreviewViewModel *newPreviewViewModel =
          [[CUIPreviewViewModel alloc] initWithDevice:deviceStub
                                        previewSignal:[RACSignal never]
                                usePreviewLayerSignal:[RACSignal never]];
      weakPreviewViewModel = newPreviewViewModel;
      signal = newPreviewViewModel.focusModeAndPosition;
    }
    expect(signal).toNot.beNil();
    expect(weakPreviewViewModel).to.beNil();
  });

  context(@"single focus", ^{
    it(@"should call set single focus and exposure with conversion", ^{
      [previewViewModel previewTapped:tapMock];
      expect(deviceStub.lastReceivedSingleExposurePoint).to.equal(deviceTapPoint);
      expect(deviceStub.lastReceivedSingleFocusPoint).to.equal(deviceTapPoint);
    });

    it(@"should subscribe each focus and exposure signal", ^{
      [singleFocusSignal startCountingSubscriptions];
      [singleExposureSignal startCountingSubscriptions];

      [previewViewModel previewTapped:tapMock];
      expect(singleFocusSignal).to.beSubscribedTo(1);
      expect(singleExposureSignal).to.beSubscribedTo(1);

      RACSubject *newSingleFocusSignal = [[RACSubject alloc] init];
      RACSubject *newSingleExposureSignal = [[RACSubject alloc] init];
      [newSingleFocusSignal startCountingSubscriptions];
      [newSingleExposureSignal startCountingSubscriptions];
      deviceStub.setSingleFocusPointSignal = newSingleFocusSignal;
      deviceStub.setSingleExposurePointSignal = newSingleExposureSignal;

      [previewViewModel previewTapped:tapMock];
      expect(newSingleFocusSignal).to.beSubscribedTo(1);
      expect(newSingleExposureSignal).to.beSubscribedTo(1);
    });

    it(@"should subscribe after focus error", ^{
      RACSignal *errSignal = [RACSignal error:[NSError lt_errorWithCode:13]];
      deviceStub.setSingleFocusPointSignal = errSignal;
      [errSignal startCountingSubscriptions];

      [previewViewModel previewTapped:tapMock];
      expect(errSignal).to.beSubscribedTo(1);

      [singleFocusSignal startCountingSubscriptions];
      deviceStub.setSingleFocusPointSignal = singleFocusSignal;

      [previewViewModel previewTapped:tapMock];
      expect(singleFocusSignal).to.beSubscribedTo(1);
    });

    it(@"should subscribe after exposure error", ^{
      RACSignal *errSignal = [RACSignal error:[NSError lt_errorWithCode:13]];
      deviceStub.setSingleExposurePointSignal = errSignal;
      [errSignal startCountingSubscriptions];

      [previewViewModel previewTapped:tapMock];
      expect(errSignal).to.beSubscribedTo(1);

      [singleExposureSignal startCountingSubscriptions];
      deviceStub.setSingleExposurePointSignal = singleExposureSignal;

      [previewViewModel previewTapped:tapMock];
      expect(singleExposureSignal).to.beSubscribedTo(1);
    });

    it(@"should send focus position when single focus changed", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [singleFocusSignal sendNext:$(kTapPoint)];
      [singleFocusSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [singleExposureSignal sendNext:$(kTapPoint)];
      [singleExposureSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus]);
    });

    it(@"should hide focus after focus error", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];
      [previewViewModel previewTapped:tapMock];
      [singleFocusSignal sendError:nil];
      [singleExposureSignal sendNext:$(kTapPoint)];
      [singleExposureSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus]);
    });

    it(@"should hide focus after exposure error", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];
      [previewViewModel previewTapped:tapMock];
      [singleFocusSignal sendNext:$(kTapPoint)];
      [singleFocusSignal sendCompleted];
      [singleExposureSignal sendError:nil];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus]);
    });

    it(@"should not send definite focus with NaN position", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];
      id nanTapMock = OCMClassMock([UITapGestureRecognizer class]);
      OCMStub([(UITapGestureRecognizer *)nanTapMock locationInView:OCMOCK_ANY]).
          andReturn(CGPointMake(1, NAN));
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:nanTapMock];
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
    });

    it(@"should not send definite focus with infinite position", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];
      id infiniteTapMock = OCMClassMock([UITapGestureRecognizer class]);
      OCMStub([(UITapGestureRecognizer *)infiniteTapMock locationInView:OCMOCK_ANY]).
          andReturn(CGPointMake(-INFINITY, 1));
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:infiniteTapMock];
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
    });

    it(@"should deliver focus updates on main thread", ^{
      LLSignalTestRecorder *recorder = [previewViewModel.focusModeAndPosition testRecorder];

      RACSignal *performInBackgroundThread = [[RACSignal defer:^RACSignal *{
        [previewViewModel previewTapped:tapMock];
        [singleFocusSignal sendNext:$(kTapPoint)];
        [singleFocusSignal sendCompleted];
        [singleExposureSignal sendNext:$(kTapPoint)];
        [singleExposureSignal sendCompleted];
        return [RACSignal empty];
      }] subscribeOn:[RACScheduler scheduler]];
      [performInBackgroundThread waitUntilCompleted:nil];

      expect(recorder).will.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus]);
      expect(recorder).to.deliverValuesOnMainThread();
      expect(recorder.operatingThreadsCount).to.equal(1);
    });
  });

  context(@"continuous focus", ^{
    it(@"should call set continuous focus and exposure on center", ^{
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(deviceStub.lastReceivedContinuousExposurePoint).to.equal(kDeviceCenterPoint);
      expect(deviceStub.lastReceivedContinuousFocusPoint).to.equal(kDeviceCenterPoint);

      deviceStub.lastReceivedContinuousExposurePoint = CGPointZero;
      deviceStub.lastReceivedContinuousFocusPoint = CGPointZero;
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(deviceStub.lastReceivedContinuousExposurePoint).to.equal(kDeviceCenterPoint);
      expect(deviceStub.lastReceivedContinuousFocusPoint).to.equal(kDeviceCenterPoint);
    });

    it(@"should subscribe each focus and exposure signal", ^{
      [continuousFocusSignal startCountingSubscriptions];
      [continuousExposureSignal startCountingSubscriptions];

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(continuousFocusSignal).to.beSubscribedTo(1);
      expect(continuousExposureSignal).to.beSubscribedTo(1);

      RACSubject *newContinuousFocusSignal = [[RACSubject alloc] init];
      RACSubject *newContinuousExposureSignal = [[RACSubject alloc] init];
      [newContinuousFocusSignal startCountingSubscriptions];
      [newContinuousExposureSignal startCountingSubscriptions];
      deviceStub.setContinuousFocusPointSignal = newContinuousFocusSignal;
      deviceStub.setContinuousExposurePointSignal = newContinuousExposureSignal;

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(newContinuousFocusSignal).to.beSubscribedTo(1);
      expect(newContinuousExposureSignal).to.beSubscribedTo(1);
    });

    it(@"should subscribe after focus error", ^{
      RACSignal *errSignal = [RACSignal error:[NSError lt_errorWithCode:13]];
      deviceStub.setContinuousFocusPointSignal = errSignal;
      [errSignal startCountingSubscriptions];

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(errSignal).to.beSubscribedTo(1);

      [continuousFocusSignal startCountingSubscriptions];
      deviceStub.setContinuousFocusPointSignal = continuousFocusSignal;

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(continuousFocusSignal).to.beSubscribedTo(1);
    });

    it(@"should subscribe after exposure error", ^{
      RACSignal *errSignal = [RACSignal error:[NSError lt_errorWithCode:13]];
      deviceStub.setContinuousExposurePointSignal = errSignal;
      [errSignal startCountingSubscriptions];

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(errSignal).to.beSubscribedTo(1);

      [continuousExposureSignal startCountingSubscriptions];
      deviceStub.setContinuousExposurePointSignal = continuousExposureSignal;

      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(continuousExposureSignal).to.beSubscribedTo(1);
    });
  });

  context(@"multiple focus change", ^{
    static const CGPoint kTapPoint2 = kTapPoint * 2;
    static CUIFocusIconMode * const kDefiniteFocusAtTapPoint2 =
        [CUIFocusIconMode definiteFocusAtPosition:kTapPoint2];

    __block LLSignalTestRecorder *recorder;
    __block id tapMock2;

    beforeEach(^{
      recorder = [previewViewModel.focusModeAndPosition testRecorder];
      tapMock2 = OCMClassMock([UITapGestureRecognizer class]);
      OCMStub([(UITapGestureRecognizer *)tapMock2 locationInView:OCMOCK_ANY]).andReturn(kTapPoint2);
    });

    it(@"shouldn't send focus position when continuous focus changed multiple times", ^{
      expect(recorder).to.sendValues(@[]);
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[focusAction]);
      [continuousFocusSignal sendNext:[RACUnit defaultUnit]];
      [continuousExposureSignal sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[focusAction]);
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[focusAction]);
    });

    it(@"should send focus position when continuous focus changed twice with tap in the middle", ^{
      expect(recorder).to.sendValues(@[]);
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[focusAction]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[focusAction, kDefiniteFocusAtTapPoint]);
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[focusAction, kDefiniteFocusAtTapPoint, focusAction]);
    });

    it(@"shouldn't send double tap", ^{
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
    });

    it(@"should send different taps", ^{
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [previewViewModel previewTapped:tapMock2];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kDefiniteFocusAtTapPoint2]);
    });

    it(@"should send focus position when tap twice with continuous focus changed in the middle", ^{
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [subjectAreaChanged sendNext:[RACUnit defaultUnit]];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, focusAction]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, focusAction,
                                       kDefiniteFocusAtTapPoint]);
    });

    it(@"should send focus position when single focus changed twice", ^{
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [singleFocusSignal sendNext:$(kTapPoint)];
      [singleFocusSignal sendCompleted];
      [singleExposureSignal sendNext:$(kTapPoint)];
      [singleExposureSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus]);
      [previewViewModel previewTapped:tapMock2];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus,
                                       kDefiniteFocusAtTapPoint2]);
      [singleFocusSignal sendNext:$(kTapPoint)];
      [singleFocusSignal sendCompleted];
      [singleExposureSignal sendNext:$(kTapPoint)];
      [singleExposureSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kHiddenFocus,
                                       kDefiniteFocusAtTapPoint2, kHiddenFocus]);
    });

    it(@"should send focus position when a second focus starts before the first finished", ^{
      expect(recorder).to.sendValues(@[]);
      [previewViewModel previewTapped:tapMock];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint]);
      [previewViewModel previewTapped:tapMock2];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kDefiniteFocusAtTapPoint2]);
      [singleFocusSignal sendNext:$(kTapPoint)];
      [singleFocusSignal sendCompleted];
      [singleExposureSignal sendNext:$(kTapPoint)];
      [singleExposureSignal sendCompleted];
      expect(recorder).to.sendValues(@[kDefiniteFocusAtTapPoint, kDefiniteFocusAtTapPoint2,
                                       kHiddenFocus]);
    });
  });
});

SpecEnd
