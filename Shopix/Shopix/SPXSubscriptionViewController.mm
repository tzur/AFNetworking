// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewController.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsManager.h>
#import <LTKit/NSArray+Functional.h>
#import <MessageUI/MessageUI.h>

#import "MFMailComposeViewController+Dismissal.h"
#import "SPXAlertViewControllerProvider.h"
#import "SPXButtonsHorizontalLayoutView.h"
#import "SPXColorScheme.h"
#import "SPXFeedbackComposeViewControllerProvider.h"
#import "SPXPagingView.h"
#import "SPXRestorePurchasesButton.h"
#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionGradientButtonsFactory.h"
#import "SPXSubscriptionTermsView.h"
#import "SPXSubscriptionTermsViewModel.h"
#import "SPXSubscriptionVideoPageView.h"
#import "SPXSubscriptionVideoPageViewModel.h"
#import "SPXSubscriptionViewModel.h"
#import "UIAlertController+ViewModel.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

#pragma mark -
#pragma mark SPXSubscriptionViewController
#pragma mark -

@interface SPXSubscriptionViewController ()

/// View configuration.
@property (readonly, nonatomic) id<SPXSubscriptionViewModel> viewModel;

/// Provider used for creating success and failure alerts when requested.
@property (readonly, nonatomic) id<SPXAlertViewControllerProvider> alertControllerProvider;

/// Provider used for creating the feedback view controller when requested.
@property (readonly, nonatomic) id<SPXFeedbackComposeViewControllerProvider> mailComposerProvider;

/// Provider used for creating the subscription buttons.
@property (readonly, nonatomic) id<SPXSubscriptionButtonsFactory> subscriptionButtonsFactory;

/// View that lets the user paginate horizontally between the given pages.
@property (readonly, nonatomic) SPXPagingView *pagingView;

/// View containing horizontally aligned buttons, where one of the buttons can be enlarged.
@property (readonly, nonatomic) SPXButtonsHorizontalLayoutView *subscriptionButtonsView;

/// Button that allows the user to restore previous subscription.
@property (readonly, nonatomic) SPXRestorePurchasesButton *restorePurchasesButton;

/// View contains \c subscriptionButtonsView and \c restorePurchasesButton with padding between
/// them.
@property (readonly, nonatomic) UIView *buttonsContainer;

/// View contains centered \c buttonsContainer with top and bottom margins.
@property (readonly, nonatomic) UIView *buttonsContainerWithMargins;

/// View for subscription terms of use text and documents links.
@property (readonly, nonatomic) SPXSubscriptionTermsView *termsView;

/// View used to disable the UI when a task is in progress.
@property (readonly, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation SPXSubscriptionViewController

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
    mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider {
  auto defaultButtonsFactory = [[SPXSubscriptionGradientButtonsFactory alloc]
                                initWithColorScheme:viewModel.colorScheme];
  return [self initWithViewModel:viewModel
         alertControllerProvider:[[SPXAlertViewControllerProvider alloc] init]
            mailComposerProvider:mailComposerProvider
      subscriptionButtonsFactory:defaultButtonsFactory];
}

- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory {
  return [self initWithViewModel:viewModel
         alertControllerProvider:[[SPXAlertViewControllerProvider alloc] init]
            mailComposerProvider:mailComposerProvider
      subscriptionButtonsFactory:subscriptionButtonsFactory];
}

- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
          alertControllerProvider:(id<SPXAlertViewControllerProvider>)alertControllerProvider
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _viewModel = viewModel;
    _alertControllerProvider = alertControllerProvider;
    _mailComposerProvider = mailComposerProvider;
    _subscriptionButtonsFactory = subscriptionButtonsFactory;
  }
  return self;
}

#pragma mark -
#pragma mark View Lifecycle
#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = self.viewModel.colorScheme.backgroundColor;
  [self setupSubviews];
  [self setupBindings];
  [self.viewModel fetchProductsInfo];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  if (self.view.frame.size.width < self.view.frame.size.height) {
    self.pagingView.pageViewWidthRatio = 0.84;
    self.pagingView.spacingRatio = 0.05;
  } else {
    self.pagingView.pageViewWidthRatio = 0.42;
    self.pagingView.spacingRatio = 0.4;
  }
}

#pragma mark -
#pragma mark Subviews Setup
#pragma mark -

