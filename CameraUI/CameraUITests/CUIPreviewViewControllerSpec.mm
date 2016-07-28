// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIPreviewViewController.h"

#import "CUIPreviewViewModel.h"
#import "UIView+Retrieval.h"

@interface CUIFakePreviewViewModel : NSObject <CUIPreviewViewModel>
@property (nonatomic) BOOL usePreviewLayer;
@property (strong, nonatomic, nullable) CALayer *previewLayer;
@property (strong, nonatomic, nullable) RACSignal *previewSignal;
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
  context(@"using layer", ^{
    __block CUIPreviewViewController *viewController;

    beforeEach(^{
      viewModel.usePreviewLayer = YES;
      viewModel.previewLayer = [CALayer layer];

      viewController = [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
    });

    it(@"should create view for preview layer", ^{
      expect([viewController.view wf_viewForAccessibilityIdentifier:@"LayerView"]).notTo.beNil();
      expect([viewController.view wf_viewForAccessibilityIdentifier:@"SignalView"]).to.beNil();
    });
  });

  context(@"using signal", ^{
    __block CUIPreviewViewController *viewController;
    __block RACSubject *previewSignal;

    beforeEach(^{
      previewSignal = [RACSubject subject];
      [previewSignal startCountingSubscriptions];

      viewModel.usePreviewLayer = NO;
      viewModel.previewSignal = previewSignal;

      viewController = [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
    });

    it(@"should create view for preview signal", ^{
      expect([viewController.view wf_viewForAccessibilityIdentifier:@"LayerView"]).to.beNil();
      expect([viewController.view wf_viewForAccessibilityIdentifier:@"SignalView"]).notTo.beNil();
    });

    it(@"should subscribe to preview signal", ^{
      [viewController loadViewIfNeeded];
      expect(previewSignal).to.beSubscribedTo(1);
    });
  });
});

context(@"dealloc", ^{
  it(@"should dealloc when using layer", ^{
    viewModel.usePreviewLayer = YES;
    viewModel.previewLayer = [CALayer layer];

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
    viewModel.previewLayer = nil;
    viewModel.previewSignal = [RACSignal never];

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
