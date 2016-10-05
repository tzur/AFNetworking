// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIPreviewViewController.h"

#import "CUIPreviewViewModel.h"
#import "UIView+Retrieval.h"

@interface CUIFakePreviewViewModel : NSObject <CUIPreviewViewModel>
@property (nonatomic) BOOL usePreviewLayer;
@property (strong, nonatomic) CALayer *previewLayer;
@property (strong, nonatomic) RACSignal *previewSignal;
@property (strong, nonatomic) RACSignal *animateCapture;
@property (strong, nonatomic) RACSignal *focusModeAndPosition;
@property (nonatomic) BOOL tapEnabled;
@property (nonatomic) BOOL pinchEnabled;
@property (nonatomic) BOOL gridHidden;
@end

@implementation CUIFakePreviewViewModel
- (void)previewTapped:(UITapGestureRecognizer __unused *)gestureRecognizer {
}
- (void)previewPinched:(UIPinchGestureRecognizer __unused *)gestureRecognizer {
}
- (void)performCaptureAnimation {
}
@end

SpecBegin(CUIPreviewViewController)

__block CUIFakePreviewViewModel *viewModel;

beforeEach(^{
  viewModel = [[CUIFakePreviewViewModel alloc] init];
  viewModel.animateCapture = [RACSubject subject];
  viewModel.focusModeAndPosition = [RACSubject subject];
});

context(@"preview view", ^{
  __block CUIPreviewViewController *viewController;
  __block RACSubject *previewSignal;

  beforeEach(^{
    previewSignal = [RACSubject subject];
    [previewSignal startCountingSubscriptions];

    viewModel.usePreviewLayer = NO;
    viewModel.previewSignal = previewSignal;
    viewModel.previewLayer = [CALayer layer];

    viewController = [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
  });

  afterEach(^{
    viewModel = nil;
    viewController = nil;
  });

  it(@"should create view for preview signal", ^{
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"LayerView"]).notTo.beNil();
    expect([viewController.view wf_viewForAccessibilityIdentifier:@"SignalView"]).notTo.beNil();
  });

  it(@"should toggle to preview layer and signal", ^{
    UIView *layerView = [viewController.view wf_viewForAccessibilityIdentifier:@"LayerView"];
    UIView *signalView = [viewController.view wf_viewForAccessibilityIdentifier:@"SignalView"];
    expect(layerView.hidden).to.beTruthy();
    expect(signalView.hidden).to.beFalsy();
    viewModel.usePreviewLayer = YES;
    expect(layerView.hidden).to.beFalsy();
    expect(signalView.hidden).to.beTruthy();
    viewModel.usePreviewLayer = NO;
    expect(layerView.hidden).to.beTruthy();
    expect(signalView.hidden).to.beFalsy();
  });
});

context(@"dealloc", ^{
  beforeEach(^{
    viewModel.previewLayer = [CALayer layer];
    viewModel.previewSignal = [RACSignal never];
  });

  it(@"should dealloc when using layer", ^{
    viewModel.usePreviewLayer = YES;

    __weak CUIPreviewViewController *weakController;
    __weak UIView *weakView;

    @autoreleasepool {
      CUIPreviewViewController *viewController =
          [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
      weakController = viewController;
      weakView = [viewController.view wf_viewForAccessibilityIdentifier:@"LayerView"];
      expect(weakView).notTo.beNil();
    }

    expect(weakController).to.beNil();
    expect(weakView).to.beNil();
  });

  it(@"should dealloc when using signal", ^{
    viewModel.usePreviewLayer = NO;

    __weak CUIPreviewViewController *weakController;
    __weak UIView *weakView;

    @autoreleasepool {
      CUIPreviewViewController *viewController =
          [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
      weakController = viewController;
      weakView = [viewController.view wf_viewForAccessibilityIdentifier:@"SignalView"];
      expect(weakView).notTo.beNil();
    }

    expect(weakController).to.beNil();
    expect(weakView).to.beNil();
  });
});

SpecEnd