- (void)setupSubviews {
  [self setupBackgroundView];
  [self setupTerms];
  [self setupPageingView];
  [self setupButtonsContainer];
  [self setupButtons];
  [self setupRestorePurchasesButton];
  [self setupActivityIndicator];
}

- (void)setupBackgroundView {
  if (!self.backgroundView) {
    return;
  }

  [self.view insertSubview:self.backgroundView atIndex:0];
  [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setupPageingView {
  _pagingView = [[SPXPagingView alloc] init];
  [self.view addSubview:self.pagingView];

  [self.pagingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self.view);
    make.height.equalTo(self.view).multipliedBy(0.58).priorityHigh();
    make.height.mas_lessThanOrEqualTo(self.view.mas_width).multipliedBy(0.95);
  }];
  self.pagingView.pageViews = [self createPageViews];
}

- (NSArray<UIView *> *)createPageViews {
  return [self.viewModel.pageViewModels
          lt_map:^UIView *(id<SPXSubscriptionVideoPageViewModel> pageViewModel) {
    auto pageView = [[SPXSubscriptionVideoPageView alloc] init];
    pageView.videoURL = pageViewModel.videoURL;
    pageView.title = pageViewModel.title;
    pageView.subtitle = pageViewModel.subtitle;
    pageView.videoBorderColor = pageViewModel.videoBorderColor;

    return pageView;
  }];
}

- (void)setupButtonsContainer {
  _buttonsContainerWithMargins = [[UIView alloc] init];
  [self.view addSubview:self.buttonsContainerWithMargins];

  [self.buttonsContainerWithMargins mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.view);
    make.top.equalTo(self.pagingView.mas_bottom);
    make.bottom.equalTo(self.termsView.mas_top);
  }];

  _buttonsContainer = [[UIView alloc] init];
  [self.buttonsContainerWithMargins addSubview:self.buttonsContainer];

  [self.buttonsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.buttonsContainerWithMargins);
    make.center.equalTo(self.buttonsContainerWithMargins);
    make.height.equalTo(self.view).multipliedBy(0.24).priorityHigh();
    make.height.mas_lessThanOrEqualTo(230);
  }];
}

- (void)setupButtons {
  _subscriptionButtonsView = [[SPXButtonsHorizontalLayoutView alloc] init];
  [self.buttonsContainer addSubview:self.subscriptionButtonsView];

  [self.subscriptionButtonsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.view);
    make.top.equalTo(self.buttonsContainer);
    make.height.equalTo(self.view).multipliedBy(0.197).priorityHigh();
    make.height.mas_lessThanOrEqualTo(167);
    make.height.mas_lessThanOrEqualTo(self.view.mas_width).multipliedBy(0.32);
  }];

  auto descriptors = self.viewModel.subscriptionDescriptors;
  self.subscriptionButtonsView.buttons = [descriptors
      lt_map:^UIControl *(SPXSubscriptionDescriptor *subscriptionDescriptor) {
        return [self.subscriptionButtonsFactory
                createSubscriptionButtonWithSubscriptionDescriptor:subscriptionDescriptor
                atIndex:[descriptors indexOfObject:subscriptionDescriptor] outOf:descriptors.count
                isHighlighted:NO];
      }];

  self.subscriptionButtonsView.enlargedButtonIndex = self.viewModel.preferredProductIndex;
}

- (void)setupRestorePurchasesButton {
  _restorePurchasesButton = [[SPXRestorePurchasesButton alloc] init];
  self.restorePurchasesButton.textColor = self.viewModel.colorScheme.textColor;

  [self.buttonsContainer addSubview:self.restorePurchasesButton];
  [self.restorePurchasesButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.centerX.equalTo(self.buttonsContainer);
    make.height.equalTo(@16);
  }];
}

- (void)setupTerms {
  _termsView = [[SPXSubscriptionTermsView alloc]
                initWithTermsText:self.viewModel.termsViewModel.termsText
                termsOfUseLink:self.viewModel.termsViewModel.termsOfUseLink
                privacyPolicyLink:self.viewModel.termsViewModel.privacyPolicyLink];
  self.termsView.termsTextContainerInset = UIEdgeInsetsMake(6, 0, 6, 0);
  [self.view addSubview:self.termsView];

  [self.termsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.view);
    make.bottom.equalTo(self.view);
    make.width.equalTo(self.view).multipliedBy(0.94);
  }];
}

- (void)setupActivityIndicator {
  _activityIndicatorView = [[UIActivityIndicatorView alloc]
                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.activityIndicatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
  self.activityIndicatorView.hidesWhenStopped = YES;
  [self.view addSubview:self.activityIndicatorView];

  [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

#pragma mark -
#pragma mark Bindings Setup
#pragma mark -

- (void)setupBindings {
  [self setupSubscriptionButtonsBindings];
  [self setupRestorePurchasesButtonPressedBinding];
  [self setupActivityIndicatorBinding];
  [self setupScrollPositionBinding];
  [self setupVideoDidFinishBinding];
  [self setupScrollRequestBinding];
  [self setupAlertRequestBinding];
  [self setupFeedbackComposerRequestBinding];
}

- (void)setupSubscriptionButtonsBindings {
  @weakify(self);
  [self.subscriptionButtonsView.buttonPressed subscribeNext:^(NSNumber *index) {
    @strongify(self);
    [self.viewModel subscriptionButtonPressed:index.unsignedIntegerValue];
  }];
}

- (void)setupRestorePurchasesButtonPressedBinding {
  @weakify(self);
  [[self.restorePurchasesButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   subscribeNext:^(UIControl *) {
     @strongify(self);
     [self.viewModel restorePurchasesButtonPressed];
   }];
}

- (void)setupActivityIndicatorBinding {
  @weakify(self);
  [RACObserve(self.viewModel, shouldShowActivityIndicator) subscribeNext:^(NSNumber *active) {
    @strongify(self);
    active.boolValue ?
        [self.activityIndicatorView startAnimating] : [self.activityIndicatorView stopAnimating];
  }];
}

- (void)setupScrollPositionBinding {
  @weakify(self);
  [RACObserve(self.pagingView, scrollPosition) subscribeNext:^(NSNumber *scrollPosition) {
    @strongify(self);
    [self.viewModel pagingViewScrolledToPosition:scrollPosition.floatValue];
  }];
}

- (void)setupVideoDidFinishBinding {
  NSArray<RACSignal *> *videoDidFinishPlaybackSignals =
      [self.pagingView.pageViews valueForKey:@instanceKeypath(SPXSubscriptionVideoPageView,
                                                              videoDidFinishPlayback)];
  @weakify(self);
  [[RACSignal merge:videoDidFinishPlaybackSignals] subscribeNext:^(id) {
    @strongify(self)
    [self.viewModel activePageDidFinishVideoPlayback];
  }];
}

- (void)setupScrollRequestBinding {
  @weakify(self);
  [[self.viewModel.pagingViewScrollRequested distinctUntilChanged]
      subscribeNext:^(NSNumber *pageIndex) {
        @strongify(self);
        [self.pagingView scrollToPage:pageIndex.unsignedIntegerValue animated:YES];
      }];
}

- (void)setupAlertRequestBinding {
  @weakify(self);
  [self.viewModel.alertRequested subscribeNext:^(id<SPXAlertViewModel> alertViewModel) {
    @strongify(self);
    auto alert = [UIAlertController spx_alertControllerWithViewModel:alertViewModel];
    [self presentViewController:alert animated:YES completion:nil];
  }];
}

- (void)setupFeedbackComposerRequestBinding {
  @weakify(self);
  [self.viewModel.feedbackComposerRequested subscribeNext:^(LTVoidBlock completionHandler) {
    @strongify(self);
    auto _Nullable mailComposer = [self.mailComposerProvider createFeedbackComposeViewController];

    if (mailComposer) {
      [mailComposer.dismissRequested subscribeNext:^(RACUnit *) {
        [self dismissViewControllerAnimated:YES completion:completionHandler];
      }];
      [self presentViewController:mailComposer animated:YES completion:nil];
    } else {
      completionHandler();
    }
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  if (_backgroundView && self.isViewLoaded) {
    [_backgroundView removeFromSuperview];
  }

  _backgroundView = backgroundView;

  if (backgroundView && self.isViewLoaded) {
    [self setupBackgroundView];
  }
}

- (RACSignal<RACUnit *> *)dismissRequested {
  return self.viewModel.dismissRequested;
}

@end

NS_ASSUME_NONNULL_END
